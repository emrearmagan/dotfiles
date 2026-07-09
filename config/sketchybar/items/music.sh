#!/bin/bash
# Apple Music: music icon + "title — artist" on one line. Hidden unless playing;
# click to play/pause.

sketchybar --add item music right \
	--set music drawing=off updates=on update_freq=5 \
	icon="$MUSIC_PLAY" icon.color=$WHITE icon.font="$FONT:Regular:$ICON_SIZE" \
	label.font="$FONT:Semibold:12.0" label.align=left \
	scroll_texts=on label.scroll_duration=200 label.max_chars=25 \
	padding_left=6 padding_right=6 \
	script="$PLUGIN_DIR/music.sh" \
	click_script="osascript -e 'tell application \"Music\" to playpause'; sketchybar --update" \
	--subscribe music system_woke
