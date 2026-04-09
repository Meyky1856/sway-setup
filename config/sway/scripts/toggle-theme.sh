#!/bin/bash

#   ▀█▀ █░█ █▀▀ █▀▄▀█ █▀▀
#   ░█░ █▀█ ██▄ █░▀░█ ██▄
# ==========================================
#  SYSTEM THEME & WALLPAPER TOGGLER
# ==========================================

# --- CONFIGURATION ---
STATE_FILE="$HOME/.config/sway/state_theme"
GTK_CONFIG="$HOME/.config/gtk-3.0/settings.ini"

# Wallpapers
WALL_LIGHT="$HOME/Pictures/Wallpapers/Hinata.png"
WALL_DARK="$HOME/Pictures/Wallpapers/muichiro-tokito.png"

# GTK Themes (Ensure these are installed or use 'Adwaita' as fallback)
GTK_THEME_LIGHT="Adwaita"
GTK_THEME_DARK="Adwaita-dark"

# --- HELPER FUNCTIONS ---

# Function: Force update GTK3 settings.ini for legacy app support
update_gtk_file() {
    local theme="$1"
    local dark_int="$2" # 1 for dark, 0 for light

    if [ -f "$GTK_CONFIG" ]; then
        # Update theme name
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$GTK_CONFIG"
        # Update dark preference
        sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark_int/" "$GTK_CONFIG"
    fi
}

# Function: Activate Light Mode
set_light() {
    # 1. Set Wallpaper
    swaymsg output "*" bg "$WALL_LIGHT" fill

    # 2. Disable Night Light (Blue light filter)
    pkill wlsunset

    # 3. Apply GTK Settings (Modern apps & Browsers)
    # 'default' tells browsers to use Light Mode
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_LIGHT"
    gsettings set org.gnome.desktop.interface color-scheme 'default'

    # 4. Update Config File (Legacy support)
    update_gtk_file "$GTK_THEME_LIGHT" 0

    # 5. Save State & Notify
    echo "light" > "$STATE_FILE"
    notify-send -t 2000 -i weather-clear "System Theme" "Light Mode Active"
}

# Function: Activate Dark Mode
set_dark() {
    # 1. Set Wallpaper
    swaymsg output "*" bg "$WALL_DARK" fill

    # 2. Enable Night Light (Eye comfort)
    if ! pgrep -x "wlsunset" > /dev/null; then
        wlsunset -t 4000 &
    fi

    # 3. Apply GTK Settings (Modern apps & Browsers)
    # 'prefer-dark' tells browsers to use Dark Mode
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_DARK"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    # 4. Update Config File (Legacy support)
    update_gtk_file "$GTK_THEME_DARK" 1

    # 5. Save State & Notify
    echo "dark" > "$STATE_FILE"
    notify-send -t 2000 -i weather-clear-night "System Theme" "Dark Mode Active"
}

# --- EXECUTION LOGIC ---

# Case 1: Restore State (Run on Startup)
if [ "$1" == "restore" ]; then
    if [ -f "$STATE_FILE" ]; then
        CURRENT=$(cat "$STATE_FILE")
        [ "$CURRENT" == "dark" ] && set_dark || set_light
    else
        # Default to Light if no state found
        set_light
    fi
    exit 0
fi

# Case 2: Toggle State (Run on Keypress)
if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE")
    if [ "$CURRENT" == "dark" ]; then
        set_light
    else
        set_dark
    fi
else
    # Default to Dark on first run
    set_dark
fi
