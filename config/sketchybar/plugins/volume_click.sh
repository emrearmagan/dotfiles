#!/bin/bash

WIDTH=100

INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
if [ "$INITIAL_WIDTH" -eq "0" ]; then
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
else
  sketchybar --animate tanh 30 --set volume slider.width=0
fi
