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

c() {
    val="${colors[color$1]}"
    if [ -z "$val" ]; then echo "000000"; else echo "$val"; fi
}

mkdir -p ~/.config/ghostty/themes

# Determinar siguiente slot (A/B)
CONFIG_FILE="$HOME/.config/ghostty/config"
CURRENT_THEME=$(grep "^theme = polar-theme-" "$CONFIG_FILE" | cut -d'-' -f3)

if [ "$CURRENT_THEME" == "A" ]; then
    NEXT_THEME="B"
else
    NEXT_THEME="A"
fi

THEME_FILE="$HOME/.config/ghostty/themes/polar-theme-$NEXT_THEME"

cat <<CONFIG > "$THEME_FILE"
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

# Actualizar el config principal ATÓMICAMENTE
# Usamos un archivo temporal para evitar lecturas parciales
TEMP_CONFIG=$(mktemp)
cp "$CONFIG_FILE" "$TEMP_CONFIG"

if grep -q "^theme = polar-theme-" "$TEMP_CONFIG"; then
    sed -i "s/^theme = polar-theme-.*/theme = polar-theme-$NEXT_THEME/" "$TEMP_CONFIG"
else
    echo "theme = polar-theme-$NEXT_THEME" >> "$TEMP_CONFIG"
fi

# Mover el archivo (atomic replace)
mv "$TEMP_CONFIG" "$CONFIG_FILE"
