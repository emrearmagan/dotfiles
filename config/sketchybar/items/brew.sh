#!/bin/bash
# Outdated Homebrew package count; click for a popup listing them.
# Trigger `brew_update` from the shell (e.g. in .zshrc after brew upgrade) to refresh.

brew=(
	icon="􀐛"
	icon.font="$FONT:Bold:13.0"
	label.font="$FONT:Semibold:13.0"
	label=?
	popup.align=right
	popup.height=22
	script="$PLUGIN_DIR/brew.sh"
	update_freq=3600
)

sketchybar --add event brew_update \
	--add item brew right \
	--set brew "${brew[@]}" \
	--subscribe brew brew_update mouse.clicked mouse.exited mouse.exited.global front_app_switched

# Popup rows (outdated packages), filled by the plugin.
for i in $(seq 1 15); do
	sketchybar --add item brew.row.$i popup.brew \
		--set brew.row.$i drawing=off \
		icon=􀀁 icon.color=$PEACH icon.font="$FONT:Bold:7.0" icon.padding_left=12 \
		label.font="$FONT:Semibold:12.0" label.padding_right=16 label.color=$LABEL_COLOR \
		click_script="sketchybar --set brew popup.drawing=off"
done
