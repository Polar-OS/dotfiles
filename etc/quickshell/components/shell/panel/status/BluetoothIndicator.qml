import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../../ui/button"
import "../../../config"
import "../../../ui/panel"

FocusScope {
    id: root

    property bool powered: Bluetooth.defaultAdapter?.enabled ?? false
    property int connectedCount: {
        let count = 0;
        if (Bluetooth.devices) {
            for (let i = 0; i < Bluetooth.devices.count; i++) {
                if (Bluetooth.devices.get(i).connected)
                    count++;
            }
        }
        return count;
    }

    signal showRequested
    signal clicked
    signal extendRequested

    implicitWidth: 40
    implicitHeight: 40

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    
    // Hide if no bluetooth adapter found
    visible: Bluetooth.defaultAdapter !== null

    // Keyboard focus support
    activeFocusOnTab: true

    function getBluetoothIcon() {
        if (!root.powered)
            return "󰂲"; // Bluetooth off
        if (root.connectedCount > 0)
            return "󰂱"; // Bluetooth connected
        return "󰂯"; // Bluetooth on
    }

    function getBluetoothColor() {
        if (!root.powered)
            return Config.foreground;
        if (root.connectedCount > 0)
            return Config.accent;
        return Config.statusGood;
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }

    StatusButton {
        id: statusBtn
        anchors.fill: parent
        focus: true

        fillPercentage: 0
        icon: getBluetoothIcon()
        iconPixelSize: 18

        // Forward focus state to button
        border.width: root.activeFocus ? 2 : 0
        border.color: Config.accent

        // Left-click: extend panel to show device manager
        onClicked: {
            root.extendRequested();
            root.clicked();
        }

        // Right-click: toggle Bluetooth on/off
        onRightClicked: {
            root.toggleBluetooth();
        }
    }

    // Indicator dot when devices are connected
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        width: 6
        height: 6
        radius: Config.itemRadius
        color: Config.accent
        visible: root.connectedCount > 0
    }

    // Keyboard handlers - Enter/Space opens extended, Ctrl+Enter toggles power
    Keys.onReturnPressed: event => {
        if (event.modifiers & Qt.ControlModifier) {
            root.toggleBluetooth();
        } else {
            root.extendRequested();
            root.clicked();
        }
    }
    Keys.onSpacePressed: {
        root.extendRequested();
        root.clicked();
    }
}
