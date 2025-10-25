#!/usr/bin/env sh

# Update label of space.<workspace_id> with app icons from Aerospace
# - If a workspace id is provided as $1 or via WORKSPACE env, update only that one
# - If none provided, update ALL workspaces

icon_for_apps() {
	apps_list="$1"
	icon_strip=""
	if [ -n "$apps_list" ]; then
		while IFS= read -r app; do
			[ -n "$app" ] && icon_strip="$icon_strip $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
		done <<EOF
$apps_list
EOF
	fi
	printf "%s" "$icon_strip"
}

update_workspace() {
	ws="$1"
	apps=$(aerospace list-windows --workspace "$ws" --json 2>/dev/null | jq -r '.[].["app-name"]' | sort -u)
	icons=$(icon_for_apps "$apps")
	if [ -n "$icons" ]; then
		sketchybar --set "space.$ws" \
			label="$ws $icons" \
			label.font="sketchybar-app-font:Regular:14.0" \
			icon.drawing=off
	else
		sketchybar --set "space.$ws" \
			label="$ws —" \
			label.font="sketchybar-app-font:Regular:14.0" \
			icon.drawing=off
	fi
}

# If a specific workspace is provided, update only that; otherwise update all
if [ -n "$1" ] || [ -n "$WORKSPACE" ]; then
	ws="${1:-$WORKSPACE}"
	update_workspace "$ws"
else
	for sid in $(aerospace list-workspaces --all); do
		update_workspace "$sid"
	done
fi
