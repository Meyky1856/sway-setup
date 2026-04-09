# arch-setup

Automated post-install setup untuk Arch Linux + Sway.

## Cara Pakai

```bash
git clone https://github.com/username/arch-setup.git
cd arch-setup
chmod +x install.sh
./install.sh
```

> Jangan jalankan sebagai root. Script akan meminta `sudo` sendiri ketika dibutuhkan.

---

## Apa yang Dilakukan install.sh

| Step | Aksi |
|------|------|
| 1 | Install semua pacman packages |
| 2 | Enable `sddm.service` |
| 3 | Install `yay` (AUR helper) |
| 4 | Install semua AUR packages via `yay` |
| 5 | Copy `config/` ke `~/.config/` + `chmod +x sway/scripts/*` |
| 6 | Install rofi themes (adi1090x) + buat symlink |
| 7 | Copy/clone `powerlevel10k` ke `~/powerlevel10k` |
| 8 | Copy `.zshrc` ke `~/` |
| 9 | Set default shell ke `zsh` |
| 10 | Copy `Projects/SilentSDDM` ke `~/Projects/SilentSDDM` + `chmod +x *.sh` |

---

## Struktur Folder

```
arch-setup/
├── install.sh               # Script utama
├── README.md
│
├── config/                  # Dotconfig — disalin ke ~/.config/
│   ├── alacritty/           # Config terminal alacritty
│   └── sway/
│       ├── config           # Sway config (terminal = alacritty)
│       └── scripts/         # Script-script sway (akan di-chmod +x)
│
├── dotfiles/
│   └── .zshrc               # Zsh config dengan powerlevel10k
│
├── powerlevel10k/           # Letakkan folder p10k di sini
│                            # Jika kosong, script akan git clone otomatis
│
└── Projects/
    └── SilentSDDM/          # SDDM theme — disalin ke ~/Projects/SilentSDDM/
```

---

## Setelah Instalasi

1. **Reboot** atau re-login
2. Jalankan wizard powerlevel10k:
   ```bash
   p10k configure
   ```
3. Setup SilentSDDM:
   ```bash
   cd ~/Projects/SilentSDDM
   ./install.sh   # sesuaikan nama script-nya
   ```

---

## Pacman Packages

`adwaita-icon-theme` `alacritty` `autotiling` `base-devel` `brightnessctl` `btop` `cliphist` `code` `curl` `dolphin` `discord` `dunst` `eza` `fastfetch` `git` `gnome-themes-extra` `gsettings-desktop-schemas` `grim` `gvfs` `jq` `libnotify` `micro` `mpv` `neovim` `noto-fonts` `noto-fonts-cjk` `noto-fonts-emoji` `obs-studio` `pipewire` `pipewire-alsa` `pipewire-pulse` `playerctl` `polkit-kde-agent` `proton-vpn-gtk-app` `python` `python-pip` `qbittorrent` `qt5-wayland` `qt6-wayland` `rofi-wayland` `sddm` `slurp` `snapper` `swappy` `swayidle` `swaylock` `ttf-font-awesome` `ttf-jetbrains-mono-nerd` `thunderbird` `unzip` `vimix-cursors` `wget` `wireplumber` `wl-clipboard` `xdg-desktop-portal-wlr` `xdg-user-dirs` `zsh` `zsh-autosuggestions` `zsh-completions` `zsh-syntax-highlighting`

## AUR Packages

`zen-browser-bin` `brave-bin` `librewolf-bin` `zotero-bin` `obsidian` `wps-office` `onlyoffice-bin` `zoom` `xclicker` `swayfx` `android-studio` `gimgv`
