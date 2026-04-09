#!/bin/bash

#   ▄▀█ █   █▀▄▀█ █▀▀ █▄░█ █░█
#   █▀█ █   █░▀░█ ██▄ █░▀█ █▄█
# ==========================================
#  AESTHETIC AI MODEL MENU
# ==========================================

# --- CONFIGURATION ---
TARGET_SCRIPT="/usr/local/bin/chat"

# --- COLORS ---
RED='\033[38;2;247;118;142m'
GREEN='\033[38;2;158;206;106m'
BLUE='\033[38;2;122;162;247m'
CYAN='\033[38;2;125;207;255m'
YELLOW='\033[38;2;224;175;104m'
PURPLE='\033[38;2;187;154;247m'
GRAY='\033[38;2;86;95;137m'
DIM='\033[38;2;68;71;90m'
NC='\033[0m'

# --- HELPERS ---
PAD="  "
draw_line() {
    width=$(tput cols)
    printf -v line "%*s" "$width" ""
    echo -e "${DIM}${line// /─}${NC}"
}

# --- MAIN INTERFACE ---
clear
echo ""
echo -e "${PAD}${CYAN}AI MODEL SELECTOR${NC}"
draw_line
echo ""

# Group 1: DeepSeek (Reasoning)
echo -e "${PAD}${GREEN}[1]${NC} DeepSeek R1 ${DIM}(8b • Fast)${NC}"
echo -e "${PAD}${GREEN}[2]${NC} DeepSeek R1 ${DIM}(14b • Smart)${NC}"
echo ""

# Group 2: LLaMA (General & Vision)
echo -e "${PAD}${YELLOW}[3]${NC} LLaMA 3.2    ${DIM}(3b • Light)${NC}"
echo -e "${PAD}${YELLOW}[4]${NC} LLaMA Vision${DIM}(Multimodal)${NC}"
echo ""

# Group 3: Others
echo -e "${PAD}${PURPLE}[5]${NC} Dolphin Q8   ${DIM}(Uncensored)${NC}"

echo ""
draw_line
echo ""
printf "${PAD}${CYAN}Select${NC} ${DIM}>${NC} "
read -r choice

# --- LOGIC ---
case $choice in
    1) MODEL="deepseek-r1:8b" ;;
    2) MODEL="deepseek-r1:14b" ;;
    3) MODEL="llama3.2:3b" ;;
    4) MODEL="llama3.2-vision:latest" ;;
    5) MODEL="dolphin-q8:latest" ;;
    *)
        echo ""
        echo -e "${PAD}${RED}Invalid selection.${NC}"
        sleep 1
        exit 1
        ;;
esac

# --- EXECUTE ---
if [ -f "$TARGET_SCRIPT" ]; then
    # Clear screen before running
    clear 
    exec python3 "$TARGET_SCRIPT" "$MODEL"
else
    echo ""
    echo -e "${PAD}${RED}ERROR: Script not found ($TARGET_SCRIPT)${NC}"
    read -p "${PAD}Press Enter..."
fi
