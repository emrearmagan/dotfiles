#!/usr/bin/env bash

cmd="$1"
title="$2"

name="${title:-$cmd}"

case "$name" in
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

*zsh* | *bash* | *fish*)
	echo ""
	;;

*opencode*)
	echo "󰚩"
	;;

*)
	echo ""
	;;
esac
