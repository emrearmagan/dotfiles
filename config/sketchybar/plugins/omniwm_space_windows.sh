#!/usr/bin/env sh
source "$HOME/.config/sketchybar/icons.sh" # for $ICON_SIZE
source "$CONFIG_DIR/plugins/icon_map_bg.sh"

# Update label of space.<workspace_id> with app icons from OmniWM
# - If a workspace id is provided as $1 or via WORKSPACE env, update only that one
# - If none provided, update ALL workspaces

focused() {
	omniwmctl query active-workspace --format json 2>/dev/null | jq -r '.result.payload.workspace.rawName // empty'
}

# One "workspace|app" line per window, scratchpad windows left out.
windows=$(omniwmctl query windows --fields workspace,app,is-scratchpad --format json 2>/dev/null |
	jq -r '.result.payload.windows[] | select(.isScratchpad | not) | "\(.workspace.rawName)|\(.app.name)"')

icon_for_apps() {
	apps_list="$1"
	icons=""
	normal_icons=""
	font="sketchybar-app-font-bg"
	if [ -n "$apps_list" ]; then
		while IFS= read -r app; do
			[ -n "$app" ] || continue
			__icon_map "$app"
			icons="$icons $icon_result"
			[ "$icon_result" != ":default:" ] || font="sketchybar-app-font"
			normal_icons="$normal_icons $("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app")"
		done <<EOF
$apps_list
EOF
	fi
	# A workspace label uses one font, so its whole strip must use the matching map.
	if [ "$font" = "sketchybar-app-font" ]; then
		icons="$normal_icons"
	fi
}

update_workspace() {
	ws="$1"
	apps=$(printf '%s\n' "$windows" | awk -F'|' -v ws="$ws" '$1 == ws { print $2 }' | sort -u)
	icon_for_apps "$apps"
	# Keep focused workspace visible even if empty
	focused_ws="${FOCUSED_WORKSPACE:-}"
	if [ -z "$focused_ws" ]; then
		focused_ws=$(focused)
	fi
	if [ -n "$icons" ]; then
		sketchybar --set "space.$ws" \
			drawing=on \
			label="$icons" \
			label.font="$font:Regular:$ICON_SIZE" \
			icon.drawing=on
	elif [ "$ws" = "$focused_ws" ]; then
		# Focused but empty: keep visible and show background
		sketchybar --set "space.$ws" \
			drawing=on \
			label="" \
			label.font="$font:Regular:$ICON_SIZE" \
			icon.drawing=on \
			background.drawing=on
	else
		sketchybar --set "space.$ws" \
			drawing=off \
			label="" \
			icon.drawing=on
	fi
}

# If a specific workspace is provided, update only that; otherwise update all
if [ -n "$1" ] || [ -n "$WORKSPACE" ]; then
	ws="${1:-$WORKSPACE}"
	update_workspace "$ws"
else
	FOCUSED_WORKSPACE="${FOCUSED_WORKSPACE:-$(focused)}"
	for sid in $(omniwmctl query workspaces --fields raw-name --format json 2>/dev/null | jq -r '.result.payload.workspaces[].rawName'); do
		update_workspace "$sid"
	done
fi
