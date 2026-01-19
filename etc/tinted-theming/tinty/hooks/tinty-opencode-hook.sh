#!/bin/bash

LOG_FILE="/tmp/tinty-opencode-debug.log"
exec >> "$LOG_FILE" 2>&1
echo "--- $(date) ---"
echo "Running tinty-opencode-hook"

function get_color() {
    local color_name=$1
    local r_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_R"
    local g_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_G"
    local b_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_B"
    echo "#${!r_var}${!g_var}${!b_var}"
}

echo "Sample var BASE00_HEX_R: ${TINTY_SCHEME_PALETTE_BASE00_HEX_R}"

base00=$(get_color "BASE00")
base01=$(get_color "BASE01")
base02=$(get_color "BASE02")
base03=$(get_color "BASE03")
base04=$(get_color "BASE04")
base05=$(get_color "BASE05")
base06=$(get_color "BASE06")
base07=$(get_color "BASE07")
base08=$(get_color "BASE08")
base09=$(get_color "BASE09")
base0A=$(get_color "BASE0A")
base0B=$(get_color "BASE0B")
base0C=$(get_color "BASE0C")
base0D=$(get_color "BASE0D")
base0E=$(get_color "BASE0E")
base0F=$(get_color "BASE0F")

echo "Resolved base00: $base00"

TARGET_FILE="$HOME/.config/opencode/themes/generated.json"
echo "Writing to $TARGET_FILE"

cat <<EOF > "$TARGET_FILE"
{
  "\$schema": "https://opencode.ai/theme.json",
  "defs": {
    "base00": "$base00",
    "base01": "$base01",
    "base02": "$base02",
    "base03": "$base03",
    "base04": "$base04",
    "base05": "$base05",
    "base06": "$base06",
    "base07": "$base07",
    "base08": "$base08",
    "base09": "$base09",
    "base10": "$base0A",
    "base11": "$base0B",
    "base12": "$base0C",
    "base13": "$base0D",
    "base14": "$base0E",
    "base15": "$base0F",
    "base0A": "$base0A",
    "base0B": "$base0B",
    "base0C": "$base0C",
    "base0D": "$base0D",
    "base0E": "$base0E",
    "base0F": "$base0F"
  },
  "theme": {
    "primary": { "dark": "base0D", "light": "base0D" },
    "secondary": { "dark": "base0E", "light": "base0E" },
    "tertiary": { "dark": "base0C", "light": "base0C" },
    "error": { "dark": "base08", "light": "base08" },
    "warning": { "dark": "base0A", "light": "base0A" },
    "success": { "dark": "base0B", "light": "base0B" },
    "info": { "dark": "base0C", "light": "base0C" },
    "text": { "dark": "base05", "light": "base05" },
    "textMuted": { "dark": "base03", "light": "base03" },
    "background": { "dark": "base00", "light": "base00" },
    "backgroundPanel": { "dark": "base01", "light": "base01" },
    "backgroundElement": { "dark": "base02", "light": "base02" },
    "border": { "dark": "base03", "light": "base03" },
    "borderActive": { "dark": "base0D", "light": "base0D" },
    "borderSubtle": { "dark": "base02", "light": "base02" },
    "diffAdded": { "dark": "base0B", "light": "base0B" },
    "diffRemoved": { "dark": "base08", "light": "base08" },
    "markdownCode": { "dark": "base0B", "light": "base0B" },
    "syntaxKeyword": { "dark": "base0E", "light": "base0E" },
    "syntaxFunction": { "dark": "base0D", "light": "base0D" },
    "syntaxString": { "dark": "base0B", "light": "base0B" },
    "syntaxVariable": { "dark": "base08", "light": "base08" },
    "syntaxType": { "dark": "base0A", "light": "base0A" },
    "syntaxComment": { "dark": "base03", "light": "base03" }
  }
}
EOF

echo "Calling refresh script: ~/.config/matugen/hooks/refresh_opencode_theme.sh"
bash ~/.config/matugen/hooks/refresh_opencode_theme.sh
echo "Done"



