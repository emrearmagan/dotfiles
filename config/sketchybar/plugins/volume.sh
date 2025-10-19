#!/usr/bin/env sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

source "$HOME/.config/sketchybar/icons.sh" # Loads all defined colors

if [ "$SENDER" = "volume_change" ]; then
	VOLUME=$INFO

	case $VOLUME in
	[6-9][0-9] | 100) ICON="􀊩" ;;   # High volume
	[3-5][0-9]) ICON="􀊥" ;;         # Medium volume
	[1-9] | [1-2][0-9]) ICON="􀊡" ;; # Low volume
	*) ICON="􀊣" ;;                  # Muted
	esac

	sketchybar --set $NAME icon="$ICON" label="$VOLUME%"
fi
