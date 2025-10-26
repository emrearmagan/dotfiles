#!/usr/bin/env sh

sketchybar --add item clock right \
	--set clock \
	update_freq=1 \
	icon="$CLOCK" \
	icon.color=$PEACH \
	icon.font="$FONT:Bold:14.0" \
	icon.padding_left=6 \
	icon.padding_right=6 \
	label.color=$TEXT \
	label.font="$FONT:Semibold:13.0" \
	label.padding_left=4 \
	label.padding_right=4 \
	background.color=$BACKGROUND_1 \
	background.height=26 \
	background.corner_radius=8 \
	script="$PLUGIN_DIR/clock.sh"
