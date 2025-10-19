#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

source "$CONFIG_DIR/colors.sh" # Loads all defined colors

# Assuming ACCENT_COLOR should be BLUE based on colors.sh
ACCENT_COLOR="$BLUE"
BAR_COLOR="$BAR_COLOR" # Assuming BAR_COLOR is defined in colors.sh

# Get the space ID from the script argument
SPACE_ID="$1"

# Check if jq is available for JSON parsing
if command -v jq >/dev/null 2>&1; then
  # Get application names for the current space using aerospace and jq
  APP_NAMES=$(aerospace list-windows --workspace "$SPACE_ID" --json | jq -r '.[].app')

  # Build the icon string
  APP_ICONS=""
  for app_name in $APP_NAMES; do
    ICON=$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app_name")
    APP_ICONS="${APP_ICONS}${ICON}"
  done
else
  # Fallback if jq is not installed (less robust parsing)
  # This will try to extract app names, but might be less reliable
  APP_NAMES=$(aerospace list-windows --workspace "$SPACE_ID" | grep -E 'app:' | awk -F': ' '{print $2}')
  APP_ICONS=""
  for app_name in $APP_NAMES; do
    ICON=$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app_name")
    APP_ICONS="${APP_ICONS}${ICON}"
  done
  if [ -z "$APP_ICONS" ]; then
    # If no app icons, use the space ID as a fallback label
    APP_ICONS="$SPACE_ID"
  fi
fi

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                         background.color="$ACCENT_COLOR" \
                         label.color="$BAR_COLOR" \
                         icon.color="$BAR_COLOR" \
                         label="$APP_ICONS" # Set the label to app icons
else
  sketchybar --set "$NAME" background.drawing=off \
                         label.color="$ACCENT_COLOR" \
                         icon.color="$ACCENT_COLOR" \
                         label="$APP_ICONS" # Set the label to app icons
fi