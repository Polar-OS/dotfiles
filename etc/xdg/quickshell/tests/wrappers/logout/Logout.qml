import QtQuick
import QtQuick.Layouts
import Quickshell 1.0
import Quickshell.Wayland 1.0
import Quickshell.Io
import "../../../ui/shell" // OverlayWindow
import ".."

OverlayWindow {
    id: root
    active: false
    windowWidth: 600
    windowHeight: 400
    
    property var lockContext: null

    view: FocusScope {
        id: contentRoot
        anchors.fill: parent
        focus: true

        property int currentIndex: 0
        readonly property int columns: 3
        readonly property int rows: 2
        property var buttons: [lockBtn, logoutBtn, suspendBtn, hibernateBtn, rebootBtn, shutdownBtn]

        onVisibleChanged: if (visible) forceActiveFocus()
        Component.onCompleted: {
            contentRoot.currentIndex = 0
            forceActiveFocus()
        }

        LogoutButton {
            id: lockBtn
            text: "Lock"
            icon: "\u{f0338}"
            keybind: Qt.Key_L
            action: () => root.lockContext ? root.lockContext.active = true : null
        }

        LogoutButton {
            id: logoutBtn
            text: "Logout"
            icon: "\u{f17bc}"
            keybind: Qt.Key_E
            command: "loginctl terminate-user $USER"
        }

        LogoutButton {
            id: suspendBtn
            text: "Suspend"
            icon: "\u{f10b2}"
            keybind: Qt.Key_U
            command: "systemctl suspend"
        }

        LogoutButton {
            id: hibernateBtn
            text: "Hibernate"
            icon: "\u{f02ca}"
            keybind: Qt.Key_H
            command: "systemctl hibernate"
        }

        LogoutButton {
            id: rebootBtn
            text: "Reboot"
            icon: "\u{f0709}"
            keybind: Qt.Key_R
            command: "systemctl reboot"
        }

        LogoutButton {
            id: shutdownBtn
            text: "Shutdown"
            icon: "\u{f0425}"
            keybind: Qt.Key_S
            command: "systemctl poweroff"
        }

        // Navigation helpers
        function moveLeft() { if (currentIndex % columns > 0) currentIndex--; }
        function moveRight() { if (currentIndex % columns < columns - 1 && currentIndex < buttons.length - 1) currentIndex++; }
        function moveUp() { if (currentIndex >= columns) currentIndex -= columns; }
        function moveDown() { if (currentIndex + columns < buttons.length) currentIndex += columns; }
        function executeCurrentAction() {
            if (currentIndex >= 0 && currentIndex < buttons.length) {
                buttons[currentIndex].exec();
                root.active = false;
            }
        }
        
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left: contentRoot.moveLeft(); break;
            case Qt.Key_Right: contentRoot.moveRight(); break;
            case Qt.Key_Up: contentRoot.moveUp(); break;
            case Qt.Key_Down: contentRoot.moveDown(); break;
            case Qt.Key_Return:
            case Qt.Key_Enter: contentRoot.executeCurrentAction(); break;
            default:
                for (let i = 0; i < contentRoot.buttons.length; i++) {
                    let button = contentRoot.buttons[i];
                    if (event.key === button.keybind) {
                        button.exec();
                        root.active = false;
                        break;
                    }
                }
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 25

            // Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Session"
                font.family: Config.fontFamily
                font.pixelSize: 22
                font.bold: true
                color: Config.foreground
            }

            // Button Grid
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: contentRoot.columns
                columnSpacing: 15
                rowSpacing: 15

                Repeater {
                    model: contentRoot.buttons
                    delegate: Rectangle {
                        id: buttonDelegate
                        required property var modelData
                        required property int index

                        property bool isSelected: contentRoot.currentIndex === index
                        property bool isHovered: buttonMa.containsMouse

                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 95
                        radius: Config.itemRadius
                        color: isSelected ? Config.accent : (isHovered ? Qt.alpha(Config.foreground, 0.12) : Qt.alpha(Config.foreground, 0.06))

                        Behavior on color {
                            ColorAnimation { duration: Config.animationDurationQuick }
                        }

                        MouseArea {
                            id: buttonMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: contentRoot.currentIndex = index
                            onClicked: {
                                buttonDelegate.modelData.exec();
                                root.active = false;
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: buttonDelegate.modelData.icon
                                font.family: Config.iconFontFamily
                                font.pixelSize: 30
                                color: buttonDelegate.isSelected ? Config.background : Config.foreground

                                Behavior on color {
                                    ColorAnimation { duration: Config.animationDurationQuick }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: buttonDelegate.modelData.text
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: buttonDelegate.isSelected ? Config.background : Config.foreground

                                Behavior on color {
                                    ColorAnimation { duration: Config.animationDurationQuick }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "[" + String.fromCharCode(buttonDelegate.modelData.keybind).toLowerCase() + "]"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                color: buttonDelegate.isSelected ? Qt.alpha(Config.background, 0.7) : Config.dimmed
                                visible: buttonDelegate.modelData.keybind !== -1

                                Behavior on color {
                                    ColorAnimation { duration: Config.animationDurationQuick }
                                }
                            }
                        }
                    }
                }
            }

            // Navigation hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
                text: "← → ↑ ↓  Enter  Esc"
                font.family: Config.fontFamily
                font.pixelSize: 10
                color: Config.dimmed
            }
        }
    }
}
