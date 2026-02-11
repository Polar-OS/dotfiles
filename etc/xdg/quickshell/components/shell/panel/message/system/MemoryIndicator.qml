import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../../ui/button"
import "../../../../config"
import "../../../../ui/panel"

FocusScope {
    id: root

    property real memoryUsage: 0
    property real memTotal: 0
    property real memAvailable: 0
    property real memFree: 0
    property real buffers: 0
    property real cached: 0
    property real swapTotal: 0
    property real swapFree: 0

    signal extendRequested
    signal clicked

    implicitWidth: 32
    implicitHeight: 32

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // Keyboard focus support
    activeFocusOnTab: true

    function getMemoryColor() {
        if (root.memoryUsage >= 90)
            return Config.statusCritical;
        if (root.memoryUsage >= 70)
            return Config.statusWarning;
        if (root.memoryUsage >= 50)
            return Config.statusMedium;
        return Config.statusGood;
    }

    StatusButton {
        id: statusBtn
        anchors.fill: parent
        focus: true

        fillPercentage: root.memoryUsage
        fillColor: getMemoryColor()
        icon: "󰆼"
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

    Process {
        id: memProcess
        command: ["cat", "/proc/meminfo"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split('\n');
                let values = {};
                
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(/:\s+/);
                    if (parts.length >= 2) {
                        let key = parts[0];
                        let val = parseFloat(parts[1].split(/\s+/)[0]) || 0;
                        values[key] = val;
                    }
                }
                
                root.memTotal = values["MemTotal"] || 0;
                root.memFree = values["MemFree"] || 0;
                root.memAvailable = values["MemAvailable"] || 0;
                root.buffers = values["Buffers"] || 0;
                root.cached = values["Cached"] || 0;
                root.swapTotal = values["SwapTotal"] || 0;
                root.swapFree = values["SwapFree"] || 0;
                
                // Calculate usage percentage (used = total - available)
                if (root.memTotal > 0) {
                    let used = root.memTotal - root.memAvailable;
                    root.memoryUsage = Math.min(100, Math.max(0, (used / root.memTotal) * 100));
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            memProcess.running = true;
        }
    }

    Component.onCompleted: {
        memProcess.running = true;
    }
}
