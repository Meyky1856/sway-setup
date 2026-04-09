#!/bin/bash

#   █▄▄ ▄▀█ █▀█
#   █▄█ █▀█ █▀▄
# ==========================================
#  WAYBAR POSITION SWITCHER
# ==========================================

CONFIG_DIR="$HOME/.config/waybar"
STATE_FILE="$CONFIG_DIR/current_position"
POSITIONS=("top" "right" "bottom" "left")

# Init state
if [ ! -f "$STATE_FILE" ]; then echo "top" > "$STATE_FILE"; fi
CURRENT_POS=$(cat "$STATE_FILE")

# Determine Next Position
NEXT_POS=""
if [ -z "$1" ]; then
    for i in "${!POSITIONS[@]}"; do
       if [[ "${POSITIONS[$i]}" == "${CURRENT_POS}" ]]; then
           NEXT_INDEX=$(( (i + 1) % ${#POSITIONS[@]} ))
           NEXT_POS="${POSITIONS[$NEXT_INDEX]}"
           break
       fi
    done
else
    NEXT_POS="$1"
fi
[ -z "$NEXT_POS" ] && NEXT_POS="top"

# Apply
echo "Switching to: $NEXT_POS"
pkill -x waybar 
sleep 0.2
waybar -c "$CONFIG_DIR/config-$NEXT_POS.jsonc" -s "$CONFIG_DIR/style.css" > /dev/null 2>&1 & disown

# Save
echo "$NEXT_POS" > "$STATE_FILE"
