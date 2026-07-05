#!/bin/bash
# Free space on the root volume.

sketchybar --add item disk right \
	--set disk \
	icon=$DISK_ICON icon.color=$SAPPHIRE icon.font="$FONT:Bold:13.0" \
	label.font="$FONT:Semibold:12.0" \
	padding_left=4 padding_right=4 \
	update_freq=300 \
	script="$PLUGIN_DIR/disk.sh"
