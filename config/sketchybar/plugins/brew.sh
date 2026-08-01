#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

case "$SENDER" in
mouse.clicked)
	sketchybar --set brew popup.drawing=toggle
	exit 0
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set brew popup.drawing=off
	exit 0
	;;
esac

# Filter out any "JSON API ..." lines that appear during Homebrew metadata sync.
BREW=/opt/homebrew/bin/brew
[ -x "$BREW" ] || BREW=$(command -v brew)
LIST=$("$BREW" outdated --quiet 2>/dev/null | grep -v 'JSON API')
COUNT=$(printf '%s' "$LIST" | grep -c .)

case "$COUNT" in
0) COLOR=$GREEN LABEL="" ;;
[12]) COLOR=$WHITE LABEL="$COUNT" ;;
[34]) COLOR=$YELLOW LABEL="$COUNT" ;;
[5-7]) COLOR=$PEACH LABEL="$COUNT" ;;
*) COLOR=$RED LABEL="$COUNT" ;;
esac
sketchybar --set brew label="$LABEL" icon.color=$COLOR

# ---- popup: outdated package list ----
idx=1
if [ "$COUNT" -eq 0 ]; then
	sketchybar --set brew.row.1 drawing=on icon.drawing=off label="Everything up to date" label.color=$GREEN
	idx=2
else
	while IFS= read -r pkg; do
		[ -n "$pkg" ] || continue
		[ "$idx" -gt 15 ] && break
		if [ "$idx" -eq 15 ] && [ "$COUNT" -gt 15 ]; then
			sketchybar --set brew.row.15 drawing=on icon.drawing=off label="…and $((COUNT - 14)) more"
			idx=16
			break
		fi
		sketchybar --set brew.row.$idx drawing=on icon.drawing=on label="$pkg"
		idx=$((idx + 1))
	done <<EOF
$LIST
EOF
fi
while [ "$idx" -le 15 ]; do
	sketchybar --set brew.row.$idx drawing=off
	idx=$((idx + 1))
done
