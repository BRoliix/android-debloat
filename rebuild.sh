#!/bin/bash
# Rebuilds the whole setup on a fresh / reset HONOR X6c. Run from this folder with the phone connected (adb devices = device).
cd "$(dirname "$0")"
step() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; read -p "Press Enter to continue (Ctrl+C to stop)... "; }
adb get-state >/dev/null 2>&1 || { echo "Phone not connected - run: adb devices"; exit 1; }
MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
echo "Phone: $MODEL"
echo "These scripts were made for the HONOR X6c (MagicOS 9 / Android 15). On other phones, read every list in lists/ first."
read -p "Type 'yes' to continue: " ok; [ "$ok" = "yes" ] || exit 1
step "1. Keyboard -> SwiftKey";               bash scripts/switch-keyboard.sh
step "2. Ads & promos";                       bash scripts/run-batch.sh lists/batch1.txt
step "3. Honor extras";                       bash scripts/run-batch.sh lists/batch2.txt
step "4. Google apps";                        bash scripts/run-batch.sh lists/batch3.txt
step "5. Installed apps (data kept)";         [ -f lists/batch4.txt ] && bash scripts/run-batch.sh lists/batch4.txt || echo "No lists/batch4.txt - skipping (see lists/batch4.example.txt)"
step "6. Fossify Messages (SMS)";             bash scripts/install-fossify.sh
step "7. Lawnchair - then set it as Home app on the phone"; bash scripts/install-lawnchair.sh
step "8. Google core (checks defaults first)"; bash scripts/run-batch5.sh
step "9. Honor Themes";                       bash scripts/run-batch.sh lists/batch-themes.txt
step "10. Speed, ad-block DNS, Lawnicons, reboot test"; bash scripts/customize.sh
step "11. Linux dev apps (Termux etc.)";      bash scripts/install-dev.sh
step "12. Firefox";                           bash scripts/install-firefox.sh
step "13. Obtainium (updates)";               bash scripts/install-obtainium.sh
echo; echo "Phone side: open Termux -> termux-setup-storage -> bash ~/storage/downloads/dev-setup.sh"
