// Template: Quickshell Component
// Copy and customize this template for new components
//
// File naming conventions:
//   *Indicator.qml - Small icon button (visual)
//   *Manager.qml   - Data/logic (model, pragma Singleton)
//   *Widget.qml    - Visual widget
//   *Provider.qml  - Data provider
//   *Controller.qml - Complex state machine

// ============================================================================
// PRAGMAS
// ============================================================================
// Uncomment for singletons:
// pragma Singleton

// ============================================================================
// IMPORTS (order: Qt -> Quickshell -> relative)
// ============================================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
// import Quickshell.Services.Pipewire
// import Quickshell.Services.UPower
// import Quickshell.Services.Mpris
import ".."  // Config singleton

// ============================================================================
// ROOT COMPONENT
// ============================================================================
// For singletons, use: Singleton {
// For visuals: Item, Rectangle, ColumnLayout, RowLayout
Item {
    id: root

    // ========================================================================
    // SECTION 1: INTERFACE (Public API)
    // ========================================================================
    // Required properties (for Variants/Repeater)
    // required property var modelData

    // Public properties
    property bool enabled: true

    // Property aliases (expose internal elements)
    // property alias text: label.text

    // Signals
    signal clicked()
    signal extendRequested()

    // ========================================================================
    // SECTION 2: INTERNAL STATE
    // ========================================================================
    property real _internalValue: 0
    property bool _isHovered: false

    // ========================================================================
    // SECTION 3: LAYOUT & SIZING
    // ========================================================================
    implicitWidth: 100
    implicitHeight: 40

    // For use inside RowLayout/ColumnLayout:
    // Layout.fillWidth: true
    // Layout.preferredHeight: 50
    // Layout.alignment: Qt.AlignCenter

    // ========================================================================
    // SECTION 4: VISUAL PROPERTIES (always use Config)
    // ========================================================================
    // color: Config.background
    // radius: Config.itemRadius
    // border.width: activeFocus ? 2 : 0
    // border.color: Config.accent

    // ========================================================================
    // SECTION 5: BEHAVIORS & ANIMATIONS
    // ========================================================================
    Behavior on opacity {
        NumberAnimation {
            duration: Config.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    // ========================================================================
    // SECTION 6: FUNCTIONS
    // ========================================================================
    function toggle(): void {
        root.enabled = !root.enabled
    }

    // ========================================================================
    // SECTION 7: CHILD VISUAL ELEMENTS
    // ========================================================================
    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Config.foreground, 0.1)
        radius: Config.itemRadius
    }

    // Content
    Text {
        id: label
        anchors.centerIn: parent
        text: "Component"
        font.family: Config.fontFamily
        font.pixelSize: 14
        color: Config.foreground
    }

    // ========================================================================
    // SECTION 8: INTERACTION HANDLERS
    // ========================================================================
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root._isHovered = true
        onExited: root._isHovered = false
    }

    // Keyboard navigation
    activeFocusOnTab: true
    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()

    // ========================================================================
    // SECTION 9: IPC HANDLERS
    // ========================================================================
    // IpcHandler {
    //     target: "ui.component.name"  // Unique target ID
    //     function toggle(): void { root.toggle() }
    //     function show(): void { root.visible = true }
    // }

    // ========================================================================
    // SECTION 10: CONNECTIONS & BINDINGS
    // ========================================================================
    // Connections {
    //     target: SomeExternalSingleton
    //     function onSomeSignal() { /* handle */ }
    // }

    // ========================================================================
    // SECTION 11: DATA SOURCES
    // ========================================================================
    // FileView {
    //     id: dataFile
    //     path: "/proc/some/file"
    // }

    // Process {
    //     id: dataProcess
    //     command: ["some-command"]
    //     running: false
    //     stdout: SplitParser {
    //         onRead: (line) => { root._processLine(line) }
    //     }
    // }

    // Timer {
    //     interval: 1000
    //     running: root.visible
    //     repeat: true
    //     onTriggered: dataProcess.running = true
    // }

    // ========================================================================
    // SECTION 12: LIFECYCLE
    // ========================================================================
    Component.onCompleted: {
        console.log("Component initialized")
    }
}
