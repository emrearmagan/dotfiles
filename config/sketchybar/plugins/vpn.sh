#!/bin/bash
# VPN indicator: visible when any VPN is up. Detects Tailscale, OpenVPN
# / Tunnelblick / OpenVPN Connect, and macOS-native connections.

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

up=false
tailscale status &>/dev/null && up=true
ifconfig 2>/dev/null | awk '/^[a-z0-9]+:/{u=($0 ~ /^utun/)} u && /inet .*-->/{f=1} END{exit !f}' && up=true
scutil --nc list 2>/dev/null | grep -qE '\(Connected\)' && up=true

if $up; then
	sketchybar --set "$NAME" drawing=on icon.color=0xff${GREEN:2} label.drawing=off
else
	sketchybar --set "$NAME" drawing=off label.drawing=off
fi
