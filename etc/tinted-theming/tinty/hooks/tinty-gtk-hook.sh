#!/bin/bash

FILE="$TINTY_THEME_FILE_PATH"

declare -A colors

while IFS='=' read -r key val; do
    key=$(echo "$key" | tr -d ' ')
    val=$(echo "$val" | cut -d'"' -f2 | cut -d'#' -f1 | tr -d ' ' | tr -d '/')
    if [[ $key == color* ]]; then
        colors[$key]="$val"
    fi
done < "$FILE"

for k in "${!colors[@]}"; do
    val="${colors[$k]}"
    if [[ $val == \$* ]]; then
        ref_key="${val:1}"
        colors[$k]="${colors[$ref_key]}"
    fi
done

PRIMARY_COLOR="${colors[color04]}"
BG_COLOR="${colors[color00]}"

case "$PRIMARY_COLOR" in
    *ff*00*|*ff*a5*|*ff*69*) COLOR="orange" ;;
    *ff*00*|*dc*14*|*e0*1b*) COLOR="red" ;;
    *ff*c0*|*f6*6d*|*ea*76*) COLOR="pink" ;;
    *a0*6a*|*91*3d*|*c0*61*) COLOR="purple" ;;
    *33*d1*|*26*a2*|*1a*7f*) COLOR="blue" ;;
    *2e*c2*|*00*d4*|*19*b5*) COLOR="teal" ;;
    *2e*c2*|*26*a2*|*2e*a0*) COLOR="green" ;;
    *e5*a5*|*f5*c2*|*f9*e2*) COLOR="yellow" ;;
    *70*76*|*64*6d*|*5e*66*) COLOR="slate" ;;
    *) COLOR="blue" ;;
esac

bg_r=$((16#${BG_COLOR:0:2}))
bg_g=$((16#${BG_COLOR:2:2}))
bg_b=$((16#${BG_COLOR:4:2}))

luminance=$((bg_r * 299 + bg_g * 587 + bg_b * 114))

if [ $luminance -gt 128000 ]; then
    SCHEME="prefer-light"
else
    SCHEME="prefer-dark"
fi

gsettings set org.gnome.desktop.interface accent-color "$COLOR"
gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"

echo "✓ GTK: $COLOR accent, $SCHEME"
