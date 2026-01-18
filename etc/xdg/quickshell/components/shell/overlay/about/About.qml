import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../ui/shell" // OverlayWindow
import "../../../config"

OverlayWindow {
    id: root
    active: false
    windowWidth: 900
    windowHeight: 520

    property var systemInfo: ({})
    property string collectedInfo: ""

    Process {
        id: infoCollector
        command: ["sh", "-c", "echo \"HOSTNAME=$(hostnamectl hostname 2>/dev/null || hostname)\"; echo \"OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'\"' -f2)\"; echo \"KERNEL=$(uname -r)\"; echo \"UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')\"; echo \"CPU=$(lscpu 2>/dev/null | grep 'Model name' | cut -d':' -f2 | xargs)\"; echo \"CORES=$(nproc)\"; echo \"RAM=$(free -h 2>/dev/null | awk '/Mem:/ {print $3 \"/\" $2}')\"; echo \"GPU=$(lspci 2>/dev/null | grep -i vga | cut -d':' -f3 | xargs | head -c 50)\"; echo \"DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 \"/\" $2}')\"; echo \"DE=Niri + Quickshell\"; echo \"USER=$USER\""]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root.collectedInfo += data; }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                var info = {};
                var lines = root.collectedInfo.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("=");
                    if (parts.length >= 2) {
                        info[parts[0]] = parts.slice(1).join("=");
                    }
                }
                root.systemInfo = info;
                root.collectedInfo = "";
            }
        }
    }

    onActiveChanged: {
        if (active) infoCollector.running = true
    }

    view: ColumnLayout {
        id: mainContent
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰋽"
            font.family: Config.iconFontFamily
            font.pixelSize: 48
            color: Config.accent
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.systemInfo.HOSTNAME || "System"
            font.family: Config.fontFamily
            font.pixelSize: 24
            font.bold: true
            color: Config.foreground
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Config.foreground, 0.1)
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 20

            InfoRow { icon: "󰣇"; label: "OS"; value: root.systemInfo.OS || "N/A" }
            InfoRow { icon: ""; label: "Kernel"; value: root.systemInfo.KERNEL || "N/A" }
            InfoRow { icon: "󰍛"; label: "CPU"; value: root.systemInfo.CPU || "N/A" }
            InfoRow { icon: "󰘚"; label: "Cores"; value: root.systemInfo.CORES || "N/A" }
            InfoRow { icon: "󰑭"; label: "RAM"; value: root.systemInfo.RAM || "N/A" }
            InfoRow { icon: "󰋩"; label: "GPU"; value: root.systemInfo.GPU || "N/A" }
            InfoRow { icon: "󰋊"; label: "Disk"; value: root.systemInfo.DISK || "N/A" }
            InfoRow { icon: "󰅐"; label: "Uptime"; value: root.systemInfo.UPTIME || "N/A" }
            InfoRow { icon: "󰖲"; label: "DE"; value: root.systemInfo.DE || "N/A" }
            InfoRow { icon: "󰀄"; label: "User"; value: root.systemInfo.USER || "N/A" }
        }
    }

    component InfoRow: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: icon
            font.family: Config.iconFontFamily
            font.pixelSize: 16
            color: Config.accent
            Layout.preferredWidth: 24
        }

        Text {
            text: label
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.dimmed
            Layout.preferredWidth: 60
        }

        Text {
            text: value
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.foreground
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
