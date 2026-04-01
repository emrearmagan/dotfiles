#!/usr/bin/env bash

cmd="$1"
title="$2"

get_icon() {
	case "$1" in
	*db* | *DB*)
		echo ""
		;;
	*nvim* | *vim*)
		echo ""
		;;
	*lazygit* | *git*)
		echo ""
		;;
	*node*)
		echo ""
		;;
	*docker*)
		echo ""
		;;
	*ssh*)
		echo "󰣀"
		;;
	*opencode*)
		echo "󰚩"
		;;
	*http*)
		echo "󰖟"
		;;
	esac
}

icon=$(get_icon "$title")
if [[ -z "$icon" ]]; then
	icon=$(get_icon "$cmd")
fi

echo "${icon:-}"
