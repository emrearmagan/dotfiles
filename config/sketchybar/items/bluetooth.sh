#!/bin/bash
# Battery of the connected Bluetooth device (AirPods / Magic peripherals).
# Hidden when nothing with a battery is connected.

sketchybar --add item bluetooth right \
	--set bluetooth \
	drawing=off \
	update_freq=120 \
	icon=$BLUETOOTH icon.color=$BLUE icon.font="$FONT:Bold:13.0" \
	label.font="$FONT:Semibold:12.0" \
	padding_left=4 padding_right=4 \
	script="$PLUGIN_DIR/bluetooth.sh"
