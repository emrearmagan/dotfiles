#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

COUNT=$(brew outdated | wc -l | tr -d ' ')
COLOR=$RED

case "$COUNT" in
0)
	COLOR=$GREEN
	COUNT=􀆅
	;;
[12])
	COLOR=$WHITE
	;;
[34])
	COLOR=$YELLOW
	;;
[5-7])
	COLOR=$PEACH
	;;
*)
	COLOR=$RED
	;;
esac

sketchybar --set "$NAME" label="$COUNT" icon.color=$COLOR
