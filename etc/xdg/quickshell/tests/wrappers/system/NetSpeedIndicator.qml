import QtQuick
import QtQuick.Layouts
import Quickshell.Io 1.0
import "../../../../ui/button"
import ".."
import "../base"

FocusScope {
    id: root

    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second
    property string activeInterface: ""
    
    // Previous values for delta calculation
    property real prevRxBytes: 0
    property real prevTxBytes: 0
    property bool initialized: false

    signal extendRequested
    signal clicked

    implicitWidth: 32
    implicitHeight: 32

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // Keyboard focus support
    activeFocusOnTab: true

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
        } else if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        }
        return bytesPerSec.toFixed(0) + " B/s";
    }

    function getSpeedColor() {
        var totalSpeed = root.downloadSpeed + root.uploadSpeed;
        // Color based on activity level
        if (totalSpeed >= 10 * 1024 * 1024) // >= 10 MB/s
            return Config.statusCritical;
        if (totalSpeed >= 1 * 1024 * 1024)  // >= 1 MB/s
            return Config.statusWarning;
        if (totalSpeed >= 100 * 1024)       // >= 100 KB/s
            return Config.statusMedium;
        return Config.statusGood;
    }

    // Calculate usage percentage for visual indicator (0-100)
    // Based on a reasonable max of 100 MB/s
    function getUsagePercentage() {
        var totalSpeed = root.downloadSpeed + root.uploadSpeed;
        var maxSpeed = 100 * 1024 * 1024; // 100 MB/s as reference max
        return Math.min(100, (totalSpeed / maxSpeed) * 100);
    }

    StatusButton {
        id: statusBtn
        anchors.fill: parent
        focus: true

        fillPercentage: getUsagePercentage()
        fillColor: getSpeedColor()
        icon: "\u{f0552}" // network icon
        iconPixelSize: 18

        // Forward focus state to button
        border.width: root.activeFocus ? 2 : 0
        border.color: Config.accent

        onClicked: {
            root.extendRequested();
            root.clicked();
        }
    }

    // Keyboard handlers
    Keys.onReturnPressed: {
        root.extendRequested();
        root.clicked();
    }
    Keys.onSpacePressed: {
        root.extendRequested();
        root.clicked();
    }

    // Read network stats from /proc/net/dev
    Process {
        id: netProcess
        command: ["cat", "/proc/net/dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split('\n');
                let totalRx = 0;
                let totalTx = 0;
                let foundInterface = "";
                
                for (let i = 2; i < lines.length; i++) { // Skip header lines
                    let line = lines[i].trim();
                    if (!line) continue;
                    
                    let parts = line.split(/[:\s]+/).filter(x => x);
                    if (parts.length >= 10) {
                        let iface = parts[0];
                        // Skip loopback
                        if (iface === "lo") continue;
                        
                        let rxBytes = parseFloat(parts[1]) || 0;
                        let txBytes = parseFloat(parts[9]) || 0;
                        
                        // Use interface with traffic or first non-lo interface
                        if (rxBytes > 0 || txBytes > 0) {
                            totalRx += rxBytes;
                            totalTx += txBytes;
                            if (!foundInterface) foundInterface = iface;
                        }
                    }
                }
                
                if (root.initialized) {
                    let deltaRx = totalRx - root.prevRxBytes;
                    let deltaTx = totalTx - root.prevTxBytes;
                    
                    // Divide by interval (1 second)
                    root.downloadSpeed = Math.max(0, deltaRx);
                    root.uploadSpeed = Math.max(0, deltaTx);
                }
                
                root.prevRxBytes = totalRx;
                root.prevTxBytes = totalTx;
                root.activeInterface = foundInterface;
                root.initialized = true;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            netProcess.running = true;
        }
    }

    Component.onCompleted: {
        netProcess.running = true;
    }
}
