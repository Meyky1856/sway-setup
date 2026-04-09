#!/bin/bash

#   █▀ ▀█▀ ▄▀█ █▀█ ▀█▀
#   ▄█ ░█░ █▀█ █▀▄ ░█░
# ==========================================
#  WAYBAR STARTUP (RESTORE POS)
# ==========================================

CONFIG_DIR="$HOME/.config/waybar"
STATE_FILE="$CONFIG_DIR/current_position"
POS="top"

if [ -f "$STATE_FILE" ]; then
    POS=$(cat "$STATE_FILE")
fi

pkill -x waybar
waybar -c "$CONFIG_DIR/config-$POS.jsonc" -s "$CONFIG_DIR/style.css" &
