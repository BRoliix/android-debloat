#!/bin/bash
# Installs Cromite (free, open-source Chromium browser with built-in ad blocking) and makes it the default browser.
cd "$(dirname "$0")/.."; mkdir -p apks
URL=$(curl -s "https://api.github.com/repos/uazo/cromite/releases/latest" | grep -o '"browser_download_url": *"[^"]*\.apk"' | sed 's/.*"\(https[^"]*\)"/\1/' | grep -i arm64 | head -1)
[ -z "$URL" ] && { echo "Cromite download not found"; exit 1; }
echo "Downloading: $URL"
curl -L -o apks/cromite.apk "$URL" && adb install -r apks/cromite.apk || exit 1
PKG=$(adb shell pm list packages | tr -d '\r' | grep -i cromite | head -1 | sed 's/package://')
echo "Installed as: $PKG"
adb shell cmd role add-role-holder android.app.role.BROWSER "$PKG" 2>/dev/null
echo "Default browser now: $(adb shell cmd role get-role-holders android.app.role.BROWSER | tr -d '\r')"
