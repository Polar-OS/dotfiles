import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../panel"

Scope {
    id: root

    property bool active: false
    // Use direct properties instead of aliases to inner delegate items
    property int windowWidth: 600
    property int windowHeight: 400
    
    // Content is a Component that will be instantiated in each window
    default property Component view
    
    // Signals
    signal dismissed

    Variants {
        model: root.active ? Quickshell.screens : []

        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            contentItem {
                focus: true
                Keys.onEscapePressed: {
                    root.active = false
                    root.dismissed()
                }
            }

            // Dimmed Background
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Config.background, 0.92)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.active = false
                        root.dismissed()
                    }
                }

                // Centered Card
                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: root.windowWidth
                    height: root.windowHeight
                    radius: Config.radius
                    color: Config.background
                    border.color: Qt.alpha(Config.foreground, 0.1)
                    border.width: 1
                    clip: true

                    // Prevent clicks inside card from closing overlay
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.AllButtons
                    }

                    // Content Container
                    Loader {
                        anchors.fill: parent
                        sourceComponent: root.view
                        focus: true
                    }
                }
            }
        }
    }
}
