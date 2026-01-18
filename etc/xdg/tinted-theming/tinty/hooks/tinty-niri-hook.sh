#!/bin/bash
base0D="#${TINTY_SCHEME_PALETTE_BASE0D_HEX_R}${TINTY_SCHEME_PALETTE_BASE0D_HEX_G}${TINTY_SCHEME_PALETTE_BASE0D_HEX_B}"
base02="#${TINTY_SCHEME_PALETTE_BASE02_HEX_R}${TINTY_SCHEME_PALETTE_BASE02_HEX_G}${TINTY_SCHEME_PALETTE_BASE02_HEX_B}"
base0E="#${TINTY_SCHEME_PALETTE_BASE0E_HEX_R}${TINTY_SCHEME_PALETTE_BASE0E_HEX_G}${TINTY_SCHEME_PALETTE_BASE0E_HEX_B}"
base01="#${TINTY_SCHEME_PALETTE_BASE01_HEX_R}${TINTY_SCHEME_PALETTE_BASE01_HEX_G}${TINTY_SCHEME_PALETTE_BASE01_HEX_B}"

# Only write colors, no layout or static props
cat <<CONFIG > ~/.config/niri/colors.kdl
layout {
    focus-ring {
        active-color "$base0D"
        inactive-color "$base02"
    }
    border {
        active-color "$base0E"
        inactive-color "$base01"
    }
}
CONFIG

niri msg action load-config-file 2>/dev/null
