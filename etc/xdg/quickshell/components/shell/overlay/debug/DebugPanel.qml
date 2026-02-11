import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../ui/button"
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../../ui/panel"
import "../../../config"

PanelWindow {
    id: root
    
    // Position in bottom-right corner
    anchors {
        bottom: true
        right: true
    }
    
    // Dimensions
    implicitWidth: 350
    implicitHeight: 400
    
    // Visual properties
    color: "transparent"
    
    // IPC Identification
    objectName: "ui.panel.debug"
    
    // Visibility state (start hidden)
    visible: false
    
    // Debug Mode property (can be toggled via IPC)
    property bool debugMode: false
    
    // Toggle function for IPC
    function toggle() {
        root.visible = !root.visible
    }
    
    // Enable debug mode via IPC
    function setDebug(enabled) {
        root.debugMode = enabled
        if (enabled) root.visible = true
    }

    // IPC Handler with standard naming convention
    IpcHandler {
        target: "ui.panel.debug"
        
        function toggle() { root.toggle() }
        function open() { root.visible = true }
        function close() { root.visible = false }
        
        // Alternatives to setDebug for easier CLI usage
        function enable() { root.setDebug(true) }
        function disable() { root.setDebug(false) }
    }

    // Background and Content
    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        color: Config.background
        radius: Config.radius
        border.width: 1
        border.color: Config.dimmed
        
        // Main Layout
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Debug Panel"
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                    color: Config.foreground
                }
                
                Item { Layout.fillWidth: true }
                
                // Debug Mode Indicator
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: root.debugMode ? Config.statusGood : Config.statusCritical
                }
                
                Text {
                    text: root.debugMode ? "DEBUG ON" : "DEBUG OFF"
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    color: Config.dimmed
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.dimmed
                opacity: 0.2
            }
            
            // System Info Section
            Label {
                text: "System Info"
                font.bold: true
                color: Config.accent
            }
            
            GridLayout {
                columns: 2
                rowSpacing: 4
                columnSpacing: 10
                
                Text { text: "Quickshell:"; color: Config.dimmed; font.family: Config.fontFamily }
                Text { text: "Running"; color: Config.foreground; font.family: Config.fontFamily }
                
                Text { text: "Resolution:"; color: Config.dimmed; font.family: Config.fontFamily }
                Text { text: Screen.width + "x" + Screen.height; color: Config.foreground; font.family: Config.fontFamily }
                
                Text { text: "Scale:"; color: Config.dimmed; font.family: Config.fontFamily }
                Text { text: Screen.devicePixelRatio.toFixed(2); color: Config.foreground; font.family: Config.fontFamily }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.dimmed
                opacity: 0.2
            }
            
            // Logs Section
            RowLayout {
                Label {
                    text: "Logs (journalctl)"
                    font.bold: true
                    color: Config.accent
                }
                Item { Layout.fillWidth: true }
                QuickButton {
                    size: 24
                    icon: "" // Refresh icon
                    onClicked: logProcess.running = true
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.darker(Config.background, 1.2)
                radius: 4
                clip: true
                
                ScrollView {
                    anchors.fill: parent
                    
                    TextArea {
                        id: logView
                        text: "Loading logs...\n"
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        color: Config.foreground
                        readOnly: true
                        background: null
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
    
    // Process to fetch logs
    Process {
        id: logProcess
        command: ["journalctl", "--user", "-t", "quickshell", "-n", "50", "--no-pager"]
        running: root.visible // Run when panel is visible
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                logView.text += data + "\n"
            }
        }
    }
    
    // Auto-refresh logs periodically if visible
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: logProcess.running = true
    }
}
