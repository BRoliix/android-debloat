#!/bin/bash
# Installs Obtainium (free, open source) - updates your apps straight from their GitHub releases, since there is no Play Store.
cd "$(dirname "$0")/.."; mkdir -p apks
URLS=$(curl -s "https://api.github.com/repos/ImranR98/Obtainium/releases/latest" | grep -o '"browser_download_url": *"[^"]*\.apk"' | sed 's/.*"\(https[^"]*\)"/\1/')
URL=$(echo "$URLS" | grep -i arm64 | grep -vi fdroid | head -1); [ -z "$URL" ] && URL=$(echo "$URLS" | grep -vi fdroid | head -1)
[ -z "$URL" ] && { echo "Obtainium download not found"; exit 1; }
echo "Downloading: $URL"
curl -L -o apks/obtainium.apk "$URL" && adb install -r apks/obtainium.apk || exit 1
adb push lists/obtainium-apps.txt /sdcard/Download/obtainium-apps.txt >/dev/null
echo "Done. The list of app links to add is in Downloads/obtainium-apps.txt on the phone."
