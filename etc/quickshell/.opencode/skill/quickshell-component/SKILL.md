---
name: quickshell-component
description: Create QML components for Quickshell (Wayland shell framework) following best practices, View/Model separation, and official Quickshell v0.2.1 types. Use when creating new .qml files, refactoring shell components, implementing status indicators/managers, panels, or integrating with system services (Pipewire, UPower, Mpris, Bluetooth). Triggers on Quickshell component work, QML file creation, or shell UI development.
---

# Quickshell Component Creation

Create QML components following Quickshell conventions and the official type system.

## Component Template

Use this canonical structure for all Quickshell components:

```qml
// PRAGMAS (only for singletons)
// pragma Singleton

// IMPORTS: Qt -> Quickshell -> relative
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."  // Config singleton

Item {
    id: root

    // === SECTION 1: INTERFACE ===
    required property var modelData  // For Variants/Repeater
    property bool enabled: true
    property alias text: label.text
    signal clicked()
    signal extendRequested()

    // === SECTION 2: INTERNAL STATE ===
    property real _value: 0
    property bool _hovered: false

    // === SECTION 3: SIZING ===
    implicitWidth: 100
    implicitHeight: 40
    Layout.fillWidth: true

    // === SECTION 4: VISUAL (always use Config) ===
    color: Config.background
    radius: Config.itemRadius

    // === SECTION 5: BEHAVIORS ===
    Behavior on opacity {
        NumberAnimation { duration: Config.animationDuration; easing.type: Easing.OutCubic }
    }

    // === SECTION 6: FUNCTIONS ===
    function toggle(): void { root.enabled = !root.enabled }

    // === SECTION 7: CHILD ELEMENTS ===
    Text {
        id: label
        anchors.centerIn: parent
        font.family: Config.fontFamily
        color: Config.foreground
    }

    // === SECTION 8: INTERACTION ===
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
    Keys.onSpacePressed: root.clicked()

    // === SECTION 9: IPC ===
    IpcHandler {
        target: "ui.component.name"
        function toggle(): void { root.toggle() }
    }

    // === SECTION 10: CONNECTIONS ===
    Connections {
        target: ExternalSingleton
        function onSignal() { /* handle */ }
    }

    // === SECTION 11: DATA SOURCES ===
    FileView { id: dataFile; path: "/proc/file" }
    Process { id: proc; command: ["cmd"]; running: false }
    Timer { interval: 1000; running: root.visible; repeat: true; onTriggered: proc.running = true }

    // === SECTION 12: LIFECYCLE ===
    Component.onCompleted: { /* init */ }
}
```

## View/Model Separation

| Type | Purpose | Naming |
|------|---------|--------|
| **View** | Visual, interaction | `*Indicator.qml`, `*Widget.qml` |
| **Model** | Data, logic, state | `*Manager.qml`, `*Provider.qml` |
| **Controller** | Complex state machines | `*Controller.qml` |
| **Singleton** | Shared config | `pragma Singleton` + `Singleton {}` |

## Config Singleton (ALWAYS use)

```qml
import ".."  // Access Config

Rectangle {
    color: Config.background
    radius: Config.radius
    Text { color: Config.foreground; font.family: Config.fontFamily }
}
```

**Available:** `background`, `foreground`, `dimmed`, `accent`, `red`, `green`, `yellow`, `orange`, `cyan`, `statusCritical/Warning/Medium/Good`, `radius`, `itemRadius`, `padding`, `spacing`, `buttonSize`, `iconSize`, `panelWidth`, `animationDuration`, `fontFamily`, `iconFontFamily`, `isLightTheme`, `iconColor`

## Quickshell Types Reference

See [references/types.md](references/types.md) for complete type documentation.

**Core:** `PanelWindow`, `FloatingWindow`, `PopupWindow`, `Scope`, `Singleton`, `Variants`, `LazyLoader`, `SystemClock`

**I/O:** `Process`, `FileView`, `IpcHandler`, `Socket`, `SplitParser`, `StdioCollector`, `JsonAdapter`

**Services:** `Pipewire`, `UPower`, `Mpris`, `NotificationServer`, `Bluetooth`, `SystemTray`, `PamContext`

## Anti-Patterns (FORBIDDEN)

| Never | Instead |
|-------|---------|
| Hardcode colors/radii | Use `Config.*` |
| `childrenRect` for sizing | Calculate from children's implicit sizes |
| `signal textChanged` + `property alias text` | Alias auto-generates signal |
| Stack transparent rects | Pre-calculate with `Qt.alpha()` |
| Zero-sized containers | Always set implicit size |
| Process restart < 1000ms | Add delays |

## IPC Pattern

```qml
IpcHandler {
    target: "ui.panel.status"
    function toggle(): void { root.visible = !root.visible }
    function show(): void { root.visible = true }
}
// Terminal: qs ipc emit ui.panel.status toggle
```

## Multi-Screen

```qml
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
    }
}
```

## Verification

```bash
QML_IMPORT_PATH=$HOME/.local/lib/qt6/qml quickshell -p .
qs log -t 50
```
