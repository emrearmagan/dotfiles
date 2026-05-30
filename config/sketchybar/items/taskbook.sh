#!/bin/bash

taskbook=(
	update_freq=60
	icon.font="$FONT:Bold:15.0"
	icon=$TASK
	icon.color=$BLUE
	label=$LOADING
	script="$PLUGIN_DIR/taskbook.sh"
	click_script="open -a Ghostty -n --args -e tb"
)

sketchybar --add item taskbook right \
	--set taskbook "${taskbook[@]}" \
	--subscribe taskbook system_woke
