#!/usr/bin/env sh

# Register a custom event that your aerospace plugin trigger: see aerospace.toml config
sketchybar --add event aerospace_workspace_change

# Only non-empty workspaces get items; focused empty one stays visible via space_windows.sh
for sid in $(aerospace list-workspaces --all); do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" aerospace_workspace_change \
		--set space."$sid" \
		background.color=$BACKGROUND_1 \
		background.border_color=$BACKGROUND_2 \
		background.border_width=2 \
		background.drawing=off \
		background.padding_right=4 \
		background.padding_top=4 \
		background.padding_bottom=4 \
		padding_left=5 \
		padding_right=5 \
		padding_top=5 \
		padding_bottom=5 \
		icon="$sid" \
		icon.font="$FONT:Bold:14.0" \
		icon.padding_left=8 \
		label.padding_right=15 \
		label.font="sketchybar-app-font:Regular:14.0" \
		label.align=center \
		label.y_offset=-1 \
		click_script="aerospace workspace $sid" \
		script="$PLUGIN_DIR/aerospacer.sh $sid"
done

separator=(
  icon=􀆊
  icon.font="$FONT:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  icon.color=$WHITE
)

sketchybar --add item separator left \
  --set separator "${separator[@]}" \
  script="$PLUGIN_DIR/space_windows.sh" \
  --subscribe separator space_windows_change aerospace_workspace_change
