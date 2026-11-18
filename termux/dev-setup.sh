#!/data/data/com.termux/files/usr/bin/bash
# Run inside Termux:  bash ~/storage/downloads/dev-setup.sh
# Builds a themed Linux dev environment: Termux tools + Ubuntu (for Claude Code, Railway, Docker CLI) + optional XFCE desktop.
set -e
say() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; }
UPG='-o Dpkg::Options::=--force-confnew'

say "Updating Termux"
yes | pkg update $UPG; yes | pkg upgrade -y $UPG

say "Core dev tools (git, python, node, C/C++, java, ssh, editors)"
pkg install -y $UPG git gh openssh python nodejs-lts clang make cmake micro neovim zsh curl wget \
  tmux htop fastfetch starship ripgrep fd bat jq unzip tree proot-distro
pkg install -y openjdk-21 || pkg install -y openjdk-17

say "Look & feel: Tokyo Night colours, JetBrains Mono Nerd Font, extra keys row"
mkdir -p ~/.termux ~/.config ~/.zsh ~/bin ~/projects
cat > ~/.termux/colors.properties <<'C'
background=#1a1b26
foreground=#c0caf5
cursor=#c0caf5
color0=#15161e
color1=#f7768e
color2=#9ece6a
color3=#e0af68
color4=#7aa2f7
color5=#bb9af7
color6=#7dcfff
color7=#a9b1d6
color8=#414868
color9=#f7768e
color10=#9ece6a
color11=#e0af68
color12=#7aa2f7
color13=#bb9af7
color14=#7dcfff
color15=#c0caf5
C
cat > ~/.termux/termux.properties <<'P'
extra-keys = [['ESC','/','-','|','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','~','LEFT','DOWN','RIGHT','PGDN']]
terminal-cursor-style = bar
bell-character = ignore
P
curl -sL -o $PREFIX/tmp/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  && unzip -o -j $PREFIX/tmp/jbm.zip 'JetBrainsMonoNerdFontMono-Regular.ttf' -d $PREFIX/tmp/jbm >/dev/null \
  && cp $PREFIX/tmp/jbm/JetBrainsMonoNerdFontMono-Regular.ttf ~/.termux/font.ttf || echo "(font download failed - default font kept)"
termux-reload-settings || true

say "zsh + starship prompt + autosuggestions + syntax highlighting"
[ -d ~/.zsh/zsh-autosuggestions ] || git clone -q --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ -d ~/.zsh/zsh-syntax-highlighting ] || git clone -q --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
starship preset tokyo-night -o ~/.config/starship.toml 2>/dev/null || true
cat > ~/.zshrc <<'Z'
export PATH="$HOME/bin:$PATH"
HISTFILE=~/.zsh_history; HISTSIZE=10000; SAVEHIST=10000; setopt share_history
autoload -Uz compinit && compinit
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval "$(starship init zsh)"
alias ls='ls --color=auto' ll='ls -lah' cat='bat --paging=never' vim='nvim' cls='clear'
alias p='cd ~/projects' phone='cd ~/storage/shared'
# Ubuntu (glibc) for Claude Code, Railway CLI, Docker CLI. ~/projects is shared with Ubuntu.
ub() { proot-distro login ubuntu --shared-tmp --bind "$HOME/projects:/root/projects" -- "$@"; }
alias ubuntu='proot-distro login ubuntu --shared-tmp --bind $HOME/projects:/root/projects'
_inproj() { local r="${PWD#$HOME/projects}"; [ "$r" = "$PWD" ] && r=""; echo "/root/projects$r"; }
claude()  { ub bash -lc "cd '$(_inproj)' && ~/.local/bin/claude $*"; }
railway() { ub bash -lc "cd '$(_inproj)' && railway $*"; }
docker()  { ub bash -lc "cd '$(_inproj)' && docker $*"; }
[ -z "$TMUX" ] && fastfetch
Z
chsh -s zsh

say "SSH key (for GitHub / your servers)"
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "broly@x6c" >/dev/null

say "Ubuntu (takes a while)"
proot-distro list 2>/dev/null | grep -q "ubuntu.*installed" || proot-distro install ubuntu || true
proot-distro login ubuntu --shared-tmp -- bash -c '
set -e; export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git build-essential python3 python3-pip python3-venv openjdk-21-jdk-headless ca-certificates gnupg unzip ripgrep
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs
V=$(curl -s https://download.docker.com/linux/static/stable/aarch64/ | grep -o "docker-[0-9.]*\.tgz" | sort -V | tail -1)
[ -n "$V" ] && curl -sL "https://download.docker.com/linux/static/stable/aarch64/$V" | tar xz -C /tmp && mv /tmp/docker/docker /usr/local/bin/docker
npm install -g @railway/cli
curl -fsSL https://claude.ai/install.sh | bash
mkdir -p /root/projects
' || echo "(some Ubuntu steps failed - send the output to Claude)"

say "Linux desktop (XFCE) - only uses RAM while open"
pkg install -y x11-repo && pkg install -y termux-x11-nightly xfce4 xfce4-terminal firefox || echo "(desktop install failed - everything else is fine)"
cat > ~/bin/desktop <<'D'
#!/data/data/com.termux/files/usr/bin/bash
# Starts the XFCE desktop in the Termux:X11 app. Close with: pkill -f termux.x11 ; pkill xfce
termux-x11 :0 >/dev/null 2>&1 &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session >/dev/null 2>&1 &
D
chmod +x ~/bin/desktop

say "Termux:Widget shortcuts (home-screen buttons)"
mkdir -p ~/.shortcuts
printf '#!/data/data/com.termux/files/usr/bin/bash\ncd ~/projects && exec zsh\n' > ~/.shortcuts/Projects
printf '#!/data/data/com.termux/files/usr/bin/bash\n~/bin/desktop\n' > ~/.shortcuts/Desktop
printf '#!/data/data/com.termux/files/usr/bin/zsh\nsource ~/.zshrc; cd ~/projects; claude\n' > ~/.shortcuts/Claude
chmod +x ~/.shortcuts/*

say "ALL DONE"
echo "Your SSH public key (add it to GitHub > Settings > SSH keys):"; cat ~/.ssh/id_ed25519.pub
echo; echo "Close Termux completely and reopen it to load the new look."
