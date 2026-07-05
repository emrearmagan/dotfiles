#!/bin/bash
# Apple Music now-playing (icon + "title — artist") via AppleScript.
# Hidden unless a track is playing.

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

[ "$(osascript -e 'application "Music" is running' 2>/dev/null)" = "true" ] || {
	sketchybar --set music drawing=off
	exit 0
}

info=$(osascript -e 'tell application "Music"
  if player state is stopped then return "stopped||"
  return (player state as text) & "|" & (name of current track) & "|" & (artist of current track)
end tell' 2>/dev/null)
state=${info%%|*}
rest=${info#*|}
title=${rest%%|*}
artist=${rest#*|}

if [ "$state" != "playing" ] || [ -z "$title" ]; then
	sketchybar --set music drawing=off
	exit 0
fi

sketchybar --set music drawing=on label="$title - $artist"
