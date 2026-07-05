#!/bin/bash
# Headline = next meeting; popup = upcoming events (today + 3 days).

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

case "$SENDER" in
mouse.clicked)
	sketchybar --set meeting popup.drawing=toggle
	exit 0
	;;
mouse.exited | mouse.exited.global | front_app_switched)
	sketchybar --set meeting popup.drawing=off
	exit 0
	;;
esac

ICAL_BUDDY="/opt/homebrew/bin/icalBuddy"
[ -x "$ICAL_BUDDY" ] || ICAL_BUDDY="$(command -v icalBuddy)"
if [ -z "$ICAL_BUDDY" ]; then
	sketchybar --set meeting icon="$CALENDAR" label="" icon.color=$WHITE
	exit 0
fi

# ---- headline: next event ----
COMMON_ARGS=(
	--includeEventProps "title,datetime"
	--propertyOrder "datetime,title"
	--noCalendarNames --dateFormat "%A" --limitItems 1
	--excludeAllDayEvents --separateByDate --bullet ""
	--excludeCals "training,omerxx@gmail.com"
)
NOW_EVENT=$($ICAL_BUDDY "${COMMON_ARGS[@]}" eventsNow 2>/dev/null)
if [ -n "$NOW_EVENT" ]; then
	# A meeting is happening right now → normal meeting icon + name + time range.
	START=$(printf '%s' "$NOW_EVENT" | grep -oE '[0-9]{1,2}:[0-9]{2}' | sed -n 1p)
	END=$(printf '%s' "$NOW_EVENT" | grep -oE '[0-9]{1,2}:[0-9]{2}' | sed -n 2p)
	TITLE=$(printf '%s\n' "$NOW_EVENT" | awk 'found && NF {sub(/^[[:space:]]+/, "", $0); print; exit} / - / {found=1}')
	sketchybar --set meeting icon="$CALENDAR" icon.color=$RED label="$TITLE $START-$END" label.color=$RED
else
	NEXT=$($ICAL_BUDDY "${COMMON_ARGS[@]}" --includeOnlyEventsFromNowOn eventsToday 2>/dev/null)
	TIME=$(printf '%s' "$NEXT" | grep -oE '[0-9]{1,2}:[0-9]{2}' | sed -n 1p)
	TITLE=$(printf '%s\n' "$NEXT" | awk 'found && NF {sub(/^[[:space:]]+/, "", $0); print; exit} / - / {found=1}')
	if [ -z "$TIME" ] || [ -z "$TITLE" ]; then
		sketchybar --set meeting icon="$CALENDAR" label="" icon.color=$WHITE
	else
		MINUTES=$((($(date -j -f "%H:%M" "$TIME" +%s 2>/dev/null) - $(date +%s)) / 60))
		ICON="$CALENDAR"
		COLOR=$WHITE
		if [ "$MINUTES" -lt 15 ]; then
			ICON="$BELL"
			COLOR=$RED
		fi
		sketchybar --set meeting icon="$ICON" label="$TITLE $TIME (${MINUTES}m)" icon.color=$COLOR label.color=$COLOR
	fi
fi

# ---- popup: upcoming events (Today / Tomorrow / weekday) ----
today=$(date +%Y-%m-%d)
tomorrow=$(date -v+1d +%Y-%m-%d)
idx=1
while IFS= read -r line; do
	[ -n "$line" ] || continue
	[ "$idx" -gt 6 ] && break
	title="${line%%@@@*}"
	rest="${line#*@@@}"
	rest="${rest%% - *}"     # drop end time
	d="${rest%% at *}"       # date part (YYYY-MM-DD)
	t="${rest##* at }"       # time part (HH:MM)
	if [ "$d" = "$today" ]; then
		day="Today"
	elif [ "$d" = "$tomorrow" ]; then
		day="Tomorrow"
	else
		day=$(date -j -f "%Y-%m-%d" "$d" +%a 2>/dev/null)
	fi
	sketchybar --set meeting.row.$idx drawing=on label="$day $t · $title"
	idx=$((idx + 1))
done <<EOF
$($ICAL_BUDDY -nc -npn -b "" -nrd --excludeAllDayEvents -iep "title,datetime" -po "title,datetime" -df "%Y-%m-%d" -tf "%H:%M" -ps "|@@@|" -li 6 --includeOnlyEventsFromNowOn eventsToday+3 2>/dev/null)
EOF
while [ "$idx" -le 6 ]; do
	sketchybar --set meeting.row.$idx drawing=off
	idx=$((idx + 1))
done
