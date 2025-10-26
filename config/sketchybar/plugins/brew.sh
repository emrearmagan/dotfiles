#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

popup() {
  sketchybar --set $NAME popup.drawing=$1
}

update() {
  COUNT=$(zsh -l -c "/opt/homebrew/bin/brew outdated --quiet" | wc -l | tr -d ' ')
  COLOR=$RED
  case "$COUNT" in
    0)
      COLOR=$GREEN
      COUNT=􀆅
      ;;
    [12])
      COLOR=$WHITE
      ;;
    [34])
      COLOR=$YELLOW
      ;;
    [5-7])
      COLOR=$PEACH
      ;;
    *)
      COLOR=$RED
      ;;
  esac
  sketchybar --set "$NAME" label="$COUNT" icon.color=$COLOR
}

case "$SENDER" in
  "routine"|"forced")
    update
    ;;
  "mouse.entered")
    # Remove previous popup items
    sketchybar --remove '/brew.popup.*/'
    # Get outdated packages
    OUTDATED=$(zsh -l -c "/opt/homebrew/bin/brew outdated --quiet")
    if [ -z "$OUTDATED" ]; then
      OUTDATED="No outdated packages!"
    fi
    COUNTER=0
    while read -r pkg; do
      COUNTER=$((COUNTER+1))
      popup_item=(
        label="$pkg"
        drawing=on
        position=popup.brew
      )
      sketchybar --clone brew.popup.$COUNTER brew --set brew.popup.$COUNTER "${popup_item[@]}"
    done <<<"$OUTDATED"
    popup on
    ;;
  "mouse.exited"|"mouse.exited.global")
    popup off
    sketchybar --remove '/brew.popup.*/'
    ;;
esac
