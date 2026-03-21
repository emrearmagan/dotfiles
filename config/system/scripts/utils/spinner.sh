#!/bin/bash -e

declare -x FRAME
declare -x FRAME_INTERVAL

: "${SPINNER_FRAME_COLOR:=text}"
: "${SPINNER_TEXT_COLOR:=text}"
: "${SPINNER_SUCCESS_COLOR:=green}"
: "${SPINNER_ERROR_COLOR:=red}"

paint() {
	local color_name="$1"
	shift || true
	local text="$*"

	if declare -F colorize >/dev/null 2>&1; then
		colorize "$color_name" "$text"
	else
		printf '%s' "$text"
	fi
}

set_spinner() {
	case $1 in
	spinner1)
		FRAME=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
		FRAME_INTERVAL=0.1
		;;
	spinner2)
		FRAME=("-" "\\" "|" "/")
		FRAME_INTERVAL=0.25
		;;
	spinner3)
		FRAME=("◐" "◓" "◑" "◒")
		FRAME_INTERVAL=0.5
		;;
	spinner4)
		FRAME=(":(" ":|" ":)" ":D")
		FRAME_INTERVAL=0.5
		;;
	spinner5)
		FRAME=("◇" "◈" "◆")
		FRAME_INTERVAL=0.5
		;;
	spinner6)
		FRAME=("⚬" "⚭" "⚮" "⚯")
		FRAME_INTERVAL=0.25
		;;
	spinner7)
		FRAME=("░" "▒" "▓" "█" "▓" "▒")
		FRAME_INTERVAL=0.25
		;;
	spinner8)
		FRAME=("☉" "◎" "◉" "●" "◉")
		FRAME_INTERVAL=0.1
		;;
	spinner9)
		FRAME=("❤" "♥" "♡")
		FRAME_INTERVAL=0.15
		;;
	spinner10)
		FRAME=("✧" "☆" "★" "✪" "◌" "✲")
		FRAME_INTERVAL=0.1
		;;
	spinner11)
		FRAME=("●" "◕" "☯" "◔" "◕")
		FRAME_INTERVAL=0.25
		;;
	*)
		echo "No spinner is defined for $1"
		exit 1
		;;
	esac
}

start() {
	local step=0

	tput civis -- invisible

	while [ "$step" -lt "${#CMDS[@]}" ]; do
		${CMDS[$step]} &
		pid=$!

		while ps -p $pid &>/dev/null; do
			for k in "${!FRAME[@]}"; do
				printf '\r[ %s ] %s ...' "$(paint "$SPINNER_FRAME_COLOR" "${FRAME[k]}")" "$(paint "$SPINNER_TEXT_COLOR" "${STEPS[$step]}")"
				sleep $FRAME_INTERVAL
			done
		done

		if ! wait "$pid"; then
			printf '\r\033[K[ %s ] %s\n' "$(paint "$SPINNER_ERROR_COLOR" "✖")" "$(paint "$SPINNER_TEXT_COLOR" "${STEPS[$step]}")"
			tput cnorm -- normal
			return 1
		fi

		printf '\r\033[K[ %s ] %s\n' "$(paint "$SPINNER_SUCCESS_COLOR" "✔")" "$(paint "$SPINNER_TEXT_COLOR" "${STEPS[$step]}")"
		step=$((step + 1))
	done

	tput cnorm -- normal
}

set_spinner "$1"
