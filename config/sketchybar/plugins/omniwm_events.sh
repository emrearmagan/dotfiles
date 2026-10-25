#!/usr/bin/env bash

# Forward OmniWM workspace and window events to sketchybar.
#
# Usage:
#   omniwm_events.sh            wait for OmniWM, then watch its events
#   omniwm_events.sh --handle   handle one event from stdin (run by omniwmctl watch)

cache="${TMPDIR:-/tmp}/sketchybar_omniwm_windows"

if [ "$1" = --handle ]; then
	event=$(cat)
	case "$OMNIWM_EVENT_CHANNEL" in
	active-workspace)
		workspace=$(jq -r '.result.payload.workspace.rawName // empty' <<<"$event")
		sketchybar --trigger omniwm_workspace_change FOCUSED_WORKSPACE="$workspace"
		;;
	windows-changed)
		# Window moves and resizes fire this too, so only update when the apps per workspace change.
		state=$(jq -r '[.result.payload.windows[] | select(.isScratchpad | not) | "\(.workspace.rawName)|\(.app.name)"] | unique | join(",")' <<<"$event")
		[ "$state" = "$(cat "$cache" 2>/dev/null)" ] && exit 0
		printf '%s' "$state" >"$cache"
		sketchybar --trigger omniwm_windows_change
		;;
	esac
	exit 0
fi

rm -f "$cache"
until omniwmctl ping >/dev/null 2>&1; do
	sleep 2
done
exec omniwmctl watch active-workspace,windows-changed --reconnect --exec "$0" --handle
