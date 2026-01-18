#!/usr/bin/env bash
# Script to generate Catppuccin-compatible tmux colors from a base16 shell script
# Usage: tinty-tmux-fix.sh <path_to_tmux_theme_file>

LOG_FILE="/var/home/frieser/.local/bin/tinty-debug.log"
echo "----------------------------------------" >> "$LOG_FILE"
echo "[$(date)] Script called with args: $@" >> "$LOG_FILE"

TMUX_THEME_PATH="$1"
# Get actual theme name from tinty (artifact filename is generic)
THEME_NAME=$(/var/home/frieser/.cargo/bin/tinty current 2>/dev/null)
if [ -z "$THEME_NAME" ]; then
    # Fallback to extracting from path if tinty current fails
    THEME_NAME=$(basename "$TMUX_THEME_PATH" .conf)
fi
SHELL_THEME_PATH="$HOME/.local/share/tinted-theming/tinty/repos/niri/scripts/$THEME_NAME.sh"

OUTPUT_FILE="$HOME/.config/tmux/colors.conf"

echo "[$(date)] Processing theme: $THEME_NAME" >> "$LOG_FILE"
echo "[$(date)] Looking for shell theme at: $SHELL_THEME_PATH" >> "$LOG_FILE"

if [ -f "$SHELL_THEME_PATH" ]; then
    # Source the shell theme to get variables (color00, color01, ..., color0F)
    # The scripts export variables like color00="282a36" (no hash)
    # We need to ensure we capture them.
    
    # Enable variable export in the sourced script
    export BASE16_SHELL_ENABLE_VARS=1
    
    # Capture source output/errors
    echo "[$(date)] Sourcing theme file..." >> "$LOG_FILE"
    source "$SHELL_THEME_PATH" 2>> "$LOG_FILE"
    
    echo "[$(date)] Sourced. Checking variables..." >> "$LOG_FILE"
    echo "BASE16_COLOR_05_HEX: '$BASE16_COLOR_05_HEX'" >> "$LOG_FILE"
    echo "color05: '$color05'" >> "$LOG_FILE"

    # CRITICAL FIX: Ensure we have valid HEX values before writing
    # If variables are empty, the theme will fail silently.
    if [ -z "$BASE16_COLOR_05_HEX" ]; then
         echo "[$(date)] WARNING: BASE16 variables are empty. Attempting direct mapping from colorXX..." >> "$LOG_FILE"
         # Force mapping if export failed or wasn't present
         BASE16_COLOR_00_HEX=$(echo "$color00" | sed 's/\///g')
         BASE16_COLOR_01_HEX=$(echo "$color01" | sed 's/\///g')
         BASE16_COLOR_02_HEX=$(echo "$color02" | sed 's/\///g')
         BASE16_COLOR_03_HEX=$(echo "$color03" | sed 's/\///g')
         BASE16_COLOR_04_HEX=$(echo "$color04" | sed 's/\///g')
         BASE16_COLOR_05_HEX=$(echo "$color05" | sed 's/\///g')
         BASE16_COLOR_06_HEX=$(echo "$color06" | sed 's/\///g')
         BASE16_COLOR_07_HEX=$(echo "$color07" | sed 's/\///g')
         BASE16_COLOR_08_HEX=$(echo "$color08" | sed 's/\///g')
         BASE16_COLOR_09_HEX=$(echo "$color09" | sed 's/\///g')
         BASE16_COLOR_0A_HEX=$(echo "$color10" | sed 's/\///g')
         BASE16_COLOR_0B_HEX=$(echo "$color02" | sed 's/\///g')
         BASE16_COLOR_0C_HEX=$(echo "$color06" | sed 's/\///g')
         BASE16_COLOR_0D_HEX=$(echo "$color04" | sed 's/\///g')
         BASE16_COLOR_0E_HEX=$(echo "$color05" | sed 's/\///g')
         BASE16_COLOR_0F_HEX=$(echo "$color16" | sed 's/\///g')
    fi
    
    echo "Resolved Color 05: '$BASE16_COLOR_05_HEX'" >> "$LOG_FILE"

    # Fallback logic if BASE16_COLOR_XX_HEX is empty but colorXX is set
    # Some templates export color05="aa/bb/cc" which needs conversion to hex #aabbcc
    if [ -z "$BASE16_COLOR_05_HEX" ] && [ -n "$color05" ]; then
        echo "[$(date)] BASE16 vars empty, attempting conversion from color05 format..." >> "$LOG_FILE"
        convert_slash_color() {
            echo "$1" | sed 's/\///g'
        }
        BASE16_COLOR_00_HEX=$(convert_slash_color "$color00")
        BASE16_COLOR_01_HEX=$(convert_slash_color "$color01")
        BASE16_COLOR_02_HEX=$(convert_slash_color "$color02")
        BASE16_COLOR_03_HEX=$(convert_slash_color "$color03")
        BASE16_COLOR_04_HEX=$(convert_slash_color "$color04")
        BASE16_COLOR_05_HEX=$(convert_slash_color "$color05")
        BASE16_COLOR_06_HEX=$(convert_slash_color "$color06")
        BASE16_COLOR_07_HEX=$(convert_slash_color "$color07")
        BASE16_COLOR_08_HEX=$(convert_slash_color "$color08")
        BASE16_COLOR_09_HEX=$(convert_slash_color "$color09")
        BASE16_COLOR_0A_HEX=$(convert_slash_color "$color10") # base0A is usually color03/color11 depending on mapping
        BASE16_COLOR_0B_HEX=$(convert_slash_color "$color02")
        BASE16_COLOR_0C_HEX=$(convert_slash_color "$color06")
        BASE16_COLOR_0D_HEX=$(convert_slash_color "$color04")
        BASE16_COLOR_0E_HEX=$(convert_slash_color "$color05")
        BASE16_COLOR_0F_HEX=$(convert_slash_color "$color16") # Approximate
        
        # Re-map correctly based on standard base16 slots
        # 00-07 are base colors
        # 08=Red, 09=Orange, 0A=Yellow, 0B=Green, 0C=Cyan, 0D=Blue, 0E=Magenta, 0F=Brown
        BASE16_COLOR_0A_HEX=$(convert_slash_color "$color03")
        BASE16_COLOR_0B_HEX=$(convert_slash_color "$color02")
        BASE16_COLOR_0C_HEX=$(convert_slash_color "$color06")
        BASE16_COLOR_0D_HEX=$(convert_slash_color "$color04")
        BASE16_COLOR_0E_HEX=$(convert_slash_color "$color05")
        # Note: color variables in sh template are often 256 colors or slash formatted
    fi

    # Generate the Catppuccin override config
    echo "[$(date)] Writing to $OUTPUT_FILE" >> "$LOG_FILE"
    cat > "$OUTPUT_FILE" <<EOF
# Generated by tinty-tmux-fix.sh from $THEME_NAME

# Status Bar Background
set -g status-style "bg=#${BASE16_COLOR_00_HEX},fg=#${BASE16_COLOR_05_HEX}"

# Catppuccin v2 Dynamic Color Overrides
set -g @thm_bg "default"
set -g @thm_fg "#${BASE16_COLOR_05_HEX}"

# Accent colors
set -g @thm_rosewater "#${BASE16_COLOR_0F_HEX}"
set -g @thm_flamingo "#${BASE16_COLOR_0F_HEX}"
set -g @thm_pink "#${BASE16_COLOR_0E_HEX}"
set -g @thm_mauve "#${BASE16_COLOR_0E_HEX}"
set -g @thm_red "#${BASE16_COLOR_08_HEX}"
set -g @thm_maroon "#${BASE16_COLOR_08_HEX}"
set -g @thm_peach "#${BASE16_COLOR_09_HEX}"
set -g @thm_yellow "#${BASE16_COLOR_0A_HEX}"
set -g @thm_green "#${BASE16_COLOR_0B_HEX}"
set -g @thm_teal "#${BASE16_COLOR_0C_HEX}"
set -g @thm_sky "#${BASE16_COLOR_0C_HEX}"
set -g @thm_sapphire "#${BASE16_COLOR_0D_HEX}"
set -g @thm_blue "#${BASE16_COLOR_0D_HEX}"
set -g @thm_lavender "#${BASE16_COLOR_0E_HEX}"

# Force Module Colors to use Dynamic Accents
set -g @catppuccin_session_color "#{E:@thm_mauve}"
set -g @catppuccin_directory_color "#{E:@thm_blue}"
set -g @catppuccin_host_color "#{E:@thm_lavender}"
set -g @catppuccin_date_time_color "#{E:@thm_teal}"
set -g @catppuccin_battery_color "#{E:@thm_green}"
set -g @catppuccin_cpu_color "#{E:@thm_peach}"

# Text and UI elements
set -g @thm_subtext_1 "#${BASE16_COLOR_04_HEX}"
set -g @thm_subtext_0 "#${BASE16_COLOR_03_HEX}"
set -g @thm_overlay_2 "#${BASE16_COLOR_03_HEX}"
set -g @thm_overlay_1 "#${BASE16_COLOR_02_HEX}"
set -g @thm_overlay_0 "#${BASE16_COLOR_02_HEX}"
set -g @thm_surface_2 "#${BASE16_COLOR_01_HEX}"
set -g @thm_surface_1 "#${BASE16_COLOR_01_HEX}"
set -g @thm_surface_0 "#${BASE16_COLOR_00_HEX}"
set -g @thm_mantle "#${BASE16_COLOR_00_HEX}"
set -g @thm_crust "#${BASE16_COLOR_00_HEX}"

# Force reload of catppuccin
run ~/.config/tmux/plugins/tmux/catppuccin.tmux

EOF

    echo "[$(date)] Reloading tmux configuration..." >> "$LOG_FILE"
    bash "$HOME/.config/matugen/hooks/matugen-tmux-reload.sh" 2>> "$LOG_FILE"
    echo "[$(date)] Done." >> "$LOG_FILE"
    
else
    echo "Error: Shell theme not found at $SHELL_THEME_PATH" >> "$LOG_FILE"
    echo "Error: Shell theme not found at $SHELL_THEME_PATH" >&2
    exit 1
fi

