#!/bin/bash
RADIUS=$1
CONFIG_FILE="$HOME/.config/niri/style.kdl"

if [ -z "$RADIUS" ]; then
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    exit 1
fi

sed -i -E "s/(geometry-corner-radius\s+)[0-9]+/\1$RADIUS/" "$CONFIG_FILE"
