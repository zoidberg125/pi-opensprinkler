#!/usr/bin/env bash
set -e

# Pfad zum Repo-Verzeichnis
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$REPO_DIR/config"

# Erstelle den Ordner, falls er nicht existiert
mkdir -p "$CONFIG_DIR"

# Kopiere die Konfigurationsdatei aus OpenSprinkler
if [ -f "/opt/OpenSprinkler-Firmware/stn.dat" ]; then
    cp /opt/OpenSprinkler-Firmware/stn.dat "$CONFIG_DIR/stn.dat"
    echo "Konfiguration stn.dat erfolgreich nach $CONFIG_DIR kopiert."
else
    echo "Fehler: /opt/OpenSprinkler-Firmware/stn.dat wurde nicht gefunden!"
    exit 1
fi

# Automatisch bei Git committen und pushen
cd "$REPO_DIR"
git add config/stn.dat

# Nur committen, wenn es tatsächlich Änderungen gab
if ! git diff-index --quiet HEAD --; then
    git commit -m "Automatisches Backup der OpenSprinkler Konfiguration $(date +'%Y-%m-%d %H:%M')"
    git push origin main
    echo "Backup erfolgreich zu GitHub gepusht!"
else
    echo "Keine Änderungen in der Konfiguration festgestellt."
fi