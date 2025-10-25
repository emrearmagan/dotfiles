#!/usr/bin/env sh
set -e

# Update label of space.<workspace_id> with app icons from Aerospace
# Accepts workspace id as $1 or WORKSPACE env, otherwise uses focused workspace.

workspace="$1"
[ -z "$workspace" ] && workspace="${WORKSPACE:-$(aerospace list-workspaces --focused)}"

apps=$(aerospace list-windows --workspace "$workspace" --json 2>/dev/null | jq -r '.[].["app-name"]')

icon_strip=""
if [ -n "$apps" ]; then
	while IFS= read -r app; do
		[ -n "$app" ] && icon_strip="$icon_strip $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
	done <<EOF
$apps
EOF
fi

sketchybar --set "space.$workspace" icon="$icon_strip" icon.font="sketchybar-app-font:Regular:14.0" icon.padding_right=4
