# SCREENSAVER SUBSYSTEM

## OVERVIEW
Animated screensaver variants designed for visual flair during idle states. Each variant focuses on a specific theme (Distros, Frameworks, etc.) using high-energy animations and glitch effects.

## STRUCTURE
- `Screensaver.qml`: Master controller and variant switcher.
- `ChaosBase.qml`: Core engine providing grid effects and movement logic.
- `*Saver.qml`: Specific implementations (Arch, Fedora, Wayland, etc.).

## KEY CONVENTIONS
- **Base Logic**: All variants SHOULD inherit from or implement the logic found in `ChaosBase.qml` for consistency.
- **Coloring**: Primary animation elements MUST use `Config.accent` instead of hardcoded brand colors to ensure theme compatibility.
- **Adaptability**: Use `root.chaosLevel` (from `ChaosBase`) to scale animation intensity.
- **Performance**: Use `Timer` for movement logic to keep the UI thread responsive during heavy animations.

## ANTI-PATTERNS
- **Hardcoded Colors**: NEVER use hex codes (e.g., `#1793d1`) or literal color names (e.g., `black`). Currently, many files in this directory violate this; new work must use `Config` tokens.
- **Static UI**: Screensavers must remain dynamic; avoid long periods of static imagery which defeats the purpose of a screensaver.
- **Complex SVGs**: Prefer procedural `Canvas` or `Rectangle` elements over high-vertex SVGs to minimize GPU load during idle.
