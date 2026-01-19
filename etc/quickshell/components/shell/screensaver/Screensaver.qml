import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import "../../config"

Scope {
    id: root

    property bool active: false
    property string currentSaver: "NiriSaver.qml" // Default

    // List of available screensavers
    property var savers: Config.activeScreensavers

    function pickRandomSaver() {
        var idx = Math.floor(Math.random() * savers.length);
        root.currentSaver = savers[idx];
        console.log("Selected Screensaver:", root.currentSaver);
    }

    IpcHandler {
        target: "ui.overlay.screensaver"
        
        function open() {
            if (!root.active) {
                root.pickRandomSaver();
                root.active = true;
            }
        }
        
        function close() {
            root.active = false;
        }
        
        function toggle() {
            if (!root.active) {
                root.pickRandomSaver();
                root.active = true;
            } else {
                root.active = false;
            }
        }
    }

    Variants {
        model: Quickshell.screens
        
        delegate: PanelWindow {
            id: window
            property var modelData
            screen: modelData
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            color: "black" 
            
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            
            visible: root.active
            
            // Input Catching Layer (Topmost)
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true // Detect mouse movement without click
                preventStealing: true
                z: 9999 // Ensure it's on top of everything
                
                onClicked: root.active = false
                onPositionChanged: root.active = false
                onWheel: root.active = false
            }

            // Dynamic Loader for Screensaver Content
            Loader {
                id: saverLoader
                anchors.fill: parent
                visible: true 
                source: root.active ? root.currentSaver : ""
            }

            // --- FAKE CRT OVERLAY (No Shaders - Qt6 Safe) ---
            Item {
                anchors.fill: parent
                z: 100 // Above content
                
                // 1. Scanlines
                Repeater {
                    model: parent.height / 4
                    Rectangle {
                        width: parent.width
                        height: 1
                        y: index * 4
                        color: "black"
                        opacity: 0.3
                    }
                }
                
                // 2. RGB Tint / Glow
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Qt.rgba(0.0, 1.0, 1.0, 0.1) // Cyan edge
                    border.width: 20
                    opacity: 0.5
                }
                
                // 3. Random Glitch Blocks
                Repeater {
                    model: 3
                    Rectangle {
                        x: Math.random() * parent.width
                        y: Math.random() * parent.height
                        width: Math.random() * 200
                        height: 2 + Math.random() * 20
                        color: Math.random() > 0.5 ? "cyan" : "red"
                        opacity: 0.0
                        
                        Timer {
                            interval: 50 + Math.random() * 200
                            running: root.active
                            repeat: true
                            onTriggered: {
                                parent.x = Math.random() * root.width
                                parent.y = Math.random() * root.height
                                parent.opacity = Math.random() > 0.9 ? 0.4 : 0.0
                            }
                        }
                    }
                }
            }

            // Keyboard Input Handler (Global)
            Item {
                focus: true
                anchors.fill: parent
                Keys.onPressed: root.active = false
            }
        }
    }
}
