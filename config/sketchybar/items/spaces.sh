#!/usr/bin/env sh

sketchybar --add event aerospace_workspace_change
RED=0xffed8796 # Assuming RED is still desired for highlight_color

for sid in $(aerospace list-workspaces --all); do
  sketchybar --add item "space.$sid" left \
             --set "space.$sid" space="$sid" \
                              # Removed icon="$ICON" as app icons will be in label
                              icon.font="sketchybar-app-font:Regular:12.0" \
                              icon.padding_left=10 \
                              icon.padding_right=10 \
                              label.padding_right=10 \
                              icon.highlight_color="$RED" \
                              background.color=0x44ffffff \
                              background.corner_radius=5 \
                              background.height=20 \
                              background.drawing=off \
                              label.font="sketchybar-app-font:Regular:12.0" \
                              label.background.height=20 \
                              label.background.drawing=on \
                              label.background.color=0xff494d64 \
                              label.background.corner_radius=9 \
                              label.drawing=on \
                              click_script="aerospace workspace $sid" \
                              script="$PLUGIN_DIR/space.sh"
done

sketchybar --add item space_separator left \
           --set space_separator icon="􀆊" \
                                 icon.color="$BLUE" \
                                 icon.padding_left=4 \
                                 label.drawing=off \
                                 background.drawing=off \
                                 script="$PLUGIN_DIR/space_windows.sh" \
           --subscribe space_separator space_windows_change