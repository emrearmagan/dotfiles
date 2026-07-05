#!/usr/bin/env sh
# VPN indicator (Tailscale / OpenVPN / macOS-native). Click toggles Tailscale.

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

sketchybar --add event vpn_update \
	--add item vpn right \
	--set vpn \
	drawing=off updates=on update_freq=30 \
	icon=$VPN \
	icon.color=0xff${RED:2} \
	label.drawing=off \
	background.padding_left=3 \
	background.padding_right=3 \
	script="$PLUGIN_DIR/vpn.sh" \
	click_script="$PLUGIN_DIR/vpn_click.sh" \
	--subscribe vpn vpn_update
