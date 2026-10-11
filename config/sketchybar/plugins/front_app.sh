#!/usr/bin/env sh
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/plugins/icon_map_bg.sh"

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
	__icon_map "$INFO"
	ICON="$icon_result"
	font="sketchybar-app-font-bg"
	if [ "$ICON" = ":default:" ]; then
		ICON=$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$INFO")
		font="sketchybar-app-font"
	fi
	sketchybar --set "$NAME" icon="$ICON" icon.font="$font:Regular:$ICON_SIZE" label="$INFO"
fi
