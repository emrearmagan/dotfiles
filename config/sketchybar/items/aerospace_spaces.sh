#!/usr/bin/env sh

# Register the workspace event triggered from aerospace.toml.
sketchybar --add event aerospace_workspace_change

# Only non-empty workspaces get items; focused empty one stays visible.
for sid in $(aerospace list-workspaces --all); do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" aerospace_workspace_change \
		--set space."$sid" \
		background.color=$BACKGROUND_1 \
		background.border_color=$BACKGROUND_2 \
		background.border_width=2 \
		background.drawing=off \
		background.padding_right=3 \
		background.padding_top=4 \
		background.padding_bottom=4 \
		padding_left=5 \
		padding_right=5 \
		padding_top=5 \
		padding_bottom=5 \
		icon="$sid" \
		icon.font="$FONT:Semibold:$FONT_SIZE" \
		icon.padding_left=6 \
		label.padding_right=10 \
		label.font="sketchybar-app-font:Regular:$ICON_SIZE" \
		label.align=center \
		label.y_offset=-1 \
		click_script="aerospace workspace $sid" \
		script="$PLUGIN_DIR/aerospace_workspace.sh $sid"
done

separator=(
  icon=􀆊
  icon.font="$FONT:Semibold:$ICON_SIZE"
  padding_left=8
  padding_right=8
  label.drawing=off
  icon.color=$WHITE
)

sketchybar --add item separator left \
  --set separator "${separator[@]}" \
  script="$PLUGIN_DIR/aerospace_space_windows.sh" \
  --subscribe separator space_windows_change aerospace_workspace_change
