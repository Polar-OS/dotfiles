#!/bin/bash
FILE="$TINTY_THEME_FILE_PATH"
TARGET="$HOME/.config/ghostty/themes/polar-dynamic"

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

c() {
    val="${colors[color$1]}"
    if [ -z "$val" ]; then echo "000000"; else echo "$val"; fi
}

cat <<CONFIG > "$TARGET"
background = #$(c 00)
foreground = #$(c 07)
selection-background = #$(c 19)
selection-foreground = #$(c 07)
cursor-color = #$(c 07)

palette = 0=#$(c 00)
palette = 1=#$(c 01)
palette = 2=#$(c 02)
palette = 3=#$(c 03)
palette = 4=#$(c 04)
palette = 5=#$(c 05)
palette = 6=#$(c 06)
palette = 7=#$(c 07)
palette = 8=#$(c 08)
palette = 9=#$(c 09)
palette = 10=#$(c 10)
palette = 11=#$(c 11)
palette = 12=#$(c 12)
palette = 13=#$(c 13)
palette = 14=#$(c 14)
palette = 15=#$(c 15)
CONFIG

pkill -USR2 ghostty
