#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--user username]
Installiert Docker CE über das offizielle Install-Skript und fügt optional einen Benutzer zur docker-Gruppe hinzu.
EOF
  exit 1
}

USER_TO_ADD=""
while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --user) USER_TO_ADD="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [[ $(id -u) -ne 0 ]]; then
  echo "Bitte als root ausführen (sudo)."; exit 2
fi

echo "Docker CE installieren..."
curl -fsSL https://get.docker.com | sh

echo "Daemon aktivieren und starten..."
systemctl enable --now docker

if [[ -n "$USER_TO_ADD" ]]; then
  usermod -aG docker "$USER_TO_ADD" || true
  echo "Benutzer $USER_TO_ADD zur docker-Gruppe hinzugefügt. Re-login erforderlich." 
fi

echo "Test: hello-world Container starten..."
docker run --rm hello-world || echo "Warnung: hello-world nicht erfolgreich ausgeführt." 

echo "Fertig. Docker ist installiert." 
