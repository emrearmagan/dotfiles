#!/bin/bash

source "$CONFIG_DIR/colors.sh"

FOCUSED_WORKSPACE="${FOCUSED_WORKSPACE:-$(omniwmctl query active-workspace --format json 2>/dev/null | jq -r '.result.payload.workspace.rawName // empty')}"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
	sketchybar --set "$NAME" background.drawing=on
else
	sketchybar --set "$NAME" background.drawing=off
fi
