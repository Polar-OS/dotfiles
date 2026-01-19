import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../ui/layout"
import "../../../../ui/button"
import "../../../../ui/panel"
import "../../../../config"

ColumnLayout {
    id: root
    spacing: 6
    
    // For navigation entry from the right
    property alias firstButton: dummyButton
    
    // Memory data from MemoryIndicator
    property real memoryUsage: 0
    property real memTotal: 0
    property real memAvailable: 0
    property real memFree: 0
    property real buffers: 0
    property real cached: 0
    property real swapTotal: 0
    property real swapFree: 0

    // Helper function to format bytes (kB to human readable)
    function formatMemory(kbytes) {
        if (kbytes <= 0) return "--";
        var gb = kbytes / (1024 * 1024);
        if (gb >= 1) return gb.toFixed(1) + " GB";
        var mb = kbytes / 1024;
        return mb.toFixed(0) + " MB";
    }

    // Title
    PanelHeader {
        text: "Memory"
    }

    // Memory Icon & Usage
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 15

        Text {
            text: "󰆼"
            font.family: Config.iconFontFamily
            font.pixelSize: 32
            color: {
                if (root.memoryUsage >= 90) return Config.statusCritical;
                if (root.memoryUsage >= 70) return Config.statusWarning;
                return Config.foreground;
            }
        }

        ColumnLayout {
            spacing: 2
            
            Text {
                text: Math.round(root.memoryUsage) + "%"
                font.family: Config.fontFamily
                font.pixelSize: 20
                font.bold: true
                color: Config.foreground
            }
            
            Text {
                text: formatMemory(root.memTotal - root.memAvailable) + " / " + formatMemory(root.memTotal)
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Config.dimmed
            }
        }
    }

    // Usage bar
    UsageBar {
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        value: root.memoryUsage
        Layout.preferredHeight: 6
    }

    // Stats
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 2

        DetailRow { label: "Total:"; value: formatMemory(root.memTotal) }
        DetailRow { label: "Used:"; value: formatMemory(root.memTotal - root.memAvailable) }
        DetailRow { label: "Available:"; value: formatMemory(root.memAvailable) }
        DetailRow { label: "Free:"; value: formatMemory(root.memFree) }
        DetailRow { label: "Buffers / Cached:"; value: formatMemory(root.buffers) + " / " + formatMemory(root.cached) }
    }

    // Swap Section
    SectionSeparator {
        title: "Swap"
        visible: root.swapTotal > 0
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 6
        visible: root.swapTotal > 0

        // Swap bar
        UsageBar {
            value: root.swapTotal > 0 ? ((root.swapTotal - root.swapFree) / root.swapTotal) * 100 : 0
        }

        DetailRow { label: "Used / Total:"; value: formatMemory(root.swapTotal - root.swapFree) + " / " + formatMemory(root.swapTotal) }
    }

    // Dummy button for keyboard navigation (invisible)
    QuickButton {
        id: dummyButton
        visible: false
        size: 0
    }


}
