#!/usr/bin/env sh

# Register the workspace events triggered from omniwm_events.sh.
sketchybar --add event omniwm_workspace_change
sketchybar --add event omniwm_windows_change

# At login OmniWM may not answer yet.
for _ in $(seq 20); do
	workspaces=$(omniwmctl query workspaces --fields raw-name --format json 2>/dev/null | jq -r '.result.payload.workspaces[].rawName')
	[ -n "$workspaces" ] && break
	sleep 0.5
done

# Only non-empty workspaces get items; focused empty one stays visible.
for sid in $workspaces; do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" omniwm_workspace_change \
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
		label.font="sketchybar-app-font-bg:Regular:$ICON_SIZE" \
		label.align=center \
		label.y_offset=-1 \
		click_script="omniwmctl workspace focus-name $sid" \
		script="$PLUGIN_DIR/omniwm_workspace.sh $sid"
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
  script="$PLUGIN_DIR/omniwm_space_windows.sh" \
  --subscribe separator omniwm_workspace_change omniwm_windows_change

pkill -f "^(bash $PLUGIN_DIR/omniwm_events\.sh$|omniwmctl watch active-workspace,windows-changed )" 2>/dev/null
"$PLUGIN_DIR/omniwm_events.sh" >/dev/null 2>&1 &
