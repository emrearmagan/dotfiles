#!/bin/bash
# Unread INBOX count from the matcha daemon; click to open matcha.

mail=(
	icon=$MAIL
	icon.font="$FONT:Bold:13.0"
	icon.color=$LABEL_COLOR
	label=$LOADING
	script="$PLUGIN_DIR/mail.sh"
	click_script="$HOME/.config/scripts/popup mail"
	update_freq=60
)

sketchybar --add item mail right \
	--set mail "${mail[@]}" \
	--subscribe mail system_woke
