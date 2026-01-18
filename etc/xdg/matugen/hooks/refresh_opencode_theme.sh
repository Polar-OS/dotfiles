#!/bin/bash

LOG_FILE="/tmp/opencode_theme_refresh.log"
exec >> "$LOG_FILE" 2>&1
echo "--- $(date) ---"

THEMES_DIR="$HOME/.config/opencode/themes"
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
SOURCE_FILE="$THEMES_DIR/generated.json"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source theme file $SOURCE_FILE not found."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Warning: Config file $CONFIG_FILE not found. Creating minimal config."
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo '{ "theme": "" }' > "$CONFIG_FILE"
fi

CURRENT_THEME=$(grep -o '"theme"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed -E 's/.*"theme"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
echo "Current theme: $CURRENT_THEME"

if [ "$CURRENT_THEME" == "generated_a" ]; then
    NEW_THEME="generated_b"
else
    NEW_THEME="generated_a"
fi

NEW_FILE="$THEMES_DIR/$NEW_THEME.json"
echo "Switching to: $NEW_THEME"

# Copy the generated content to the new active file
cp "$SOURCE_FILE" "$NEW_FILE"

# Update opencode.json
# Use a more robust sed pattern that handles spacing
if grep -q '"theme"' "$CONFIG_FILE"; then
    tmp=$(mktemp)
    sed -E 's/("theme"[[:space:]]*:[[:space:]]*)"[^"]*"/\1"'"$NEW_THEME"'"/' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
else
    sed -i '$d' "$CONFIG_FILE"
    echo '    "theme": "'"$NEW_THEME"'"' >> "$CONFIG_FILE"
    echo '}' >> "$CONFIG_FILE"
fi

echo "Switched OpenCode theme to $NEW_THEME"

# Signal running OpenCode instances to hot-reload theme (uncomment when PR #4879 merges)
# pkill -USR2 opencode 2>/dev/null && echo "Signaled OpenCode instances to reload theme"
