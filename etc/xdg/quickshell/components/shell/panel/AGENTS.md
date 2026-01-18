# Shell Panel Components

Persistent UI bars providing system interaction, status monitoring, and navigation.

## Overview
The shell consists of four main persistent panel areas:
- **Launcher**: App starting, mode switching (themes, wallpapers), and search.
- **Status**: Right-edge sidebar for quick settings (Wifi, Bluetooth, Battery, Volume).
- **Messages**: Left-edge sidebar for time, notifications, and system monitoring.
- **Workspaces**: Workspace navigation and overview.

## Structure
```
panel/
├── launcher/  # App launcher and provider logic
├── status/    # Quick settings and hardware indicators
├── message/   # Notifications, clock, and system monitors
└── workspace/ # Workspace switching and indicators
```

## Manager-Indicator Pattern
Most panel components follow a split architecture to separate logic from UI:

| Component | Responsibility | Examples |
|-----------|----------------|----------|
| **Manager** | Logic, system integration (procfs, D-Bus, CLI) | `CpuManager`, `WifiManager` |
| **Indicator** | UI representation, small icons, interaction | `CpuIndicator`, `WifiIndicator` |

### Interaction Flow
1. **Managers** expose properties (e.g., `signalStrength`, `usagePercentage`) and methods.
2. **Indicators** bind to Manager properties for visual state.
3. **Indicators** emit `extendRequested()` signal when clicked or focused.
4. **Panel Orchestrators** (e.g., `Status.qml`) show the full Manager UI upon receiving the signal.

## Key Conventions

### Navigation & Focus
Keyboard accessibility is mandatory for all panel elements:
- **Directional Flow**:
  - **Vertical Bars**: `up`/`down` moves focus between Indicators in the sidebar.
  - **Status (Right Bar)**: `left` moves focus into the extended Manager panel; `right` returns focus to the Indicator.
  - **Messages (Left Bar)**: `right` moves focus into the extended Manager panel; `left` returns focus to the Indicator.
- **Initial Focus**: Managers must expose a `firstButton` or `focusTarget` alias for the orchestrator to focus upon opening.

### Component Design
- **Imports**: Always use relative imports for sibling components (e.g., `import "../launcher"`).
- **State**: Keep indicators stateless; all persistent state must reside in Managers or `Config`.
- **Visibility**: Indicators should use `visible: manager.isAvailable` to handle missing dependencies (e.g., `nmcli`).
