import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../../../ui/panel"
import "../../../../config"

// Component for selecting the default Pipewire audio output device
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight
    
    // Dependency check
    property bool pipewireAvailable: false
    property bool dependencyChecked: false
    
    Process {
        id: pwCheck
        command: ["which", "pipewire"]
        onExited: (code) => {
            root.pipewireAvailable = (code === 0);
            root.dependencyChecked = true;
        }
    }
    
    Component.onCompleted: pwCheck.running = true

    // Track only valid sink nodes to avoid C++ errors on partial/monitor nodes
    PwObjectTracker {
        objects: {
            if (!root.pipewireAvailable) return [];
            var validNodes = [];
            var allNodes = Pipewire.nodes.values;
            for (var i = 0; i < allNodes.length; i++) {
                var node = allNodes[i];
                // Match the filter used in the Repeater below
                if (node && node.isSink && !node.isStream && node.audio !== null) {
                    validNodes.push(node);
                }
            }
            return validNodes;
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

        // Header
        Text {
            Layout.fillWidth: true
            text: "Audio Output"
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: Config.foreground
        }

        // Device list
        Repeater {
            // Filter for hardware audio sinks only
            model: {
                var devices = [];
                for (var i = 0; i < Pipewire.nodes.values.length; i++) {
                    var node = Pipewire.nodes.values[i];
                    if (node.isSink && !node.isStream && node.audio !== null) {
                        devices.push(node);
                    }
                }
                return devices;
            }

            delegate: Rectangle {
                id: deviceDelegate

                required property var modelData
                property bool isDefault: Pipewire.defaultAudioSink?.id === modelData.id

                Layout.fillWidth: true
                Layout.preferredHeight: 32

                radius: Config.itemRadius
                color: isDefault ? Qt.alpha(Config.accent, 0.3) : (mouseArea.containsMouse ? Qt.alpha(Config.foreground, 0.1) : "transparent")

                Behavior on color {
                    ColorAnimation { duration: Config.animDurationFast }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Device icon
                    Text {
                        text: deviceDelegate.isDefault ? "󰓃" : "󰓂"
                        font.pixelSize: 14
                        font.family: Config.iconFontFamily
                        color: deviceDelegate.isDefault ? Config.accent : Config.dimmed
                    }

                    // Device name
                    Text {
                        Layout.fillWidth: true
                        text: deviceDelegate.modelData.description || deviceDelegate.modelData.name
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        color: deviceDelegate.isDefault ? Config.foreground : Config.dimmed
                        elide: Text.ElideRight
                    }

                    // Check icon for default
                    Text {
                        visible: deviceDelegate.isDefault
                        text: "󰄬"
                        font.pixelSize: 12
                        font.family: Config.iconFontFamily
                        color: Config.accent
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (!deviceDelegate.isDefault) {
                            Pipewire.preferredDefaultAudioSink = deviceDelegate.modelData;
                        }
                    }
                }
            }
        }

        // Empty state
        Text {
            visible: {
                if (root.dependencyChecked && !root.pipewireAvailable) return true;
                
                for (var i = 0; i < Pipewire.nodes.values.length; i++) {
                    var node = Pipewire.nodes.values[i];
                    if (node.isSink && !node.isStream && node.audio !== null) {
                        return false;
                    }
                }
                return true;
            }
            Layout.fillWidth: true
            text: (!root.dependencyChecked || root.pipewireAvailable) ? "No audio devices found" : "Missing dependency: pipewire"
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: (!root.dependencyChecked || root.pipewireAvailable) ? Config.dimmed : Config.red
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
