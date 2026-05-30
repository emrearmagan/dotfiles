#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

STORAGE="$HOME/.taskbook/storage/storage.json"

if [ ! -f "$STORAGE" ]; then
	sketchybar --set "$NAME" icon=$TASK label="-" icon.color=$LABEL_COLOR
	exit 0
fi

COUNT=$(jq '[.[] | select(._isTask == true and .isComplete == false)] | length' "$STORAGE")

if [ "$COUNT" -eq 0 ]; then
	sketchybar --set "$NAME" icon=$TASK_DONE label="0" icon.color=$GREEN
else
	sketchybar --set "$NAME" icon=$TASK label="$COUNT" icon.color=$BLUE
fi
