import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../config"

// System Tray widget displaying status notifier items
Item {
    id: root

    // Required reference to the parent window for menu positioning
    required property var parentWindow

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    implicitHeight: 32

    visible: true // Debug: always visible
    
    // Show count for debugging
    Text {
        visible: SystemTray.items.count === 0
        text: "No tray items"
        color: Config.dimmed
        font.family: Config.fontFamily
        font.pixelSize: 11
    }

    Flow {
        id: trayFlow
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayButton

                readonly property var item: modelData

                width: 32
                height: 32
                radius: Config.itemRadius
                color: itemMouse.containsMouse ? Qt.alpha(Config.foreground, 0.15) : Qt.alpha(Config.foreground, 0.1)

                Behavior on color {
                    ColorAnimation { duration: Config.animationDurationQuick }
                }

                // Icon with monochrome effect
                Item {
                    id: iconContainer
                    anchors.centerIn: parent
                    width: 16
                    height: 16

                    Image {
                        id: trayIcon
                        anchors.fill: parent
                        source: {
                            var src = item.icon || "";
                            return src;
                        }
                        asynchronous: true
                        sourceSize: Qt.size(16, 16)
                        visible: false
                    }

                    // Monochrome colorization effect
                    MultiEffect {
                        anchors.fill: trayIcon
                        source: trayIcon
                        visible: trayIcon.status === Image.Ready && trayIcon.source !== ""
                        colorization: 1.0
                        colorizationColor: Config.foreground
                    }

                    // Fallback: show title initial (or specific glyphs for known broken apps)
                    Text {
                        anchors.centerIn: parent
                        text: {
                            var src = item.icon || "";
                            return item.title ? item.title.charAt(0).toUpperCase() : "?"
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Config.foreground
                        visible: trayIcon.status !== Image.Ready || trayIcon.source === ""
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (item.onlyMenu && item.hasMenu) {
                                item.display(root.parentWindow, trayButton.x + trayButton.width / 2, trayButton.y + trayButton.height);
                            } else {
                                item.activate();
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu) {
                                item.display(root.parentWindow, trayButton.x + trayButton.width / 2, trayButton.y + trayButton.height);
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        }
                    }

                    onWheel: wheel => {
                        var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                        var horizontal = wheel.angleDelta.y === 0;
                        item.scroll(delta, horizontal);
                    }
                }
            }
        }
    }
}
