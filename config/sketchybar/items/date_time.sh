calendar=(
	# icon=cal
	icon.font="$FONT:Black:12.0"
	icon.padding_right=0
	label.width=45
	label.align=right
	padding_left=15
	update_freq=30
	script="$PLUGIN_DIR/date_time.sh"
)

sketchybar --add item date_time right \
	--set date_time "${calendar[@]}" \
	--subscribe date_time system_woke
