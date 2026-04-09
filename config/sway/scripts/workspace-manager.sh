#!/bin/bash

#   █░█ █ █▀ █░█ ▄▀█ █░░
#   ▀▄▀ █ ▄█ █▄█ █▀█ █▄▄
# ==========================================
#  WORKSPACE MANAGER (Gap Filler + Nav)
# ==========================================

# Dependency Check
if ! command -v jq &> /dev/null; then
    notify-send "Error" "Install 'jq' first: sudo pacman -S jq"
    exit 1
fi

# --- FUNGSI 1: GAP FILLING (Merapikan Urutan) ---
gap_fill() {
    # Ambil list workspace, urutkan, dan rename jika ada lompatan angka
    existing_workspaces=$(swaymsg -t get_workspaces | jq -r '.[].num' | sort -n)
    counter=1

    for ws in $existing_workspaces; do
        if [ "$ws" -ne "$counter" ]; then
            swaymsg rename workspace number "$ws" to "$counter"
        fi
        ((counter++))
    done
}

# --- FUNGSI 2: NAVIGASI (Next/Prev) ---
navigate() {
    DIRECTION=$1
    # Pastikan dirapikan dulu sebelum pindah
    gap_fill 
    
    current_ws=$(swaymsg -t get_workspaces | jq '.[] | select(.focused==true).num')
    target_ws=$current_ws

    if [ "$DIRECTION" == "next" ]; then
        target_ws=$((current_ws + 1))
    elif [ "$DIRECTION" == "prev" ]; then
        if [ "$current_ws" -gt 1 ]; then
            target_ws=$((current_ws - 1))
        else
            target_ws=1
        fi
    fi
    
    swaymsg workspace number "$target_ws"
}

# --- FUNGSI 3: WATCHER (Daemon) ---
watch_mode() {
    # Matikan instance lama agar tidak duplikat
    pkill -f "swaymsg -t subscribe -m \[\"workspace\"\]"
    
    # Dengarkan event workspace, lalu jalankan gap_fill
    swaymsg -t subscribe -m '["workspace"]' | while read -r event; do
        gap_fill
    done
}

# --- LOGIKA EKSEKUSI UTAMA ---
case "$1" in
    "watch")
        watch_mode
        ;;
    "next")
        navigate "next"
        ;;
    "prev")
        navigate "prev"
        ;;
    *)
        gap_fill
        ;;
esac
