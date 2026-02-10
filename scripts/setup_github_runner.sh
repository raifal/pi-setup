#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --repo owner/repo --token GITHUB_TOKEN [--name runner-name]
Beispiel: $0 --repo raifal/pi-setup --token XXX --name pi-runner
Das Skript lädt den ARM64-Runner, extrahiert ihn und registriert ihn (unattended).
EOF
  exit 1
}

REPO=""
TOKEN=""
NAME="pi-runner"

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --token) TOKEN="$2"; shift 2;;
    --name) NAME="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [[ -z "$REPO" || -z "$TOKEN" ]]; then
  usage
fi

if [[ $(id -u) -ne 0 ]]; then
  echo "Bitte als root ausführen (sudo)."; exit 2
fi

mkdir -p /opt/actions-runner
cd /opt/actions-runner

echo "Ermittle neueste Runner-Version (linux-arm64)..."
URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
  | grep "browser_download_url" | grep "linux-arm64" | head -n1 | sed -E 's/.*"(https:[^\"]+)".*/\1/')

if [[ -z "$URL" ]]; then
  echo "Konnte Release-Asset nicht automatisch finden. Bitte manuell herunterladen."; exit 3
fi

curl -L -o actions-runner.tar.gz "$URL"
tar xzf actions-runner.tar.gz
chown -R $(logname):$(logname) .

echo "Konfiguriere Runner für https://github.com/$REPO ..."
./config.sh --url "https://github.com/$REPO" --token "$TOKEN" --name "$NAME" --unattended --work _work --labels self-hosted,linux,arm64

echo "Installiere Runner als Service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "Runner installiert und gestartet. Prüfen Sie in GitHub unter Settings → Actions → Runners." 
