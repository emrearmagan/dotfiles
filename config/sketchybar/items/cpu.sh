#!/bin/bash
# Minimal system widget: chip icon + "cpu% · mem%". Click for a details popup
# (CPU / RAM / SSD / Net / Top process).

sketchybar --add item cpu right \
	--set cpu \
	icon=$CPU_ICON icon.color=$GREEN icon.font="$FONT:Bold:13.0" \
	label.font="$FONT:Semibold:12.0" \
	padding_left=6 padding_right=6 \
	update_freq=5 \
	popup.align=right popup.height=22 \
	script="$PLUGIN_DIR/cpu.sh" \
	--subscribe cpu mouse.clicked mouse.exited mouse.exited.global front_app_switched

# Popup rows (monospace so the columns line up).
for i in 1 2 3 4 5; do
	sketchybar --add item cpu.row.$i popup.cpu \
		--set cpu.row.$i icon.drawing=off \
		label.font="JetBrainsMono Nerd Font:Medium:12.0" label.align=left \
		label.padding_left=14 label.padding_right=16 label.color=$LABEL_COLOR
done
