#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --nvme /dev/nvme0n1 [--non-interactive]
Automatisiert: partitionieren, formatieren und System von der aktuell bootenden SD auf NVMe klonen.
VORSICHT: Zielgerät wird gelöscht. Prüfen Sie Gerät vor Ausführung.
EOF
  exit 1
}

NVME=""
NONINT=0
while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --nvme) NVME="$2"; shift 2;;
    --non-interactive) NONINT=1; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [[ -z "$NVME" ]]; then
  usage
fi

if [[ $(id -u) -ne 0 ]]; then
  echo "Bitte als root ausführen (sudo)."; exit 2
fi

if [[ ! -b "$NVME" ]]; then
  echo "Ziel $NVME ist kein Blockgerät."; lsblk; exit 3
fi

if [[ $NONINT -eq 0 ]]; then
  echo "ACHTUNG: $NVME wird formatiert und alle Daten gelöscht.";
  read -p "Weiter? (yes/NO) " CONF
  if [[ "$CONF" != "yes" ]]; then
    echo "Abgebrochen."; exit 4
  fi
fi

# Partitionieren: 1=FAT32 (boot), 2=ext4 (root)
parted --script "$NVME" mklabel gpt \
  mkpart primary fat32 1MiB 256MiB set 1 boot on \
  mkpart primary ext4 256MiB 100%

BOOTP=${NVME}p1
ROOTP=${NVME}p2

if [[ ! -b "$BOOTP" ]]; then BOOTP=${NVME}1; fi
if [[ ! -b "$ROOTP" ]]; then ROOTP=${NVME}2; fi

mkfs.vfat -F32 "$BOOTP"
mkfs.ext4 -F "$ROOTP"

mkdir -p /mnt/nvme_boot /mnt/nvme_root
mount "$ROOTP" /mnt/nvme_root
rsync -aAXv --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run --exclude=/mnt --exclude=/media / /mnt/nvme_root
mount "$BOOTP" /mnt/nvme_root/boot
rsync -a /boot/ /mnt/nvme_root/boot/

# Backup fstab/cmdline and update with new PARTUUID
ROOTUUID=$(blkid -s PARTUUID -o value "$ROOTP")
echo "Detected PARTUUID for root: $ROOTUUID"
cp /mnt/nvme_root/etc/fstab /mnt/nvme_root/etc/fstab.backup || true
sed -E "s|/dev/mmcblk0p2|PARTUUID=$ROOTUUID|g" /mnt/nvme_root/etc/fstab > /mnt/nvme_root/etc/fstab.new || true
mv /mnt/nvme_root/etc/fstab.new /mnt/nvme_root/etc/fstab || true

if [[ -f /mnt/nvme_root/boot/cmdline.txt ]]; then
  cp /mnt/nvme_root/boot/cmdline.txt /mnt/nvme_root/boot/cmdline.txt.backup
  sed -E "s|root=[^ ]+|root=PARTUUID=$ROOTUUID|g" /mnt/nvme_root/boot/cmdline.txt > /mnt/nvme_root/boot/cmdline.txt.new || true
  mv /mnt/nvme_root/boot/cmdline.txt.new /mnt/nvme_root/boot/cmdline.txt || true
else
  echo "WARN: /boot/cmdline.txt nicht gefunden. Bitte manuell anpassen." >&2
fi

umount -l /mnt/nvme_root/boot || true
umount -l /mnt/nvme_root || true

echo "Fertig. Entfernen Sie die SD-Karte und booten Sie vom NVMe." 
echo "Sollte das System nicht booten, prüfen Sie /boot/cmdline.txt und /etc/fstab auf PARTUUID." 
