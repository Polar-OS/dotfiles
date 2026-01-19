#!/bin/bash

PRIMARY_HEX="{{colors.primary.default.hex}}"
BG_HEX="{{colors.surface.default.hex}}"

PRIMARY_HEX=${PRIMARY_HEX#\#}
BG_HEX=${BG_HEX#\#}

r=$((16#${PRIMARY_HEX:0:2}))
g=$((16#${PRIMARY_HEX:2:2}))
b=$((16#${PRIMARY_HEX:4:2}))

max=$r
[ $g -gt $max ] && max=$g
[ $b -gt $max ] && max=$b

min=$r
[ $g -lt $min ] && min=$g
[ $b -lt $min ] && min=$b

dominant=""
if [ $r -eq $max ]; then
    if [ $g -gt $b ]; then
        [ $((g - b)) -gt 40 ] && dominant="orange" || dominant="pink"
    else
        [ $b -gt 150 ] && dominant="pink" || dominant="red"
    fi
elif [ $g -eq $max ]; then
    if [ $r -gt $b ]; then
        [ $((r - b)) -gt 40 ] && dominant="yellow" || dominant="green"
    else
        [ $((b - r)) -gt 40 ] && dominant="teal" || dominant="green"
    fi
else
    if [ $r -gt $g ]; then
        [ $((r - g)) -gt 40 ] && dominant="purple" || dominant="blue"
    else
        [ $((g - r)) -gt 40 ] && dominant="teal" || dominant="blue"
    fi
fi

COLOR="${dominant:-slate}"

bg_r=$((16#${BG_HEX:0:2}))
bg_g=$((16#${BG_HEX:2:2}))
bg_b=$((16#${BG_HEX:4:2}))

luminance=$((bg_r * 299 + bg_g * 587 + bg_b * 114))

if [ $luminance -gt 128000 ]; then
    SCHEME="prefer-light"
else
    SCHEME="prefer-dark"
fi

gsettings set org.gnome.desktop.interface accent-color "$COLOR"
gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"

echo "✓ GTK: $COLOR accent, $SCHEME"
