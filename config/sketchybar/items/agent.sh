#!/bin/bash
sketchybar --add event agent_status_change

chip_common=(
	icon.font="$FONT:Semibold:$ICON_SIZE"
	label.font="$FONT:Semibold:$FONT_SIZE"
	drawing=off
	padding_left=4
	padding_right=4
	script="$PLUGIN_DIR/agent.sh"
)
subs=(mouse.clicked mouse.exited mouse.exited.global front_app_switched)

sketchybar --add item agent.chip.1 left \
	--set agent.chip.1 "${chip_common[@]}" updates=on update_freq=30 \
	padding_left=18 popup.align=left popup.height=26 \
	--subscribe agent.chip.1 agent_status_change system_woke "${subs[@]}"

sketchybar --add item agent.chip.2 left \
	--set agent.chip.2 "${chip_common[@]}" updates=off \
	--subscribe agent.chip.2 "${subs[@]}"

for chip in 1 2; do
	for i in $(seq 1 8); do
		sketchybar --add item agent.row.$chip.$i popup.agent.chip.$chip \
			--set agent.row.$chip.$i drawing=off icon.padding_left=10 \
			label.font="$FONT:Semibold:$FONT_SIZE" label.padding_right=12 \
			click_script="sketchybar --set agent.chip.$chip popup.drawing=off"
	done
done
