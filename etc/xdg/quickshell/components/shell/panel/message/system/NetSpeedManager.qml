import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../../ui/layout"
import "../../../../ui/button"
import Quickshell
import Quickshell.Io
import "../../../../ui/panel"
import "../../../../config"

ColumnLayout {
    id: root
    spacing: 6
    
    // For navigation entry from the right
    property alias firstButton: dummyButton
    
    // Network data from NetSpeedIndicator
    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property string activeInterface: ""
    
    // Extended stats
    property real totalRxBytes: 0
    property real totalTxBytes: 0
    property var interfaceList: []

    // Helper function to format bytes
    function formatBytes(bytes) {
        if (bytes <= 0) return "--";
        var gb = bytes / (1024 * 1024 * 1024);
        if (gb >= 1) return gb.toFixed(2) + " GB";
        var mb = bytes / (1024 * 1024);
        if (mb >= 1) return mb.toFixed(1) + " MB";
        var kb = bytes / 1024;
        return kb.toFixed(0) + " KB";
    }

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

    // Title
    PanelHeader {
        text: "Network"
    }

    // Speed Icons & Values
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 20

        // Upload (first)
        ColumnLayout {
            spacing: 2
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: "\u{f0aa}" // arrow up icon
                font.family: Config.iconFontFamily
                font.pixelSize: 24
                color: Config.statusWarning
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: formatSpeed(root.uploadSpeed)
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Config.foreground
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: "Upload"
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Config.dimmed
            }
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 40
            color: Config.foreground
            opacity: 0.2
        }

        // Download (second)
        ColumnLayout {
            spacing: 2
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: "\u{f0ab}" // arrow down icon
                font.family: Config.iconFontFamily
                font.pixelSize: 24
                color: Config.statusGood
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: formatSpeed(root.downloadSpeed)
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Config.foreground
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
                text: "Download"
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Config.dimmed
            }
        }
    }

    // Active Interface
    SectionSeparator {
        title: "Interface"
    }

    // Interface info
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 6

        DetailRow { label: "Active:"; value: root.activeInterface || "None" }
        DetailRow { label: "Total Downloaded:"; value: formatBytes(root.totalRxBytes) }
        DetailRow { label: "Total Uploaded:"; value: formatBytes(root.totalTxBytes) }
    }

    // Interfaces List
    SectionSeparator {
        title: "All Interfaces"
        visible: interfaceListView.count > 0
    }

    ListView {
        id: interfaceListView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 100)
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        model: root.interfaceList
        clip: true
        spacing: 4

        delegate: RowLayout {
            width: interfaceListView.width
            
            Text {
                text: modelData.name
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: modelData.name === root.activeInterface ? Config.accent : Config.dimmed
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "\u{f0045} " + formatBytes(modelData.rx)
                font.family: Config.iconFontFamily
                font.pixelSize: 11
                color: Config.foreground
            }
            
            Text {
                text: "\u{f0552} " + formatBytes(modelData.tx)
                font.family: Config.iconFontFamily
                font.pixelSize: 11
                color: Config.foreground
            }
        }
    }

    // Dummy button for keyboard navigation (invisible)
    QuickButton {
        id: dummyButton
        visible: false
        size: 0
    }



    // Read detailed network stats
    Process {
        id: netStatsProcess
        command: ["cat", "/proc/net/dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split('\n');
                let totalRx = 0;
                let totalTx = 0;
                let interfaces = [];
                
                for (let i = 2; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (!line) continue;
                    
                    let parts = line.split(/[:\s]+/).filter(x => x);
                    if (parts.length >= 10) {
                        let iface = parts[0];
                        if (iface === "lo") continue;
                        
                        let rxBytes = parseFloat(parts[1]) || 0;
                        let txBytes = parseFloat(parts[9]) || 0;
                        
                        if (rxBytes > 0 || txBytes > 0) {
                            interfaces.push({
                                name: iface,
                                rx: rxBytes,
                                tx: txBytes
                            });
                            totalRx += rxBytes;
                            totalTx += txBytes;
                        }
                    }
                }
                
                root.totalRxBytes = totalRx;
                root.totalTxBytes = totalTx;
                root.interfaceList = interfaces;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            netStatsProcess.running = true;
        }
    }

    Component.onCompleted: {
        netStatsProcess.running = true;
    }
}
