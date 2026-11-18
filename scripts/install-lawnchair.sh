#!/bin/bash
# Installs Lawnchair 15 (open-source launcher) from its GitHub releases.
cd "$(dirname "$0")/.."; mkdir -p apks
URL=$(curl -s "https://api.github.com/repos/LawnchairLauncher/lawnchair/releases" | grep -o '"browser_download_url": *"[^"]*\.apk"' | grep '/download/v15' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/')
echo "Downloading: $URL"
curl -L -o apks/lawnchair.apk "$URL" && adb install -r apks/lawnchair.apk
echo "Now on the phone: Settings > Apps > Default apps > Home app > Lawnchair"
