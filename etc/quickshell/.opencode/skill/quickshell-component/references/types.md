# Quickshell Types Reference (v0.2.1)

Complete reference for official Quickshell types. Docs: https://quickshell.org/docs/v0.2.1/types/

## Core Types (import Quickshell)

| Type | Purpose | Key Properties |
|------|---------|----------------|
| `PanelWindow` | Wayland layer shell panel | `screen`, `anchors`, `exclusionMode`, `implicitWidth/Height` |
| `FloatingWindow` | Standard desktop window | `screen`, `visible`, `title` |
| `PopupWindow` | Positioned popup | `anchor`, `visible`, `parentWindow` |
| `Scope` | Non-visual container | Groups logic, used with Variants |
| `Singleton` | Single instance type | Base for global singletons |
| `Variants` | Create instances from model | `model`, `delegate` (default prop) |
| `LazyLoader` | Deferred loading | `active`, `loading`, `item` |
| `SystemClock` | System time | `date`, `precision` (Seconds/Minutes) |
| `ObjectRepeater` | Repeat non-visual objects | `model`, `delegate` |
| `Quickshell` | Global singleton | `screens`, `env()`, `reload()` |

### PanelWindow Example
```qml
PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    exclusionMode: ExclusionMode.Normal  // Reserve space
    // content...
}
```

### Variants Example
```qml
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
    }
}
```

## I/O Types (import Quickshell.Io)

| Type | Purpose | Key Properties |
|------|---------|----------------|
| `Process` | Run commands | `command`, `running`, `stdout`, `stderr` |
| `FileView` | Read files reactively | `path`, `text()`, `exists` |
| `IpcHandler` | Handle IPC commands | `target` (unique ID) |
| `Socket` | Network/Unix sockets | `path`, `connected` |
| `SplitParser` | Parse line-by-line | `onRead(line)` |
| `StdioCollector` | Collect full output | `text`, `onStreamFinished` |
| `JsonAdapter` | Parse JSON | Use with FileView |

### Process + SplitParser Example
```qml
Process {
    id: proc
    command: ["nmcli", "-t", "device", "wifi", "list"]
    running: false
    stdout: SplitParser {
        onRead: (line) => { root._parseLine(line) }
    }
}
Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: proc.running = true
}
```

### FileView Example
```qml
FileView {
    id: cpuFile
    path: "/proc/stat"
}
// Use: cpuFile.text()
```

### IpcHandler Example
```qml
IpcHandler {
    target: "ui.panel.launcher"
    function toggle(): void { root.visible = !root.visible }
    function show(): void { root.visible = true }
    function hide(): void { root.visible = false }
}
// CLI: qs ipc emit ui.panel.launcher toggle
```

## Service Types

### Pipewire (import Quickshell.Services.Pipewire)

| Type | Purpose |
|------|---------|
| `Pipewire` | Singleton, audio graph access |
| `PwNode` | Audio node |
| `PwNodeAudio` | Audio properties (volume, muted) |
| `PwObjectTracker` | Track object lifecycle |

```qml
import Quickshell.Services.Pipewire

// Volume control
property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

function setVolume(val: real): void {
    if (Pipewire.defaultAudioSink?.audio)
        Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, val))
}

PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
```

### UPower (import Quickshell.Services.UPower)

| Type | Purpose |
|------|---------|
| `UPower` | Singleton, device access |
| `UPowerDevice` | Battery/power device |
| `PowerProfiles` | Power profile control |

```qml
import Quickshell.Services.UPower

property var battery: UPower.displayDevice
property real percentage: battery?.percentage ?? 0
property bool charging: battery?.state === UPowerDeviceState.Charging
```

### Mpris (import Quickshell.Services.Mpris)

| Type | Purpose |
|------|---------|
| `Mpris` | Singleton, player access |
| `MprisPlayer` | Media player control |

```qml
import Quickshell.Services.Mpris

property var player: Mpris.players.values[0] ?? null
// player.playPause(), player.next(), player.previous()
// player.title, player.artist, player.albumArt
```

### Notifications (import Quickshell.Services.Notifications)

| Type | Purpose |
|------|---------|
| `NotificationServer` | D-Bus notification daemon |
| `Notification` | Individual notification |

```qml
NotificationServer {
    id: notifServer
    onNotification: (notif) => { notifModel.append(notif) }
}
```

### Bluetooth (import Quickshell.Bluetooth)

| Type | Purpose |
|------|---------|
| `Bluetooth` | Singleton |
| `BluetoothDevice` | BT device |
| `BluetoothAdapter` | BT adapter |

### SystemTray (import Quickshell.Services.SystemTray)

| Type | Purpose |
|------|---------|
| `SystemTray` | Singleton, tray items |
| `SystemTrayItem` | Individual tray item |

### Pam (import Quickshell.Services.Pam)

| Type | Purpose |
|------|---------|
| `PamContext` | PAM authentication |

```qml
PamContext {
    id: pam
    configDirectory: "/etc/pam.d"
    config: "login"
    onAuthenticateResult: (result) => {
        if (result === PamResult.Success) unlockSession()
    }
}
// pam.start(username); pam.respond(password)
```

## Wayland Types (import Quickshell.Wayland)

| Type | Purpose |
|------|---------|
| `WlrLayershell` | Layer shell properties |
| `WlrLayer` | Layer enum (Background, Bottom, Top, Overlay) |
| `WlSessionLock` | Session lock |
| `WlSessionLockSurface` | Lock surface |
| `ToplevelManager` | Window management |

## Widget Types (import Quickshell.Widgets)

| Type | Purpose |
|------|---------|
| `WrapperItem` | Item with margin management |
| `WrapperRectangle` | Rectangle with margins |
| `ClippingRectangle` | Clips children |
| `IconImage` | XDG icon display |
| `MarginWrapperManager` | Auto margin handling |

## Size and Position

### Implicit vs Actual Size
- `implicitWidth/Height`: Desired size, flows UP to parent
- `width/height`: Actual size, flows DOWN from parent
- Inside layouts, never set width/height directly

### Layout Properties
```qml
Layout.fillWidth: true
Layout.fillHeight: true
Layout.preferredWidth: 100
Layout.alignment: Qt.AlignCenter
```

### Anchors
```qml
anchors.fill: parent
anchors.centerIn: parent
anchors.margins: Config.padding
```

### AVOID childrenRect (causes binding loops)
```qml
// BAD:
implicitWidth: childrenRect.width

// GOOD:
implicitWidth: child.implicitWidth + padding * 2
```
