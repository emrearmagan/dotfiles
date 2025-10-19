#!/usr/bin/env sh

sketchybar --add item window_title left \
	--set window_title script="$PLUGIN_DIR/front_app.sh" \
	icon.font="sketchybar-app-font:Regular:14.0" \
	icon.drawing=on \
	label.color=$TEXT \
	--subscribe window_title front_app_switched
