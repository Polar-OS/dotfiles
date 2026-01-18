# OVERLAY AGENT

**Directory:** `components/shell/overlay`
**Responsibility:** Transient UI modals and system-level overlays.

## OVERVIEW
Handles components that appear above the main workspace (WlrLayer.Overlay). These are non-persistent, focus-stealing modals triggered by IPC or keyboard shortcuts.

## STRUCTURE
- `about/`: System information and hardware specs display.
- `cheatsheet/`: Configurable keybindings reference with search.
- `debug/`: Log viewer and QML state debugging panel.
- `lock/`: Security layer with PAM integration (password/fingerprint).
- `logout/`: Power menu (Suspend, Reboot, Shutdown, Logout).

## BEHAVIORAL PATTERN
### 1. Focus Management
- Always use `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` when active.
- Top-level `contentItem` must have `focus: true` to capture input.

### 2. Dismissal Logic
- **Escape Key**: `Keys.onEscapePressed: root.active = false`.
- **Click Outside**: A full-screen background `MouseArea` must set `root.active = false`.
- **IPC**: Exposed via `IpcHandler` with `open()`, `close()`, and `toggle()` methods.

### 3. Rendering
- Uses `Variants` with `Quickshell.screens` model to display on all connected monitors.
- Employs `Rectangle` with `Qt.alpha(Config.background, 0.92)` for consistent dimming effects.

## CONVENTIONS
- **State**: Controlled via a single `property bool active`.
- **Imports**: Ensure `../../base` for UI primitives and `../..` for `Config`.
- **Locking**: Special case—must interface with `LockContext` for security persistence.
