#!/bin/bash
# =============================================================================
# arch-setup/install-liveboot.sh
# Automated Arch Linux Live Boot setup script (lightweight)
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
# PRE-CHECK — Fix DNS sebelum mulai
# =============================================================================
section "PRE-CHECK: Memastikan Koneksi Internet"

info "Mengatur DNS ke Google & Cloudflare..."
sudo tee /etc/resolv.conf > /dev/null << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# Cegah NetworkManager override resolv.conf
sudo chattr +i /etc/resolv.conf 2>/dev/null || true

info "Menunggu DNS aktif..."
sleep 2

# Test koneksi
MAX_RETRY=5
ATTEMPT=0
CONNECTED=false

while [[ $ATTEMPT -lt $MAX_RETRY ]]; do
  ATTEMPT=$((ATTEMPT + 1))
  if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
    CONNECTED=true
    break
  fi
  warn "Koneksi belum tersedia, mencoba lagi... ($ATTEMPT/$MAX_RETRY)"
  sleep 5
done

if [[ "$CONNECTED" == false ]]; then
  error "Tidak ada koneksi internet setelah $MAX_RETRY percobaan. Pastikan kamu sudah terhubung ke internet."
fi

# Test DNS resolve
if ! ping -c 1 -W 3 github.com &>/dev/null; then
  warn "DNS masih bermasalah, mencoba flush DNS..."
  sudo systemctl restart systemd-resolved 2>/dev/null || true
  sleep 3
  if ! ping -c 1 -W 3 github.com &>/dev/null; then
    error "Tidak bisa resolve github.com. Cek koneksi internet kamu."
  fi
fi

success "Koneksi internet OK, DNS berjalan normal."

# =============================================================================
# STEP 1 — Install pacman packages
# =============================================================================
section "STEP 1: Install Pacman Packages"

info "Memperbarui mirrorlist ke server tercepat (Reflector)..."
sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || warn "Gagal menjalankan reflector, menggunakan mirror bawaan."

info "Memperbarui archlinux-keyring untuk mencegah error signature PGP..."
sudo pacman -Sy --noconfirm archlinux-keyring

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
  nodejs
  npm
  clang
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  pipewire
  pipewire-alsa
  pipewire-pulse
  playerctl
  polkit-kde-agent
  proton-vpn-gtk-app
  python
  python-pip
  qt5-wayland
  qt6-wayland
  rofi-wayland
  sddm
  scrcpy
  slurp
  swappy
  swayidle
  swaylock
  ttf-cascadia-code
  ttf-font-awesome
  ttf-jetbrains-mono-nerd
  unzip
  vimix-cursors
  vivid
  wget
  wireplumber
  wl-clipboard
  xdg-desktop-portal-wlr
  xdg-user-dirs
  xorg-xwayland
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

info "Mengupdate database pacman (Full Upgrade)..."
# Diubah ke -Syu untuk menghindari isu dependencies rusak
sudo pacman -Syu --noconfirm

info "Menginstall ${#PACMAN_PACKAGES[@]} paket pacman..."
sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"

success "Pacman packages selesai diinstall."

# =============================================================================
# STEP 2 — Enable Services
# =============================================================================
section "STEP 2: Enable Services"

sudo systemctl enable sddm.service
success "sddm.service diaktifkan."


# =============================================================================
# STEP 3 — Install yay (AUR helper)
# =============================================================================
section "STEP 3: Install yay"

# Set curl retry di makepkg.conf secara aman
info "Mengatur curl retry di makepkg.conf..."
if ! grep -q "--retry 5" /etc/makepkg.conf; then
  sudo sed -i '/curl/s/-o %o %u/--retry 5 --retry-delay 5 -o %o %u/' /etc/makepkg.conf
  success "curl retry diatur ke 5x dengan delay 5 detik."
else
  info "curl retry sudah diatur, skip."
fi

if command -v yay &>/dev/null; then
  info "yay sudah terinstall, skip."
else
  info "Menginstall yay dari AUR..."
  MAX_RETRY=3
  ATTEMPT=0
  YAY_SUCCESS=false

  while [[ $ATTEMPT -lt $MAX_RETRY ]]; do
    ATTEMPT=$((ATTEMPT + 1))
    info "Percobaan ke-$ATTEMPT dari $MAX_RETRY..."

    TMPDIR=$(mktemp -d)
    if git clone --depth=1 https://aur.archlinux.org/yay.git "$TMPDIR/yay"; then
      cd "$TMPDIR/yay"
      if makepkg -si --noconfirm; then
        cd "$SCRIPT_DIR"
        rm -rf "$TMPDIR"
        success "yay berhasil diinstall."
        YAY_SUCCESS=true
        break
      else
        warn "makepkg gagal, mencoba ulang..."
        cd "$SCRIPT_DIR"
        rm -rf "$TMPDIR"
      fi
    else
      warn "git clone gagal, mencoba ulang dalam 5 detik..."
      rm -rf "$TMPDIR"
      sleep 5
    fi
  done

  if [[ "$YAY_SUCCESS" == false ]]; then
    error "yay gagal diinstall setelah $MAX_RETRY percobaan. Cek koneksi internet kamu."
  fi
fi

# =============================================================================
# STEP 4 — Install AUR packages via yay
# =============================================================================
section "STEP 4: Install AUR Packages"

# Helper: auto import missing PGP key
import_missing_pgp_key() {
  local output="$1"
  local key_id
  key_id=$(echo "$output" | grep -oP '(?<=key |NO_PUBKEY )[0-9A-Fa-f]{8,}' | tail -n1)
  if [[ -n "$key_id" ]]; then
    warn "PGP key tidak ditemukan: $key_id — mencoba import otomatis..."
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$key_id" 2>/dev/null || \
    gpg --keyserver hkps://keys.openpgp.org --recv-keys "$key_id" 2>/dev/null || \
    gpg --keyserver hkps://pgp.mit.edu --recv-keys "$key_id" 2>/dev/null
    return 0
  fi
  return 1
}

AUR_PACKAGES=(
  zen-browser-bin
  brave-bin
  librewolf-bin
  obsidian
  swayfx
  gimgv
  ttf-ms-fonts
)

FAILED_PACKAGES=()

info "Menginstall ${#AUR_PACKAGES[@]} paket AUR..."
for pkg in "${AUR_PACKAGES[@]}"; do
  info "Installing: $pkg"
  install_output=$(yay -S --noconfirm --needed --answerdiff None --answerclean None "$pkg" 2>&1)
  install_status=$?

  if [[ $install_status -ne 0 ]]; then
    if echo "$install_output" | grep -qiE "pgp|gpg|signature|key"; then
      import_missing_pgp_key "$install_output"
      info "Retry install: $pkg setelah import PGP key..."
      if yay -S --noconfirm --needed --answerdiff None --answerclean None "$pkg"; then
        success "$pkg berhasil diinstall setelah import PGP key."
      else
        warn "$pkg gagal diinstall bahkan setelah import PGP key."
        FAILED_PACKAGES+=("$pkg")
      fi
    else
      warn "$pkg gagal diinstall (bukan masalah PGP)."
      FAILED_PACKAGES+=("$pkg")
    fi
  else
    success "$pkg berhasil diinstall."
  fi
done

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
  echo ""
  warn "Package berikut gagal dan perlu diinstall manual:"
  for pkg in "${FAILED_PACKAGES[@]}"; do
    echo -e "  ${RED}✗${RESET} $pkg"
  done
  echo ""
else
  success "Semua AUR packages selesai diinstall."
fi
# =============================================================================
# STEP 5 — Copy config files ke ~/.config
# =============================================================================
section "STEP 5: Copy Config ke ~/.config"

info "Menyalin config/alacritty ke ~/.config/alacritty..."
mkdir -p ~/.config/alacritty
cp -r "$SCRIPT_DIR/config/alacritty/." ~/.config/alacritty/ 2>/dev/null || true

info "Menyalin config/dunst ke ~/.config/dunst..."
mkdir -p ~/.config/dunst
cp -r "$SCRIPT_DIR/config/dunst/." ~/.config/dunst/ 2>/dev/null || true

info "Menyalin config/sway ke ~/.config/sway..."
mkdir -p ~/.config/sway
cp -r "$SCRIPT_DIR/config/sway/." ~/.config/sway/ 2>/dev/null || true

info "Memberikan permission chmod +x pada ~/.config/sway/scripts/..."
if [[ -d ~/.config/sway/scripts ]]; then
  chmod +x ~/.config/sway/scripts/* 2>/dev/null || true
  success "chmod +x selesai pada sway/scripts."
else
  warn "Folder ~/.config/sway/scripts tidak ditemukan, skip chmod."
fi

success "Config files berhasil disalin."

info "Memperbaiki desktop entry scrcpy..."
# Hapus entry duplikat scrcpy-audio jika ada
if [[ -f /usr/share/applications/scrcpy-audiofwd.desktop ]]; then
  sudo rm -f /usr/share/applications/scrcpy-audiofwd.desktop
  success "Entry duplikat scrcpy-audiofwd dihapus."
fi

# Set icon untuk scrcpy
if [[ -f /usr/share/applications/scrcpy.desktop ]]; then
  sudo sed -i 's|^Icon=.*|Icon=phone|' /usr/share/applications/scrcpy.desktop
  # Jika belum ada baris Icon sama sekali, tambahkan
  if ! grep -q "^Icon=" /usr/share/applications/scrcpy.desktop; then
    sudo sed -i '/^Exec=/a Icon=phone' /usr/share/applications/scrcpy.desktop
  fi
  success "Icon scrcpy berhasil diset."
fi


# =============================================================================
# STEP 6 — Setup NvChad
# =============================================================================
section "STEP 6: Setup NvChad"

info "Menghapus config nvim lama jika ada..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim

info "Mengclone NvChad starter ke ~/.config/nvim..."
git clone --depth=1 https://github.com/NvChad/starter ~/.config/nvim
success "NvChad starter berhasil diclone."
info "Mengatur tema NvChad ke horizon..."
mkdir -p ~/.config/nvim/lua
cat > ~/.config/nvim/lua/chadrc.lua << 'LUAEOF'
---@type ChadrcConfig
local M = {}
M.ui = {
  theme = "horizon",
}
return M
LUAEOF
success "Tema horizon berhasil diatur."
info "NvChad akan auto-install semua plugin saat pertama kali kamu buka nvim."

info "Menginstall LSP tools via npm: prettier dan pyright..."
sudo npm install -g prettier pyright
success "prettier dan pyright berhasil diinstall."
info "clangd sudah tersedia dari package clang."

# =============================================================================
# STEP 7 — Install Rofi themes
# =============================================================================
section "STEP 7: Install Rofi Themes"

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
# STEP 8 — Setup Powerlevel10k
# =============================================================================
section "STEP 8: Setup Powerlevel10k"

if [[ -d "$SCRIPT_DIR/powerlevel10k" && "$(ls -A "$SCRIPT_DIR/powerlevel10k" 2>/dev/null | grep -v '.gitkeep')" ]]; then
  info "Menyalin powerlevel10k dari repo ke ~/powerlevel10k..."
  cp -r "$SCRIPT_DIR/powerlevel10k/." ~/powerlevel10k/
  success "powerlevel10k berhasil disalin."
else
  warn "Folder powerlevel10k di repo kosong, mengclone dari GitHub..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  success "powerlevel10k berhasil diclone."
fi

# =============================================================================
# STEP 9 — Copy .zshrc
# =============================================================================
section "STEP 9: Setup .zshrc dan .p10k.zsh"

if [[ -f "$SCRIPT_DIR/dotfiles/.zshrc" ]]; then
  info "Menyalin .zshrc ke ~/..."
  cp "$SCRIPT_DIR/dotfiles/.zshrc" ~/.zshrc
  success ".zshrc berhasil disalin."
else
  warn ".zshrc tidak ditemukan di dotfiles/, pastikan file tersebut ada."
fi

info "Menyalin .p10k.zsh ke ~/..."
if [[ -f "$SCRIPT_DIR/dotfiles/.p10k.zsh" ]]; then
  cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" ~/.p10k.zsh
  success ".p10k.zsh berhasil disalin."
else
  warn ".p10k.zsh tidak ditemukan di dotfiles/, skip. Jalankan 'p10k configure' manual setelah reboot."
fi

# =============================================================================
# STEP 10 — Set default shell ke zsh
# =============================================================================
section "STEP 10: Set Default Shell ke ZSH"

if [[ "$SHELL" != "$(which zsh)" ]]; then
  info "Mengubah default shell ke zsh..."
  chsh -s "$(which zsh)"
  success "Default shell diubah ke zsh. Efektif setelah re-login."
else
  info "Shell sudah zsh, skip."
fi

# =============================================================================
# STEP 11 — Setup Projects/SilentSDDM
# =============================================================================
section "STEP 11: Setup Projects/SilentSDDM"

info "Membuat folder ~/Projects..."
mkdir -p ~/Projects

if [[ -d "$SCRIPT_DIR/Projects/SilentSDDM" ]]; then
  info "Menyalin SilentSDDM ke ~/Projects/SilentSDDM..."
  cp -r "$SCRIPT_DIR/Projects/SilentSDDM/." ~/Projects/SilentSDDM/

  info "Memberikan permission chmod +x pada ~/Projects/SilentSDDM/*.sh..."
  if compgen -G ~/Projects/SilentSDDM/*.sh &>/dev/null; then
    chmod +x ~/Projects/SilentSDDM/*.sh
    success "chmod +x selesai pada SilentSDDM."
  else
    warn "Tidak ada file .sh di SilentSDDM, skip chmod."
  fi

  info "Menjalankan SilentSDDM install script..."
  if [[ -f ~/Projects/SilentSDDM/install.sh ]]; then
    cd ~/Projects/SilentSDDM
    bash install.sh
    cd "$SCRIPT_DIR"
    success "SilentSDDM berhasil diinstall."
  else
    warn "install.sh tidak ditemukan di SilentSDDM, skip install."
  fi
else
  warn "Folder $SCRIPT_DIR/Projects/SilentSDDM tidak ditemukan, skip langkah ini."
fi

# =============================================================================
# SELESAI
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║       INSTALASI SELESAI! 🎉              ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${YELLOW}System akan reboot dalam 5 detik...${RESET}"
echo -e "  ${YELLOW}Tekan Ctrl+C untuk membatalkan reboot.${RESET}"
echo ""
sleep 5
sudo reboot
