# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-12
**Commit:** ef6ec68
**Branch:** user-config

## OVERVIEW
QML-based Niri compositor shell with a modular architecture. Uses Quickshell framework for Wayland integration and a dual-layer JSON configuration system.

## STRUCTURE
\`\`\`
./
├── shell.qml               # Main entry point - orchestrates components
├── components/
│   ├── config/             # Config loading (JSON merge) & singleton
│   ├── theme/              # Theme generation & animations
│   ├── ui/                 # Base primitives (Panel, Button, Layout)
│   └── shell/              # Shell logic & structure
│       ├── panel/          # Persistent bars (Launcher, Status, Messages)
│       ├── overlay/        # Transient modals (About, Cheatsheet, Lock, Logout)
│       ├── screensaver/    # Animated screensaver variants
│       └── wallpaper/      # Wallpaper management
├── config.json             # Project/User configuration
└── themes.json             # Color scheme definitions
\`\`\`

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new theme | \`themes.json\` | Follow existing color schema |
| Change layout | \`config.json\` | Global padding/spacing overrides |
| New persistent bar | \`components/shell/panel/\` | Create subfolder with component |
| New modal/overlay | \`components/shell/overlay/\` | Transient UI logic |
| System logic | \`components/shell/panel/*/\` | Manager components (D-Bus, CLI) |
| UI Primitives | \`components/ui/\` | Reusable buttons and layouts |

## CONVENTIONS
- **Root ID**: Always use \`id: root\` for the top-level element.
- **Imports**: QtQuick -> Quickshell -> Relative (e.g., \`import "../../ui"\`).
- **Design System**: Use \`Config.<property>\` for all colors, radii, and durations.
- **PascalCase**: File names must be PascalCase (\`VolumeBar.qml\`).
- **camelCase**: Property and local ID names must be camelCase (\`hideTimer\`).

## ANTI-PATTERNS (THIS PROJECT)
- **Hardcoded Styling**: NEVER use hex codes or pixel values directly; use \`Config.qml\`.
- **Transparency in Lists**: Avoid alpha/transparency in \`ListView\` delegates; pre-calculate solid colors.
- **Focus Fighting**: Do not use aggressive timers to force panel visibility on focus loss.
- **Relative desync**: Ensure imports reflect the reorganized \`components/shell\` hierarchy.

## COMMANDS
\`\`\`bash
# Run shell
QML_IMPORT_PATH=\$HOME/.local/lib/qt6/qml quickshell -p .

# Run tests
./tests/run.sh

# IPC control
qs ipc call <target> <method>
\`\`\`

## NOTES
- The project has been reorganized: \`ui\` contains primitives, \`shell\` contains specific implementations.
- Configuration is merged from project \`config.json\` and user overrides in \`~/.config/polar/shell/\`.
