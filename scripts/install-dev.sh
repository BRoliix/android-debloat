#!/bin/bash
# Installs the Linux dev toolkit apps on the phone (all free/open source, from official GitHub releases)
# and applies the Android tweaks that stop Termux sessions being killed ("signal 9").
cd "$(dirname "$0")/.."
adb get-state >/dev/null 2>&1 || { echo "Phone not connected - run: adb devices"; exit 1; }
ABI=$(adb shell getprop ro.product.cpu.abi | tr -d '\r'); echo "Phone CPU: $ABI"
mkdir -p apks
get() { # repo  tag-path  name  pattern
  local json=$(curl -s "https://api.github.com/repos/$1/releases/$2")
  local urls=$(echo "$json" | grep -o '"browser_download_url": *"[^"]*\.apk"' | sed 's/.*"\(https[^"]*\)"/\1/')
  local url=$(echo "$urls" | grep -i -- "$4" | head -1); [ -z "$url" ] && url=$(echo "$urls" | grep -i universal | head -1); [ -z "$url" ] && url=$(echo "$urls" | head -1)
  if [ -z "$url" ]; then echo "!! $3: download not found, skipping"; return; fi
  echo "== $3: $url"; curl -sL -o "apks/$3.apk" "$url" && adb install -r "apks/$3.apk"
}
get termux/termux-app       latest       termux         "$ABI"
get termux/termux-widget    latest       termux-widget  "apk"
get termux/termux-x11       tags/nightly termux-x11     "$ABI"
get zhanghai/MaterialFiles  latest       material-files "apk"
get Donnnno/Arcticons       latest       arcticons      "dark"
echo "== Stop Android killing Termux processes (phantom process limit)"
adb shell settings put global settings_enable_monitor_phantom_procs false
adb shell device_config set_sync_disabled_for_tests persistent
adb shell device_config put activity_manager max_phantom_processes 2147483647
echo "== Exempt Termux from battery optimisation"
adb shell dumpsys deviceidle whitelist +com.termux >/dev/null
adb shell dumpsys deviceidle whitelist +com.termux.x11 >/dev/null
adb shell pm grant com.termux android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
adb shell pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
echo "== Copy setup script + wallpaper to the phone"
adb push termux/dev-setup.sh /sdcard/Download/dev-setup.sh >/dev/null
adb shell mkdir -p /sdcard/Pictures/Wallpapers
adb push assets/broly-terminal-wallpaper.png /sdcard/Pictures/Wallpapers/ >/dev/null
adb shell am start -n com.termux/.app.TermuxActivity >/dev/null
echo "DONE - Termux is opening on the phone."
