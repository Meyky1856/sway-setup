#!/bin/bash

# ==========================================================
# MONITOR / PROJECTOR MANAGEMENT SCRIPT
# ==========================================================

# --- CONFIGURATION ---
LAPTOP="eDP-1"        # Sesuaikan dengan nama layar laptop (cek dengan swaymsg -t get_outputs)
EXTERNAL="HDMI-A-1"   # Layar External/Proyektor
ROFI_CMD="rofi -dmenu -i -p 'Display Mode' -theme-str 'window {width: 20%;}'"

# Notification ID (Arbitrary unique number to replace previous notification)
NOTIF_ID="1005"
TIMEOUT="3000"

# --- NOTIFICATION FUNCTION (OSD STYLE) ---
send_notif() {
    notify-send -r "$NOTIF_ID" -t "$TIMEOUT" \
    -h string:x-canonical-private-synchronous:display \
    -u low -i video-display "$1"
}

# --- MODES LOGIC ---
apply_mode() {
    case "$1" in
        "💻 Laptop Only")
            swaymsg output "$EXTERNAL" disable
            swaymsg output "$LAPTOP" enable
            send_notif "Mode: Laptop Only"
            ;;
        "📽️ Projector Only")
            swaymsg output "$LAPTOP" disable
            swaymsg output "$EXTERNAL" enable resolution 1920x1080
            send_notif "Mode: Projector Only (1080p)"
            ;;
        "🖥️ Extend (Dual)")
            swaymsg output "$LAPTOP" enable
            swaymsg output "$EXTERNAL" enable pos 1920 0 resolution 1920x1080
            send_notif "Mode: Extended Display"
            ;;
        "🪞 Mirror (Clone)")
            # Mirroring in Sway = Putting both screens at pos 0 0 with same res
            swaymsg output "$LAPTOP" enable resolution 1920x1080 pos 0 0
            swaymsg output "$EXTERNAL" enable resolution 1920x1080 pos 0 0
            send_notif "Mode: Mirror / Clone"
            ;;
        *)
            # Do nothing if cancelled
            exit 0
            ;;
    esac
}

# --- MENU SELECTION ---
# Jika script dijalankan tanpa argumen, tampilkan menu
options="💻 Laptop Only\n📽️ Projector Only\n🖥️ Extend (Dual)\n🪞 Mirror (Clone)"
choice=$(echo -e "$options" | eval "$ROFI_CMD")

apply_mode "$choice"
