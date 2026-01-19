#!/bin/bash
# Tinty hook for Quickshell - generates static-colors.json with theme colors
# Uses TINTY environment variables to extract base16 palette

# Extract colors from TINTY environment variables
function get_color() {
    local color_name=$1
    local r_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_R"
    local g_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_G"
    local b_var="TINTY_SCHEME_PALETTE_${color_name}_HEX_B"
    echo "#${!r_var}${!g_var}${!b_var}"
}

# Get scheme name from TINTY_SCHEME_NAME or fallback
SCHEME_NAME="${TINTY_SCHEME_NAME:-unknown}"
SCHEME_SLUG="${TINTY_SCHEME_SLUG:-$SCHEME_NAME}"

# Extract all base16 colors
base00=$(get_color "BASE00")  # Background
base01=$(get_color "BASE01")  # Lighter background
base02=$(get_color "BASE02")  # Selection background
base03=$(get_color "BASE03")  # Comments
base04=$(get_color "BASE04")  # Dark foreground
base05=$(get_color "BASE05")  # Foreground
base06=$(get_color "BASE06")  # Light foreground
base07=$(get_color "BASE07")  # Lightest foreground
base08=$(get_color "BASE08")  # Red
base09=$(get_color "BASE09")  # Orange
base0A=$(get_color "BASE0A")  # Yellow
base0B=$(get_color "BASE0B")  # Green
base0C=$(get_color "BASE0C")  # Cyan
base0D=$(get_color "BASE0D")  # Blue
base0E=$(get_color "BASE0E")  # Magenta/Purple
base0F=$(get_color "BASE0F")  # Brown/Deprecated

TARGET_FILE="$HOME/.config/quickshell/static-colors.json"

# Generate JSON with the current theme colors
# This file is watched by ConfigLoader and merged into themes
cat <<EOF > "$TARGET_FILE"
{
  "_generatedBy": "tinty-quickshell-hook",
  "_scheme": "$SCHEME_SLUG",
  "_timestamp": "$(date -Iseconds)",
  "current": {
    "name": "$SCHEME_NAME",
    "colors": {
      "background": "$base00",
      "foreground": "$base05",
      "accent": "$base0D",
      "red": "$base08",
      "green": "$base0B",
      "yellow": "$base0A",
      "orange": "$base09",
      "cyan": "$base0C",
      "purple": "$base0E",
      "statusCritical": "$base08",
      "statusWarning": "$base09",
      "statusMedium": "$base0A",
      "statusGood": "$base0B"
    },
    "base16": {
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
      "base0A": "$base0A",
      "base0B": "$base0B",
      "base0C": "$base0C",
      "base0D": "$base0D",
      "base0E": "$base0E",
      "base0F": "$base0F"
    }
  }
}
EOF

echo "[tinty-quickshell-hook] Generated $TARGET_FILE for scheme: $SCHEME_SLUG"
