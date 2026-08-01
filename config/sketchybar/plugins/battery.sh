#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

BATTERY_INFO=$(pmset -g batt)
PERCENTAGE=$(printf '%s\n' "$BATTERY_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(printf '%s\n' "$BATTERY_INFO" | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

DRAWING=on
COLOR=$WHITE
case ${PERCENTAGE} in
9[0-9] | 100)
	ICON=$BATTERY_100
	;;
[6-8][0-9])
	ICON=$BATTERY_75
	;;
[3-5][0-9])
	ICON=$BATTERY_50
	;;
[1-2][0-9])
	ICON=$BATTERY_25
	COLOR=$ORANGE
	;;
*)
	ICON=$BATTERY_0
	COLOR=$RED
	;;
esac

if [[ $CHARGING != "" ]]; then
	ICON=$BATTERY_CHARGING
fi

if (( PERCENTAGE < 20 )); then
	LABEL_DRAWING=on
	LABEL="${PERCENTAGE}%"
else
	LABEL_DRAWING=off
	LABEL=""
fi

sketchybar --set "$NAME" drawing=$DRAWING icon="$ICON" icon.color=$COLOR label.drawing=$LABEL_DRAWING label="$LABEL"
