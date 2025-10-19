#!/usr/bin/env sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

sketchybar --add item tailscale right \
           --set tailscale \
                update_freq=10 \
                icon=$VPN_DISCONNECTED \
                icon.color=0xff${RED:2} \
                label.drawing=off \
                background.padding_left=4 \
                background.padding_right=4 \
                script="$PLUGIN_DIR/tailscale.sh"