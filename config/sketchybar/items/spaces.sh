#!/usr/bin/env sh

# Register a custom event that your aerospace plugin: see aerospace.toml config
sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" aerospace_workspace_change \
		--set space."$sid" \
		background.color=0x44ffffff \
		background.corner_radius=5 \
		background.height=20 \
		background.drawing=off \
		label="$sid" \
		click_script="aerospace workspace $sid" \
		script="$PLUGIN_DIR/aerospacer.sh $sid"
done

sketchybar --add item space_separator left \
	--set space_separator icon=">" \
	icon.font="sketchybar-app-font:Regular:14.0" \
	icon.drawing=on \
	icon.padding_left=4 \
	script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_separator space_windows_change
