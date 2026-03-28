#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

ICAL_BUDDY="/opt/homebrew/bin/icalBuddy"
if [[ ! -x "$ICAL_BUDDY" ]]; then
	ICAL_BUDDY="$(command -v icalBuddy)"
fi

if [[ -z "$ICAL_BUDDY" ]]; then
	sketchybar --set "$NAME" icon="$CALENDAR" label="No meetings" icon.color=$WHITE label.color=$WHITE
	exit 0
fi

COMMON_ARGS=(
	--includeEventProps "title,datetime"
	--propertyOrder "datetime,title"
	--noCalendarNames
	--dateFormat "%A"
	--limitItems 1
	--excludeAllDayEvents
	--separateByDate
	--bullet ""
	--excludeCals "training,omerxx@gmail.com"
)

MEETING=$($ICAL_BUDDY "${COMMON_ARGS[@]}" eventsNow 2>/dev/null)
if [[ -z "$MEETING" ]]; then
	MEETING=$($ICAL_BUDDY "${COMMON_ARGS[@]}" --includeOnlyEventsFromNowOn eventsToday 2>/dev/null)
fi

TIME=$(printf '%s\n' "$MEETING" | awk '/ - / {print $1; exit}')
TITLE=$(printf '%s\n' "$MEETING" | awk 'found && NF {sub(/^[[:space:]]+/, "", $0); print; exit} / - / {found=1}')

if [[ -z "$TIME" || -z "$TITLE" ]]; then
	sketchybar --set "$NAME" icon="$CALENDAR" label="No meetings" icon.color=$WHITE label.color=$WHITE
	exit 0
fi

MINUTES=$((($(date -j -f "%H:%M" "$TIME" +%s 2>/dev/null) - $(date +%s)) / 60))

ICON="$CALENDAR"
COLOR=$WHITE
if [[ $MINUTES -lt 15 && $MINUTES -gt -60 ]]; then
	ICON="$BELL"
	COLOR=$RED
fi

sketchybar --set "$NAME" icon="$ICON" label="$TITLE $TIME (${MINUTES}m)" icon.color=$COLOR label.color=$COLOR
