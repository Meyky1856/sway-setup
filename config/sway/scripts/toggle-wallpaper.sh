#!/bin/bash

#   █░█ █ █▀▄▀█ █▀▀
#   █▄█ █ █░▀░█ █▄█
# ==========================================
#  WALLPAPER TOGGLER
# ==========================================

# --- CONFIG ---
WALL_A="$HOME/Pictures/Wallpapers/Hinata.png"
WALL_B="$HOME/Pictures/Wallpapers/muichiro-tokito.png"
STATE_FILE="$HOME/.config/sway/state_wallpaper"

# --- FUNCTIONS ---
set_wall_a() {
    swaymsg output "*" bg "$WALL_A" fill
    notify-send -t 2000 "Wallpaper" "Mode Hinata Active"
    echo "A" > "$STATE_FILE"
}

set_wall_b() {
    swaymsg output "*" bg "$WALL_B" fill
    notify-send -t 2000 "Wallpaper" "Mode Sword Active"
    echo "B" > "$STATE_FILE"
}

# --- LOGIC ---
if [ "$1" == "restore" ]; then
    if [ -f "$STATE_FILE" ]; then
        CURRENT=$(cat "$STATE_FILE")
        [ "$CURRENT" == "B" ] && swaymsg output "*" bg "$WALL_B" fill || swaymsg output "*" bg "$WALL_A" fill
    else
        swaymsg output "*" bg "$WALL_A" fill
    fi
    exit 0
fi

if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE")
    [ "$CURRENT" == "A" ] && set_wall_b || set_wall_a
else
    set_wall_b
fi
