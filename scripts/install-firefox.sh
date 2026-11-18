#!/bin/bash
# Installs the official Firefox for Android (Mozilla's own download server), makes it the default browser, removes Cromite.
cd "$(dirname "$0")/.."; mkdir -p apks
ABI=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
VER=$(curl -s https://product-details.mozilla.org/1.0/mobile_versions.json | grep -o '"version": *"[^"]*"' | head -1 | sed 's/.*"\([0-9][^"]*\)"/\1/')
[ -z "$VER" ] && { echo "Could not read the latest Firefox version"; exit 1; }
URL="https://archive.mozilla.org/pub/fenix/releases/$VER/android/fenix-$VER-android-$ABI/fenix-$VER.multi.android-$ABI.apk"
echo "Downloading Firefox $VER: $URL"
curl -fL --retry 5 -C - -o apks/firefox.apk "$URL" && adb install -r apks/firefox.apk || { echo "Firefox download/install failed"; exit 1; }
adb shell cmd role add-role-holder android.app.role.BROWSER org.mozilla.firefox 2>/dev/null
echo "Default browser now: $(adb shell cmd role get-role-holders android.app.role.BROWSER | tr -d '\r')"
CR=$(adb shell pm list packages | tr -d '\r' | grep -i cromite | sed 's/package://' | head -1)
[ -n "$CR" ] && adb uninstall "$CR" && echo "Removed Cromite ($CR)"
