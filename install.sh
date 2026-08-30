#!/usr/bin/env bash
set -e

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

# Submodule initialisieren (für moderne Firmware-Versionen erforderlich)
sudo git submodule update --init --recursive

# Kompilieren für Raspberry Pi (OS_PI)
echo "Kompiliere OpenSprinkler..."
sudo ./build.sh os_pi

echo "=== 3. Systemd Service einrichten ==="
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sudo cp "$SCRIPT_DIR/systemd/opensprinkler.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable opensprinkler.service
sudo systemctl restart opensprinkler.service

echo "=== Installation abgeschlossen! ==="
echo "OpenSprinkler läuft und ist im Browser unter http://<IP-DEINES-PI>:8080 erreichbar."