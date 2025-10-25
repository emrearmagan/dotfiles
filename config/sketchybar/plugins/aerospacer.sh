#!/bin/bash

source "$CONFIG_DIR/colors.sh"

echo "called with $1"
echo "$FOCUSED_WORKSPACE"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
	sketchybar --set $NAME background.drawing=on
else
	sketchybar --set $NAME background.drawing=off
fi

#
# if [ "$FOCUSED" = "$SPACE_ID" ]; then
# 	sketchybar --set space.$SPACE_ID \
# 		background.drawing=on \
# 		background.color=$BLUE \
# 		label.color=$BAR_COLOR \
# 		icon.color=$BAR_COLOR
# else
# 	sketchybar --set space.$SPACE_ID \
# 		background.drawing=off \
# 		label.color=$TEXT \
# 		icon.color=$TEXT
# fi
