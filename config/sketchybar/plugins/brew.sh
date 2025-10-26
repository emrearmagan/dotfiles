#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

# COUNT=$(zsh -l -c "/opt/homebrew/bin/brew outdated --quiet" | wc -l | tr -d ' ')
COUNT=$(zsh -l -c "brew outdated --quiet" | wc -l | tr -d ' ')
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

# Handle mouse click to trigger brew_update event
if [ "$SENDER" = "mouse.clicked" ]; then
	sketchybar --trigger brew_update
	exit 0
fi
