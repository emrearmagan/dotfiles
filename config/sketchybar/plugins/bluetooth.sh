#!/usr/bin/env bash
# Bluetooth widget. Magic Mouse/Keyboard/Trackpad expose a battery % via ioreg;
# AirPods (esp. Max) expose no battery to built-in tools, so for a connected
# audio device we just show a headphones icon (no %). Hidden when nothing's on.

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Peripheral battery (fast path).
batt=$(ioreg -r -l -n AppleDeviceManagementHIDEventService 2>/dev/null |
	grep -o '"BatteryPercent" = [0-9]*' | grep -o '[0-9]*' | sort -n | head -1)
if [ -n "$batt" ]; then
	color=$GREEN
	[ "$batt" -le 30 ] && color=$PEACH
	[ "$batt" -le 15 ] && color=$RED
	sketchybar --set bluetooth drawing=on icon=$BLUETOOTH label="${batt}%" \
		icon.color="$color" label.color=$LABEL_COLOR
	exit 0
fi

# Otherwise: any connected device (e.g. AirPods) -> icon only, no %.
connected=$(system_profiler SPBluetoothDataType 2>/dev/null |
	awk '/^ *Connected:/{c=1;next} /^ *Not Connected:/{c=0} c && /:[[:space:]]*$/{f=1} END{print (f?1:0)}')
if [ "$connected" = "1" ]; then
	sketchybar --set bluetooth drawing=on icon=$BLUETOOTH label="" icon.color=$BLUE
else
	sketchybar --set bluetooth drawing=off
fi
