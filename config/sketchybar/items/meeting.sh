#!/usr/bin/env sh
# Next meeting on the bar; click for a popup of upcoming events.

meeting=(
	icon="$CALENDAR"
	icon.font="$FONT:Black:12.0"
	label=""
	label.max_chars=50
	padding_left=4
	padding_right=4
	update_freq=30
	popup.align=right
	popup.height=24
	script="$PLUGIN_DIR/meeting.sh"
)

sketchybar --add item meeting right \
	--set meeting "${meeting[@]}" \
	--subscribe meeting system_woke mouse.clicked mouse.exited mouse.exited.global front_app_switched

# Popup rows (upcoming events), filled by the plugin.
for i in 1 2 3 4 5 6; do
	sketchybar --add item meeting.row.$i popup.meeting \
		--set meeting.row.$i drawing=off \
		icon=􀀁 icon.color=$SAPPHIRE icon.font="$FONT:Bold:7.0" icon.padding_left=12 \
		label.font="$FONT:Semibold:12.0" label.padding_right=16 label.color=$LABEL_COLOR \
		click_script="sketchybar --set meeting popup.drawing=off"
done
