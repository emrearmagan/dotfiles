#!/usr/bin/env sh

meeting=(
	icon="$CALENDAR"
	icon.font="$FONT:Black:12.0"
	label="No meetings"
	label.max_chars=50
	padding_left=8
	padding_right=8
	update_freq=30
	script="$PLUGIN_DIR/meeting.sh"
)

sketchybar --add item meeting right \
	--set meeting "${meeting[@]}" \
	--subscribe meeting system_woke
