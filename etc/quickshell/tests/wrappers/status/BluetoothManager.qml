import QtQuick
import QtQuick.Layouts
import Quickshell 1.0
import "../../../ui/button"
import Quickshell.Bluetooth 1.0
import "../base"
import ".."

Item {
    id: root

    property var adapter: Bluetooth.defaultAdapter

    // Expose navigation target
    property alias firstButton: powerToggleBtn
    property var menuButton: null

    Layout.fillHeight: true

    // Function to get Nerd Font icon based on device type
    function getDeviceIcon(deviceIcon, connected) {
        if (!deviceIcon) {
            return "󰂯"; // Default Bluetooth icon
        }

        // Map system icon names to Nerd Font icons
        const iconMap = {
            "audio-headphones": "󰋋",
            "audio-headset": "󰋋",
            "audio-speakers": "󰕾",
            "audio-card": "󰕾",
            "input-mouse": "󰍽",
            "input-keyboard": "󰌌",
            "input-tablet": "󰔫",
            "input-gaming": "󰖯",
            "input-touchpad": "󰍀",
            "phone": "󰄜",
            "printer": "󰐪",
            "network-wireless": "󰖩",
            "video-display": "󰍹",
            "camera": "󰀎",
            "video-camera": "󰄧",
            "bluetooth": "󰂯"
        };

        return iconMap[deviceIcon] || "󰂯";
    }
    Layout.fillWidth: true

    // Start discovering when component becomes visible
    onVisibleChanged: {
        if (visible && root.adapter?.enabled) {
            root.adapter.discovering = true;
        } else if (!visible && root.adapter) {
            root.adapter.discovering = false;
        }
    }
    
    // Missing adapter state
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: !root.adapter
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰂲"
                font.family: Config.iconFontFamily
                font.pixelSize: 48
                color: Qt.alpha(Config.foreground, 0.2)
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No Bluetooth Adapter Found"
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: Config.foreground
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        visible: !!root.adapter

        // Header with power toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "󰂯"
                font.family: Config.iconFontFamily
                font.pixelSize: 24
                color: root.adapter?.enabled ? Config.accent : Config.foreground
            }

            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.bold: true
                color: Config.foreground
            }

            // Scan button
            QuickButton {
                id: scanBtn
                size: 32
                icon: root.adapter?.discovering ? "󰑐" : "󰑏"
                visible: root.adapter?.enabled ?? false

                onClicked: {
                    if (root.adapter) {
                        root.adapter.discovering = !root.adapter.discovering;
                    }
                }
            }

            // Power toggle
            QuickButton {
                id: powerToggleBtn
                size: 32
                icon: root.adapter?.enabled ? "󱨥" : "󱨦"

                onClicked: {
                    if (root.adapter) {
                        root.adapter.enabled = !root.adapter.enabled;
                    }
                }

                KeyNavigation.down: deviceList.count > 0 ? deviceList.itemAtIndex(0) : null
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.foreground
            opacity: 0.2
        }

        // Status text when Bluetooth is off
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !(root.adapter?.enabled ?? false)
            text: "Bluetooth is disabled\nRight-click button to enable"
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Qt.alpha(Config.foreground, 0.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        // Device list
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.adapter?.enabled ?? false
            clip: true
            spacing: 5

            model: root.adapter?.devices ?? null

            delegate: Rectangle {
                id: deviceDelegate
                required property var modelData
                required property int index

                width: deviceList.width
                height: 50
                radius: Config.itemRadius
                color: deviceMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)

                // Keyboard focus
                activeFocusOnTab: true
                border.width: activeFocus ? 2 : 0
                border.color: Config.accent

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    // Device icon (using Nerd Font icons instead of system icons)
                    Text {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        font.family: Config.iconFontFamily
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: modelData.connected ? Config.accent : Config.foreground
                        text: getDeviceIcon(modelData.icon, modelData.connected)
                    }

                    // Device info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || "Unknown Device"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.bold: modelData.connected
                            color: modelData.connected ? Config.accent : Config.foreground
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 8

                            Text {
                                text: {
                                    switch (modelData.state) {
                                    case BluetoothDeviceState.Connected:
                                        return "Connected";
                                    case BluetoothDeviceState.Connecting:
                                        return "Connecting...";
                                    case BluetoothDeviceState.Disconnecting:
                                        return "Disconnecting...";
                                    default:
                                        return modelData.paired ? "Paired" : "Available";
                                    }
                                }
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: Qt.alpha(Config.foreground, 0.6)
                            }

                            // Battery indicator
                            Text {
                                visible: modelData.batteryAvailable
                                text: "󰁹 " + Math.round(modelData.battery * 100) + "%"
                                font.family: Config.iconFontFamily
                                font.pixelSize: 11
                                color: Qt.alpha(Config.foreground, 0.6)
                            }
                        }
                    }

                    // Connect/Disconnect button
                    QuickButton {
                        id: actionBtn
                        size: 32
                        icon: modelData.connected ? "󰂲" : "󰂱"
                        visible: modelData.paired
                        activeFocusOnTab: true

                        onClicked: {
                            if (modelData.connected) {
                                modelData.disconnect();
                            } else {
                                modelData.connect();
                            }
                        }

                        Keys.onLeftPressed: deviceDelegate.forceActiveFocus()
                        Keys.onRightPressed: {
                            if (root.menuButton) root.menuButton.forceActiveFocus();
                        }
                    }
                }

                MouseArea {
                    id: deviceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect();
                        } else {
                            modelData.connect();
                        }
                    }
                }

                // Keyboard handler
                Keys.onReturnPressed: {
                    if (modelData.connected) {
                        modelData.disconnect();
                    } else {
                        modelData.connect();
                    }
                }

                Keys.onUpPressed: {
                    if (index > 0) {
                        let prevItem = deviceList.itemAtIndex(index - 1);
                        if (prevItem) prevItem.forceActiveFocus();
                    } else {
                        powerToggleBtn.forceActiveFocus();
                    }
                }

                Keys.onDownPressed: {
                    if (index < deviceList.count - 1) {
                        let nextItem = deviceList.itemAtIndex(index + 1);
                        if (nextItem) nextItem.forceActiveFocus();
                    }
                }

                Keys.onRightPressed: {
                    if (root.menuButton) root.menuButton.forceActiveFocus();
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDurationFast
                    }
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0 && (root.adapter?.enabled ?? false)
                text: root.adapter?.discovering ? "Scanning for devices..." : "No devices found\nClick scan to search"
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: Qt.alpha(Config.foreground, 0.5)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
