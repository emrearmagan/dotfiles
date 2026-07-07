#!/bin/bash
# Agent chips (left of front_app): one chip per running AI agent, max 3, then a
# "+N more" chip. chip.1 is the controller + popup host; clicking any chip opens
# a popup listing every agent. Fed by ~/.config/scripts/agent-status-hook.

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

# chip.1: controller (updates=on) + popup host, extra left pad from front_app.
sketchybar --add item agent.chip.1 left \
	--set agent.chip.1 "${chip_common[@]}" updates=on update_freq=30 \
	padding_left=18 popup.align=left popup.height=26 \
	--subscribe agent.chip.1 agent_status_change system_woke "${subs[@]}"
# Popup rows (full list, with provider logos).
for i in $(seq 1 8); do
	sketchybar --add item agent.row.$i popup.agent.chip.1 \
		--set agent.row.$i drawing=off icon.padding_left=10 \
		label.font="$FONT:Semibold:$FONT_SIZE" label.padding_right=12 \
		click_script="sketchybar --set agent.chip.1 popup.drawing=off"
done
