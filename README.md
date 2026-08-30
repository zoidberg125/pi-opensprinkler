# OpenSprinkler Pi (OSPi) – DietPi Setup

Automatisiertes Setup, Dokumentation und Konfigurations-Backup von OpenSprinkler auf einem Raspberry Pi 4 mit OSPi-Erweiterungsplatine unter DietPi.

---

## 📁 Repository-Struktur

* README.md                 - Diese Dokumentation
* install.sh                - Automatisches Installation- & Build-Skript
* backup-config.sh          - Sichert stns.dat & nvs.dat direkt ins Repo/GitHub
* systemd/opensprinkler.service - Systemd Service-Datei für Autostart
* config/stns.dat           - Gesicherte Zonen & Programme
* config/nvs.dat            - Gesicherte System-Optionen

---

## 🛠️ Dateiinhalte des Repositories

### systemd/opensprinkler.service
[Unit]
Description=OpenSprinkler Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/OpenSprinkler-Firmware
ExecStart=/opt/OpenSprinkler-Firmware/OpenSprinkler
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target


### install.sh
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=== 1. Systempakete & Build-Tools installieren ==="
sudo apt-get update
sudo apt-get install -y git build-essential libgpiod-dev ccache

echo "=== 2. OpenSprinkler Firmware klonen & bauen ==="
cd /opt
if [ -d "OpenSprinkler-Firmware" ]; then
    echo "OpenSprinkler-Firmware existiert bereits. Aktualisiere..."
    cd OpenSprinkler-Firmware
    sudo git pull
else
    sudo git clone https://github.com/OpenSprinkler/OpenSprinkler-Firmware.git
    cd OpenSprinkler-Firmware
fi

sudo git submodule update --init --recursive

echo "Kompiliere OpenSprinkler für OSPi..."
sudo ./build.sh ospi

echo "=== 3. Systemd Service einrichten ==="
sudo cp "$SCRIPT_DIR/systemd/opensprinkler.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable opensprinkler.service
sudo systemctl restart opensprinkler.service

echo "=== Installation abgeschlossen! ==="
echo "OpenSprinkler läuft und ist unter http://<IP-DEINES-PI>:8080 erreichbar."


### backup-config.sh
#!/usr/bin/env bash
set -e

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$REPO_DIR/config"
OS_DIR="/opt/OpenSprinkler-Firmware"

mkdir -p "$CONFIG_DIR"

if [ -f "$OS_DIR/stns.dat" ]; then
    cp "$OS_DIR/stns.dat" "$CONFIG_DIR/stns.dat"
    echo "stns.dat erfolgreich gesichert."
else
    echo "Warnung: $OS_DIR/stns.dat nicht gefunden!"
fi

if [ -f "$OS_DIR/nvs.dat" ]; then
    cp "$OS_DIR/nvs.dat" "$CONFIG_DIR/nvs.dat"
    echo "nvs.dat erfolgreich gesichert."
fi

cd "$REPO_DIR"
git add config/

if ! git diff-index --quiet HEAD --; then
    git commit -m "Automatisches Backup der OpenSprinkler Konfiguration ($(date +'%Y-%m-%d %H:%M'))"
    git push origin main
    echo "Backup erfolgreich auf GitHub aktualisiert!"
else
    echo "Keine Änderungen in den .dat Dateien festgestellt."
fi

---

## ⚡ Schnellstart & Erstinstallation auf DietPi

### 1. SSH-Key auf DietPi einrichten & testen
ssh-keygen -t ed25519 -C "deine_email@example.com"
cat ~/.ssh/id_ed25519.pub

Public Key bei GitHub unter Settings -> SSH Keys hinterlegen.
Erzwingung des Keys in ~/.ssh/config eintragen:

Host github.com
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Zugriffsrechte setzen und Verbindung testen:
chmod 600 ~/.ssh/config
ssh -T git@github.com

### 2. Repository klonen & Skripte ausführen
sudo apt-get update && sudo apt-get install -y git
git clone git@github.com:DEIN_USER/pi-opensprinkler.git
cd pi-opensprinkler
chmod +x install.sh backup-config.sh
./install.sh

---

## 🔌 Hardware & Verkabelung (OSPi Board)

* Board: OpenSprinkler Pi (OSPi) Expansion Board.
* Stromversorgung: 24V AC Wechselstrom-Netzteil an den orangefarbenen Terminal-Block anschließen. Der Raspberry Pi 4 wird intern über den 40-Pin GPIO Header direkt mit 5V versorgt (kein USB-C Netzteil erforderlich).
* Ventile: Eine Ader aller 24V AC Ventile an COM (Common), die zweiten Adern jeweils an Zonen 1 bis 8.
* Wichtige System-Einstellung: In DietPi (dietpi-config -> Advanced Options) 1-Wire (w1-gpio) unbedingt deaktivieren, da GPIO 4 vom OSPi Schieberegister belegt wird.

---

## 🖥️ Verwaltung & Befehle

* Web-Interface: http://<DIETPI-IP>:8080 (Standard-Passwort: opendoor)
* Dienst-Steuerung:
  sudo systemctl status opensprinkler.service   # Status prüfen
  sudo systemctl restart opensprinkler.service  # Neustart
  sudo systemctl stop opensprinkler.service     # Stoppen

---

## 💾 Backup & Restore

### Backup durchführen (im laufenden Betrieb)
./backup-config.sh

### Restore durchführen (Wiederherstellung)
sudo systemctl stop opensprinkler.service
sudo cp config/stns.dat /opt/OpenSprinkler-Firmware/stns.dat
sudo cp config/nvs.dat /opt/OpenSprinkler-Firmware/nvs.dat
sudo systemctl start opensprinkler.service