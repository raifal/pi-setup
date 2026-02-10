# pi-setup Automatisierung

Enthält Hilfs-Skripte zum Installieren / Klonen eines Raspberry Pi Systems auf NVMe, Einrichten eines GitHub Actions self-hosted Runners und Installation von Docker.

Skripte:

- `scripts/clone_sd_to_nvme.sh` — Klont ein laufendes System (SD) auf ein NVMe-Laufwerk (Partitionieren, Formatieren, rsync, fstab/cmdline anpassen).
- `scripts/setup_github_runner.sh` — Lädt den ARM64 Actions Runner, konfiguriert und installiert ihn als Service (benötigt Repo und Token).
- `scripts/install_docker.sh` — Installiert Docker CE mit dem offiziellen Script und fügt optional einen Benutzer zur `docker`-Gruppe hinzu.

Sicherheit: Alle Skripte sollten mit Vorsicht ausgeführt werden. `clone_sd_to_nvme.sh` formatiert das Zielgerät unwiderruflich.

Beispiele:

NVMe klonen (interaktiv):

```bash
sudo bash scripts/clone_sd_to_nvme.sh --nvme /dev/nvme0n1
```

GitHub Actions Runner (erzeugen Sie ein Repo-Scoped token in GitHub und verwenden Sie es sofort):

```bash
sudo bash scripts/setup_github_runner.sh --repo owner/repo --token YOUR_TOKEN --name my-pi-runner
```

Docker installieren:

```bash
sudo bash scripts/install_docker.sh --user pi
```

Nach dem Ausführen von `install_docker.sh` melden Sie sich neu am Benutzer an, damit die Docker-Gruppe wirksam wird.

Hinweis: Passen Sie ggf. Pfade und Optionen an Ihre Distribution (Raspberry Pi OS vs. Ubuntu Server) an.
