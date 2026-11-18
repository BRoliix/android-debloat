#!/bin/bash
# Puts the phone back the way it was before this debloat - works even without UNDO.md / undo-all.sh.
#  1. Switches every app in lists/ back on
#  2. Sets the stock home screen, SMS app and keyboard back as default
#  3. Resets animations, Private DNS and the Termux background tweaks
#  4. Optionally uninstalls the replacement apps
# Usage: bash restore.sh        (asks before each part)
#        bash restore.sh --all  (no questions, does everything except removing Termux)
cd "$(dirname "$0")"
adb get-state >/dev/null 2>&1 || { echo "Phone not connected - run: adb devices"; exit 1; }
ALL=0; [ "$1" = "--all" ] && ALL=1
say() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; }
ask() { [ $ALL = 1 ] && return 0; read -p "$1 (y/n) " a; [ "$a" = "y" ]; }
sh_() { adb shell "$@" </dev/null 2>&1 | tr -d '\r'; }

# 1. Apps back on. Google core first so everything else has Play Services to talk to.
if ask "Switch all disabled apps back on?"; then
  say "Switching apps back on"
  on=0; skip=0
  for f in lists/batch5.txt $(ls lists/batch*.txt | grep -v batch5.txt); do
    [ -f "$f" ] || continue
    while IFS= read -r line || [ -n "$line" ]; do
      pkg=$(echo "${line%%#*}" | tr -d '[:space:]'); [ -z "$pkg" ] && continue
      out=$(sh_ pm enable "$pkg")
      if echo "$out" | grep -q "new state: enabled"; then echo "ON     $pkg"; on=$((on+1)); continue; fi
      out=$(sh_ cmd package install-existing "$pkg")
      if echo "$out" | grep -qi "installed for user"; then echo "ON     $pkg (reinstalled for user)"; on=$((on+1))
      else skip=$((skip+1)); fi
    done < "$f"
  done
  echo "Done: $on switched on, $skip not on this phone / already on."
fi

# 2. Stock defaults. Uses this phone's saved defaults if snapshots/ has them, otherwise HONOR stock.
if ask "Set the stock home screen, SMS app and keyboard back as default?"; then
  say "Restoring default apps"
  HOME_PKG=$(cat snapshots/default-home.txt 2>/dev/null | tr -d '[:space:]'); HOME_PKG=${HOME_PKG:-com.hihonor.android.launcher}
  SMS_PKG=$(cat snapshots/default-sms.txt 2>/dev/null | tr -d '[:space:]');   SMS_PKG=${SMS_PKG:-com.google.android.apps.messaging}
  sh_ cmd role add-role-holder android.app.role.HOME "$HOME_PKG" >/dev/null
  sh_ cmd role add-role-holder android.app.role.SMS "$SMS_PKG" >/dev/null
  echo "Home: $(sh_ cmd role get-role-holders android.app.role.HOME)"
  echo "SMS:  $(sh_ cmd role get-role-holders android.app.role.SMS)"
  IME=$(sh_ ime list -a -s | grep -i preff | head -1)
  if [ -n "$IME" ]; then sh_ ime enable "$IME" >/dev/null; sh_ ime set "$IME" >/dev/null; fi
  echo "Keyboard: $(sh_ settings get secure default_input_method)"
  echo "(If home or SMS didn't change: Settings > Apps > Default apps on the phone.)"
fi

# 3. Settings tweaks back to Android defaults.
if ask "Reset animations, Private DNS and Termux background tweaks?"; then
  say "Resetting settings"
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do sh_ settings put global $k 1.0 >/dev/null; done
  sh_ settings put global private_dns_mode opportunistic >/dev/null
  sh_ settings delete global private_dns_specifier >/dev/null
  sh_ settings delete global settings_enable_monitor_phantom_procs >/dev/null
  sh_ device_config delete activity_manager max_phantom_processes >/dev/null
  sh_ device_config set_sync_disabled_for_tests none >/dev/null
  for p in com.termux com.termux.x11; do sh_ dumpsys deviceidle whitelist -$p >/dev/null; done
  echo "Animations 1x, Private DNS automatic, phantom-process limit and battery optimisation back to normal."
fi

# 4. Replacement apps. Termux is asked separately because removing it deletes everything inside it.
INSTALLED=$(sh_ pm list packages -3 | sed 's/package://')
REPL=$(echo "$INSTALLED" | grep -E '^(org\.fossify\.messages|app\.lawnchair|org\.mozilla\.firefox|dev\.imranr\.obtainium|me\.zhanghai\.android\.files|com\.donnnno\.arcticons|org\.cromite|com\.cromite)' )
if [ -n "$REPL" ] && { [ $ALL = 1 ] || ask "Uninstall the replacement apps ($(echo $REPL | tr '\n' ' '))?"; }; then
  say "Removing replacement apps"
  for p in $REPL; do echo "$p: $(sh_ pm uninstall "$p")"; done
fi
TERMUX=$(echo "$INSTALLED" | grep -E '^com\.termux')
if [ -n "$TERMUX" ] && [ $ALL = 0 ] && ask "Uninstall Termux too? This DELETES everything inside it (projects, Ubuntu, keys)"; then
  for p in $TERMUX; do echo "$p: $(sh_ pm uninstall "$p")"; done
fi

say "Restore finished"
echo "Reboot the phone to finish: adb reboot"
