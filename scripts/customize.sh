#!/bin/bash
# Speed + ad-blocking tweaks, Lawnicons icon pack, then a reboot test and the RAM "after" snapshot.
cd "$(dirname "$0")/.."; mkdir -p apks snapshots
echo "== Animations to 0.5x (snappier)"
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
echo "== Private DNS -> AdGuard DNS (blocks ads/trackers in all apps)"
adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier dns.adguard-dns.com
echo "== Lawnicons icon pack (made by the Lawnchair team, open source)"
URL=$(curl -s "https://api.github.com/repos/LawnchairLauncher/lawnicons/releases/latest" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/')
if [ -n "$URL" ]; then echo "Downloading: $URL"; curl -sL -o apks/lawnicons.apk "$URL" && adb install apks/lawnicons.apk; else echo "Lawnicons download not found - skipping"; fi
echo "== Reboot test (phone restarts, takes ~1-2 min)"
adb reboot; adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done
echo "Booted. Letting it settle for 90 seconds..."; sleep 90
adb shell dumpsys meminfo > snapshots/ram-after.txt
echo "== RAM before vs after"
grep "Used RAM" snapshots/ram-before.txt | sed 's/^/BEFORE /'; grep "Used RAM" snapshots/ram-after.txt | sed 's/^/AFTER  /'
echo DONE
