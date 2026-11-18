#!/bin/bash
# Switches the default keyboard to SwiftKey, then turns off the Honor keyboard only if typing works.
cd "$(dirname "$0")/.."
SK=$(adb shell ime list -a -s </dev/null | tr -d '\r' | grep -i touchtype | head -1)
[ -z "$SK" ] && { echo "SwiftKey keyboard not found on phone"; exit 1; }
adb shell ime enable "$SK"; adb shell ime set "$SK"
echo "Default keyboard now: $(adb shell settings get secure default_input_method | tr -d '\r')"
read -p "On the phone, open any text box and type a word. Does SwiftKey show and work? (y/n) " a
if [ "$a" = "y" ]; then
  echo "com.preff.kb.hr   # Honor keyboard (ad/push service)" > lists/batch-keyboard.txt
  bash scripts/run-batch.sh lists/batch-keyboard.txt
else
  echo "Leaving the Honor keyboard on. Tell Claude what you saw."
fi
