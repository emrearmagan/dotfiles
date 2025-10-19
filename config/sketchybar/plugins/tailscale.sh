#!/bin/bash

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

if tailscale status &>/dev/null; then
    sketchybar --set $NAME icon=$VPN_CONNECTED icon.color=0xff${GREEN:2} label.drawing=off
else
    sketchybar --set $NAME icon=$VPN_DISCONNECTED icon.color=0xff${RED:2} label.drawing=off
fi