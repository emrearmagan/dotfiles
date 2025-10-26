#!/usr/bin/env sh

# Register a custom event that your aerospace plugin trigger: see aerospace.toml config
sketchybar --add event aerospace_workspace_change

# Only non-empty workspaces get items; focused empty one stays visible via space_windows.sh
for sid in $(aerospace list-workspaces --all); do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" aerospace_workspace_change \
		--set space."$sid" \
		background.color=0x44ffffff \
		background.corner_radius=5 \
		background.drawing=off \
		background.padding_left=20 \
		background.height=25 \
		background.y_offset=0 \
		padding_left=5 \
		padding_right=5 \
		padding_top=5 \
		padding_bottom=5 \
		icon="$sid" \
		icon.font="$FONT:Bold:14.0" \
		label.padding_right=6 \
		label.font="sketchybar-app-font:Regular:14.0" \
		label.align=center \
		label.y_offset=-1 \
		click_script="aerospace workspace $sid" \
		script="$PLUGIN_DIR/aerospacer.sh $sid"
done

# simply create a separatir item to subscribe to the event and update the space windows
sketchybar --add item space_separator left \
	--set space_separator icon=">" \
	icon.padding_left=4 \
	script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_separator space_windows_change
