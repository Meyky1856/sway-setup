#!/bin/bash
# =============================================================================
# arch-setup/install.sh
# Automated Arch Linux post-install setup script
# =============================================================================

set -e  # Exit immediately on error

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${BLUE}  $*${RESET}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════${RESET}\n"; }

# ─── Root check ──────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  error "Jangan jalankan script ini sebagai root. Jalankan sebagai user biasa."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# STEP 1 — Install pacman packages
# =============================================================================
section "STEP 1: Install Pacman Packages"

PACMAN_PACKAGES=(
  adwaita-icon-theme
  alacritty
  autotiling
  base-devel
  brightnessctl
  btop
  cliphist
  code
  curl
  dolphin
  discord
  dunst
  eza
  fastfetch
  git
  github-cli
  gnome-themes-extra
  gsettings-desktop-schemas
  grim
  gvfs
  jq
  libnotify
  micro
  mpv
  neovim
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  obs-studio
  pipewire
  pipewire-alsa
  pipewire-pulse
  playerctl
  polkit-kde-agent
  proton-vpn-gtk-app
  python
  python-pip
  qbittorrent
  qt5-wayland
  qt6-wayland
  rofi-wayland
  sddm
  slurp
  snapper
  swappy
  swayidle
  swaylock
  ttf-font-awesome
  ttf-jetbrains-mono-nerd
  thunderbird
  unzip
  vimix-cursors
  wget
  wireplumber
  wl-clipboard
  xdg-desktop-portal-wlr
  xdg-user-dirs
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

info "Mengupdate database pacman..."
sudo pacman -Sy --noconfirm

info "Menginstall ${#PACMAN_PACKAGES[@]} paket pacman..."
sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"

success "Pacman packages selesai diinstall."

# =============================================================================
# STEP 2 — Enable SDDM
# =============================================================================
section "STEP 2: Enable SDDM Service"

sudo systemctl enable sddm.service
success "sddm.service diaktifkan."

# =============================================================================
# STEP 3 — Install yay (AUR helper)
# =============================================================================
section "STEP 3: Install yay"

if command -v yay &>/dev/null; then
  info "yay sudah terinstall, skip."
else
  info "Menginstall yay dari AUR..."
  TMPDIR=$(mktemp -d)
  git clone --depth=1 https://aur.archlinux.org/yay.git "$TMPDIR/yay"
  cd "$TMPDIR/yay"
  makepkg -si --noconfirm
  cd "$SCRIPT_DIR"
  rm -rf "$TMPDIR"
  success "yay berhasil diinstall."
fi

# =============================================================================
# STEP 4 — Install AUR packages via yay (--answerdiff None --answerclean None)
# =============================================================================
section "STEP 4: Install AUR Packages"

AUR_PACKAGES=(
  zen-browser-bin
  brave-bin
  librewolf-bin
  zotero-bin
  obsidian
  wps-office
  onlyoffice-bin
  zoom
  xclicker
  swayfx
  android-studio
  gimgv
)

info "Menginstall ${#AUR_PACKAGES[@]} paket AUR..."
yay -S --noconfirm --needed --answerdiff None --answerclean None "${AUR_PACKAGES[@]}"

success "AUR packages selesai diinstall."

# =============================================================================
# STEP 5 — Copy config files ke ~/.config
# =============================================================================
section "STEP 5: Copy Config ke ~/.config"

info "Menyalin config/alacritty ke ~/.config/alacritty..."
mkdir -p ~/.config/alacritty
cp -r "$SCRIPT_DIR/config/alacritty/." ~/.config/alacritty/

info "Menyalin config/sway ke ~/.config/sway..."
mkdir -p ~/.config/sway
cp -r "$SCRIPT_DIR/config/sway/." ~/.config/sway/

info "Memberikan permission chmod +x pada ~/.config/sway/scripts/..."
if [[ -d ~/.config/sway/scripts ]]; then
  chmod +x ~/.config/sway/scripts/*
  success "chmod +x selesai pada sway/scripts."
else
  warn "Folder ~/.config/sway/scripts tidak ditemukan, skip chmod."
fi

success "Config files berhasil disalin."

# =============================================================================
# STEP 6 — Install Rofi themes
# =============================================================================
section "STEP 6: Install Rofi Themes"

TMPDIR=$(mktemp -d)
info "Mengclone adi1090x/rofi..."
git clone --depth=1 https://github.com/adi1090x/rofi.git "$TMPDIR/rofi"
cd "$TMPDIR/rofi"
chmod +x setup.sh
./setup.sh
cd "$SCRIPT_DIR"
rm -rf "$TMPDIR"
success "Rofi themes berhasil diinstall."

info "Membuat symlink launcher dan powermenu..."
ln -sf ~/.config/rofi/launchers/type-1/launcher.sh ~/.config/rofi/launcher_active.sh
ln -sf ~/.config/rofi/powermenu/type-1/powermenu.sh ~/.config/rofi/powermenu_active.sh
success "Symlink rofi berhasil dibuat."

# =============================================================================
# STEP 7 — Setup Powerlevel10k
# =============================================================================
section "STEP 7: Setup Powerlevel10k"

if [[ -d "$SCRIPT_DIR/powerlevel10k" && "$(ls -A "$SCRIPT_DIR/powerlevel10k" | grep -v '.gitkeep')" ]]; then
  info "Menyalin powerlevel10k dari repo ke ~/powerlevel10k..."
  cp -r "$SCRIPT_DIR/powerlevel10k/." ~/powerlevel10k/
  success "powerlevel10k berhasil disalin."
else
  warn "Folder powerlevel10k di repo kosong, mengclone dari GitHub..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  success "powerlevel10k berhasil diclone."
fi

# =============================================================================
# STEP 8 — Copy .zshrc
# =============================================================================
section "STEP 8: Setup .zshrc"

info "Menyalin .zshrc ke ~/..."
cp "$SCRIPT_DIR/dotfiles/.zshrc" ~/.zshrc
success ".zshrc berhasil disalin."

# =============================================================================
# STEP 9 — Set default shell ke zsh
# =============================================================================
section "STEP 9: Set Default Shell ke ZSH"

if [[ "$SHELL" != "$(which zsh)" ]]; then
  info "Mengubah default shell ke zsh..."
  chsh -s "$(which zsh)"
  success "Default shell diubah ke zsh. Efektif setelah re-login."
else
  info "Shell sudah zsh, skip."
fi

# =============================================================================
# STEP 10 — Setup Projects/SilentSDDM
# =============================================================================
section "STEP 10: Setup Projects/SilentSDDM"

info "Membuat folder ~/Projects..."
mkdir -p ~/Projects

info "Menyalin SilentSDDM ke ~/Projects/SilentSDDM..."
cp -r "$SCRIPT_DIR/Projects/SilentSDDM/." ~/Projects/SilentSDDM/

info "Memberikan permission chmod +x pada ~/Projects/SilentSDDM/*.sh..."
if compgen -G ~/Projects/SilentSDDM/*.sh &>/dev/null; then
  chmod +x ~/Projects/SilentSDDM/*.sh
  success "chmod +x selesai pada SilentSDDM."
else
  warn "Tidak ada file .sh di SilentSDDM, skip chmod."
fi

# =============================================================================
# SELESAI
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║       INSTALASI SELESAI! 🎉              ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Yang perlu dilakukan manual setelah ini:${RESET}"
echo -e "  ${YELLOW}1.${RESET} Re-login atau reboot"
echo -e "  ${YELLOW}2.${RESET} Buka terminal, ketik: ${BOLD}p10k configure${RESET}"
echo -e "  ${YELLOW}3.${RESET} Setup SilentSDDM: ${BOLD}cd ~/Projects/SilentSDDM && ./install.sh${RESET} (sesuaikan nama scriptnya)"
echo ""
