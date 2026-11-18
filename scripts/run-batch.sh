#!/bin/bash
# Usage: bash scripts/run-batch.sh lists/batch1.txt
# Disables each package for user 0 (keeps the app + data). If Honor blocks disabling,
# falls back to a per-user uninstall that keeps data (-k). Every change is logged with its undo command.
cd "$(dirname "$0")/.."
LIST="$1"
[ -f "$LIST" ] || { echo "List file not found: $LIST"; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "Phone not connected - run: adb devices"; exit 1; }
TS=$(date '+%Y-%m-%d %H:%M')
echo "" >> UNDO.md; echo "## $LIST  ($TS)" >> UNDO.md
[ -f undo-all.sh ] || echo "#!/bin/bash" > undo-all.sh
ok=0; skip=0; fail=0
while IFS= read -r line || [ -n "$line" ]; do
  pkg=$(echo "${line%%#*}" | tr -d '[:space:]')
  label=$(echo "$line" | sed -n 's/.*# *//p')
  [ -z "$pkg" ] && continue
  if [ -z "$(adb shell pm path "$pkg" </dev/null 2>/dev/null)" ]; then
    echo "SKIP   $pkg (not on phone)"; skip=$((skip+1)); continue
  fi
  out=$(adb shell pm disable-user --user 0 "$pkg" </dev/null 2>&1)
  if echo "$out" | grep -q "disabled-user"; then
    undo="adb shell pm enable $pkg"; how="disabled"
  else
    out2=$(adb shell pm uninstall -k --user 0 "$pkg" </dev/null 2>&1)
    if echo "$out2" | grep -q "Success"; then
      undo="adb shell cmd package install-existing $pkg"; how="removed for user (APK kept)"
    else
      echo "FAIL   $pkg -> $out | $out2"; fail=$((fail+1)); continue
    fi
  fi
  echo "OK     $pkg  [$how]  $label"
  echo "- \`$pkg\` ($label) - $how - undo: \`$undo\`" >> UNDO.md
  echo "$undo   # $label" >> undo-all.sh
  ok=$((ok+1))
done < "$LIST"
echo ""; echo "Done: $ok changed, $skip skipped, $fail failed. Undo commands are in UNDO.md"
