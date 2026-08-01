#!/bin/bash
# Active outgoing SSH sessions: shows the host (or "host +N"); click for the list.

sketchybar --add item ssh right \
	--set ssh \
	drawing=off updates=on update_freq=30 \
	icon=$SSH_ICON icon.color=$TEAL icon.font="JetBrainsMono Nerd Font:Bold:$FONT_SIZE" \
	label.drawing=off \
	padding_left=3 padding_right=3 \
	popup.align=right popup.height=22 \
	script="$PLUGIN_DIR/ssh.sh" \
	--subscribe ssh mouse.clicked mouse.exited mouse.exited.global front_app_switched

# Popup rows (one per host), filled by the plugin.
for i in $(seq 1 8); do
	sketchybar --add item ssh.row.$i popup.ssh \
		--set ssh.row.$i drawing=off \
		icon=􀀁 icon.color=$TEAL icon.font="$FONT:Bold:7.0" icon.padding_left=12 \
		label.font="$FONT:Semibold:12.0" label.padding_right=16 label.color=$LABEL_COLOR \
		click_script="sketchybar --set ssh popup.drawing=off"
done
