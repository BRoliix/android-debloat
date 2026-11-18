# android-debloat — HONOR X6c (MagicOS 9 / Android 15)

No-root debloat + Linux dev setup over ADB. Everything is free / open source and reversible.

> **Use at your own risk.** Made and tested on one HONOR X6c (MagicOS 9 / Android 15). Nothing is deleted. Apps are disabled for your user and can be switched back on with ADB. But turning off the wrong system app can break features or leave a phone stuck at boot. **Read every list in `lists/` before running it and delete any line you want to keep.**

## Before you run it
- `lists/batch5.txt` turns off **Google Play Services / Play Store**. Banking apps, Google sign-in and push notifications in many apps stop working. The script asks first.
- `lists/batch2.txt` turns off **Find Device** (anti-theft). Remove those two lines if you want to keep it.
- `lists/batch4.txt` is for *your own* installed apps. Copy `lists/batch4.example.txt` to `lists/batch4.txt` and fill it in, or leave it out and the step is skipped.
- Phones other than the X6c: apps that aren't on your phone are skipped, but check the lists anyway.

## What it does
- Switches off 97 preinstalled apps (ads, Honor extras, Google apps, Google core) — **disabled, not deleted**
- Replaces: home screen → **Lawnchair** + Lawnicons · SMS → **Fossify Messages** · keyboard → **SwiftKey** · browser → **Firefox**
- 0.5× animations, AdGuard Private DNS (ad-blocking)
- **Termux** dev box: zsh + starship (Tokyo Night), git/gh, Python, Node, Java, C/C++, SSH, neovim
- **Ubuntu (proot-distro)**: Claude Code, Node 22, Railway CLI, Docker CLI · XFCE desktop via Termux:X11
- **Obtainium** for app updates (no Play Store)

Result: idle RAM use 3.12 GB → 2.63 GB.

## Rebuild after a reset
```bash
brew install android-platform-tools   # once, on the Mac
adb devices                            # phone must show "device"
bash rebuild.sh                        # walks through every step
```
Then on the phone in Termux: `termux-setup-storage` → `bash ~/storage/downloads/dev-setup.sh`

## Undo / restore
Put the phone back to stock (works for anyone, no log needed):
```bash
bash restore.sh         # asks before each part
bash restore.sh --all   # no questions (never removes Termux)
```
It switches every app in `lists/` back on, sets the stock home screen, SMS app and keyboard as default again, resets animations, Private DNS and the Termux background tweaks, and offers to uninstall the replacement apps. Removing Termux is asked separately because it deletes everything inside it.

Finer control: every run of `scripts/run-batch.sh` also writes `UNDO.md` (one command per app) and `undo-all.sh` on your machine. Any single app by hand: `adb shell pm enable <package>` or `adb shell cmd package install-existing <package>`.

## Layout
```
rebuild.sh            # runs every step in order (start here)
restore.sh            # puts the phone back to stock
scripts/              # Mac-side steps over ADB
  run-batch.sh          disable a package list (logs undo commands)
  run-batch5.sh         Google core - only if SMS/home/keyboard replacements are default
  switch-keyboard.sh    SwiftKey
  install-*.sh          replacement apps (Fossify, Lawnchair, Firefox, Obtainium, Termux...)
  customize.sh          animations, DNS, icon pack, reboot test, RAM check
lists/                # package lists for run-batch.sh + Obtainium app links (batch4 = your own apps)
termux/dev-setup.sh   # runs on the phone inside Termux - full dev environment
assets/               # wallpaper
```
Not committed (see `.gitignore`): `apks/` (downloaded installers), `snapshots/` (dumps from the phone), `UNDO.md` / `undo-all.sh` (your undo log) and `lists/batch4.txt` (your own apps).

## License
MIT. See `LICENSE`.
