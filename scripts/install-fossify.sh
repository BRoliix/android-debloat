#!/bin/bash
# Installs Fossify Messages (free, open source, works without Google) and makes it the default SMS app.
cd "$(dirname "$0")/.."; mkdir -p apks
URLS=$(curl -s "https://api.github.com/repos/FossifyOrg/Messages/releases/latest" | grep -o '"browser_download_url": *"[^"]*\.apk"' | sed 's/.*"\(https[^"]*\)"/\1/')
URL=$(echo "$URLS" | grep -i foss | head -1); [ -z "$URL" ] && URL=$(echo "$URLS" | head -1)
[ -z "$URL" ] && { echo "Could not find the Fossify Messages download"; exit 1; }
echo "Downloading: $URL"
curl -L -o apks/fossify-messages.apk "$URL" && adb install apks/fossify-messages.apk || exit 1
adb shell cmd role add-role-holder android.app.role.SMS org.fossify.messages 2>/dev/null
echo "Default SMS app now: $(adb shell cmd role get-role-holders android.app.role.SMS | tr -d '\r')"
echo "If it still says com.google.android.apps.messaging: open Fossify Messages on the phone and accept 'Set as default SMS app'."
