#!/bin/bash
# Safety checks before removing Google core. Stops if any replacement is not the default yet.
cd "$(dirname "$0")/.."
sms=$(adb shell cmd role get-role-holders android.app.role.SMS | tr -d '\r')
home=$(adb shell cmd role get-role-holders android.app.role.HOME | tr -d '\r')
ime=$(adb shell settings get secure default_input_method | tr -d '\r')
echo "SMS app:  $sms"; echo "Home app: $home"; echo "Keyboard: $ime"
case "$sms" in *google*|"") echo "STOP: Fossify Messages is not the default SMS app yet."; exit 1;; esac
case "$home" in *hihonor*|"") echo "STOP: Lawnchair is not the default home app yet."; exit 1;; esac
case "$ime" in *touchtype*) ;; *) echo "STOP: SwiftKey is not the default keyboard."; exit 1;; esac
echo
echo "WARNING: this turns off Google Play Store, Play Services and Google Services Framework."
echo "Banking apps, Google sign-in, push notifications in many apps and Android Auto will stop working."
read -p "Type 'yes' to continue: " ok; [ "$ok" = "yes" ] || { echo "Skipped."; exit 0; }
bash scripts/run-batch.sh lists/batch5.txt
