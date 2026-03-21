#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# See https://github.com/m-sroka/bash-progress-bar/blob/master/progressbar
#
# Example usage:
: <<'comment'
declare -a arr=(
'./progressbar 70%'
'echo 70 | ./progressbar -c red'
'./progressbar 70% -s 40'
'./progressbar 50% -a'
'./progressbar 150%'
'./progressbar 150% -l'
'./progressbar 150% -c blue'
'./progressbar 80% -c red'
'./progressbar 70% -w 😼'
)

printf '\n\n'
for cmd in "${arr[@]}"
do
  printf '\e[34m  ~ '
  tput sgr0
  echo $cmd
  echo
  printf '     '
  eval "${cmd}"
  printf '\n\n\n'
done
comment

printHelp() {
	echo
	echo 'usage: progress-bar [VALUE], VALUE percentage value, e.g. 10%, 50%, 100%, 110%'
	echo
	echo '  -h help'
	echo
	echo '  -l long output - allow more than 100%'
	echo '  -s [SIZE], SIZE number of ■ showed when value is 100 (default: 10)'
	echo '  -w [CHARACTER], CHARACTER characted that is being shown as progress bar tile (default: ■)'
	echo '  -a append numeric value after progress bar'
	echo '  -c [COLOR] filled color: black|red|green|blue|brown|yellow|white'
	echo '  -e [COLOR] empty color: black|red|green|blue|brown|yellow|white'
}

# DEFAULT CONFIG PARAMETERS
color=
empty_color=
allow_more_than_max=false
character=■
granularity=10
append_numeric_after_progressbar=false

# PARSE ARGS
while getopts 'als:c:e:w:h' OPT ${@:2}; do
	case "$OPT" in
	"l") allow_more_than_max=true ;;
	"s") granularity=$OPTARG ;;
	"w") character=$OPTARG ;;
	"c") color=$(getColor "$OPTARG") ;;
	"e") empty_color=$(getColor "$OPTARG") ;;
	"a") append_numeric_after_progressbar=true ;;
	"h")
		printHelp
		exit 1
		;;
	"?")
		printHelp >&2
		exit 1
		;;

	esac
done

if [ -p /dev/stdin ]; then
	value=$(cat /dev/stdin | tr -d % | tr -d '\n')
else
	value=$(echo $1 | tr -d %)
fi

# Filled cells for 0..100 mapped to `granularity` cells.
# Example: granularity=10, value=70 => 7 filled + 3 spaces.
num_of_progress_items=$(( value * granularity / 100 ))

if [ "$allow_more_than_max" != true ] && [ "$num_of_progress_items" -gt "$granularity" ]; then
	num_of_progress_items=$granularity
fi

if [ "$num_of_progress_items" -lt 0 ]; then
	num_of_progress_items=0
fi

printf '|'
for i in $(seq 1 $granularity); do
	if [[ $i -le $num_of_progress_items ]]; then
		if [ "$color" ]; then printf '%b' "$color"; fi
		printf "$character"
		if [ "$color" ]; then eval "tput sgr0"; fi
	else
		if [ "$empty_color" ]; then
			printf '%b' "$empty_color"
			printf "$character"
			eval "tput sgr0"
		else
			printf ' '
		fi
	fi
done

printf '|'

if [ "$allow_more_than_max" = true ] && [ $num_of_progress_items -gt $granularity ]; then
	let num_of_excess_items=$num_of_progress_items-$granularity
	for i in $(seq 1 $num_of_excess_items); do
		printf $character
	done
fi

if $append_numeric_after_progressbar; then
	printf ' %d%%' $value
fi

eval "tput sgr0" # reset color
echo
