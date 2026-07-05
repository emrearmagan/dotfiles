#!/usr/bin/env bash
# Show free space on / (red when the volume is nearly full).

source "$HOME/.config/sketchybar/colors.sh"

read -r used avail <<<"$(df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5, $4}')"
avail=${avail%i} # 69Gi -> 69G

color=$SAPPHIRE
[ "${used:-0}" -ge 90 ] && color=$RED

sketchybar --set disk label="$avail" icon.color="$color" label.color=$LABEL_COLOR
