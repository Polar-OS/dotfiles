import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../ui/indicators" // BaseIndicator
import "../../../config"
import "../../../ui/panel"

BaseIndicator {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string currentNetwork: ""
    property int signalStrength: 0
    
    // Dependency checking
    property bool nmcliAvailable: false
    property bool dependencyChecked: false

    signal showRequested
    
    // Hide if nmcli not available
    visible: !dependencyChecked || nmcliAvailable

    // BaseIndicator config
    fillPercentage: 0
    // Icon logic binding
    icon: getWifiIcon()
    iconPixelSize: 18

    // Right-click to toggle WiFi
    onRightClicked: toggleWifi()

    // Control+Enter to toggle WiFi
    Keys.onReturnPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            root.toggleWifi();
        } else {
            root.extendRequested();
            root.clicked();
        }
    }

    Component.onCompleted: {
        nmcliCheckProcess.running = true;
    }

    // Check if nmcli is available
    Process {
        id: nmcliCheckProcess
        command: ["which", "nmcli"]
        onExited: (code) => {
            root.nmcliAvailable = (code === 0);
            root.dependencyChecked = true;
            if (root.nmcliAvailable) {
                checkWifiStatus.running = true;
            }
        }
    }

    // Update icon when WiFi status changes
    // Removed explicit update calls since we bind directly to getWifiIcon()
    // which depends on connected, signalStrength, etc.
    
    function getWifiIcon() {
        if (!root.connected)
            return "󰤯"; // Not connected - WiFi crossed out
        if (root.signalStrength >= 75)
            return "󰤨"; // Excellent signal
        if (root.signalStrength >= 50)
            return "󰤥"; // Good signal
        if (root.signalStrength >= 25)
            return "󰤢"; // Fair signal
        return "󰤟"; // Weak signal
    }

    function toggleWifi() {
        toggleWifiProcess.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        toggleWifiProcess.running = true;
    }

    // Check WiFi status periodically
    Process {
        id: checkWifiStatus
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = data.trim() === "enabled";
                if (root.wifiEnabled) {
                    checkConnection.running = true;
                } else {
                    root.connected = false;
                    root.currentNetwork = "";
                    root.signalStrength = 0;
                }
            }
        }
    }

    // Check current connection
    Process {
        id: checkConnection
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        running: false

        property string accumulatedData: ""

        stdout: SplitParser {
            onRead: data => checkConnection.accumulatedData += data + "\n"
        }

        onRunningChanged: {
            if (!running) {
                let lines = checkConnection.accumulatedData.trim().split('\n');
                let isConnected = false;

                for (let line of lines) {
                    if (!line) continue;
                    let parts = line.split(':');
                    if (parts.length >= 3 && parts[1] === "802-11-wireless") {
                        isConnected = true;
                        root.currentNetwork = parts[0];
                        break;
                    }
                }

                root.connected = isConnected;

                if (isConnected) {
                    checkSignal.running = true;
                } else {
                    root.signalStrength = 0;
                    root.currentNetwork = "";
                }
                checkConnection.accumulatedData = "";
            }
        }
    }

    // Check signal strength
    Process {
        id: checkSignal
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split('\n');
                for (let line of lines) {
                    if (line.startsWith('*:')) {
                        let parts = line.split(':');
                        if (parts.length >= 2) {
                            root.signalStrength = parseInt(parts[1]) || 0;
                        }
                        break;
                    }
                }
            }
        }
    }

    // Toggle WiFi
    Process {
        id: toggleWifiProcess
        running: false

        onRunningChanged: {
            if (!running) {
                statusTimer.restart();
            }
        }
    }

    // Periodic status update
    Timer {
        id: statusTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: checkWifiStatus.running = true
    }
}
