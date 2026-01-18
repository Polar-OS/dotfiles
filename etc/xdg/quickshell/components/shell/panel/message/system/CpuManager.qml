import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../ui/layout"
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../../ui/panel"
import "../system"
import "../../../../config"

ColumnLayout {
    id: root
    spacing: 6

    // For navigation entry from the right
    property alias firstButton: powerProfiles.lastButton
    
    property real cpuUsage: 0
    property bool profilesAvailable: typeof PowerProfiles !== "undefined"
    
    property var coreModel

    // Title
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 0
        text: "CPU"
        font.family: Config.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Config.foreground
    }

    property var usageHistory: new Array(60).fill(0)
    
    onCpuUsageChanged: {
        var hist = root.usageHistory.concat([]);
        hist.push(root.cpuUsage);
        if (hist.length > 60) {
            hist.shift();
        }
        root.usageHistory = hist;
    }

    // Graph Container
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        
        // Background
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Config.foreground, 0.05)
            radius: Config.radius
        }

        Canvas {
            id: cpuGraph
            anchors.fill: parent
            anchors.margins: 10
            
            property var dataPoints: root.usageHistory
            property color strokeColor: {
                var last = dataPoints.length > 0 ? dataPoints[dataPoints.length - 1] : 0;
                if (last >= 80) return Config.statusCritical;
                if (last >= 50) return Config.statusWarning;
                return Config.statusGood;
            }
            
            onDataPointsChanged: requestPaint()
            onStrokeColorChanged: requestPaint()
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                if (dataPoints.length === 0) return;
                
                var w = width;
                var h = height;
                var maxPoints = 60;
                var step = w / (maxPoints - 1);
                
                // Draw Line
                ctx.beginPath();
                ctx.lineWidth = 2;
                ctx.strokeStyle = strokeColor;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                
                for (var i = 0; i < dataPoints.length; i++) {
                    var x = i * step;
                    var y = h - (dataPoints[i] / 100.0 * h);
                    
                    if (i === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                }
                ctx.stroke();
                
                // Fill Gradient
                if (dataPoints.length > 0) {
                    var lastX = (dataPoints.length - 1) * step;
                    ctx.lineTo(lastX, h);
                    ctx.lineTo(0, h);
                    ctx.closePath();
                    
                    var gradient = ctx.createLinearGradient(0, 0, 0, h);
                    gradient.addColorStop(0, Qt.alpha(strokeColor, 0.4));
                    gradient.addColorStop(1, Qt.alpha(strokeColor, 0.05));
                    ctx.fillStyle = gradient;
                    ctx.fill();
                }
            }
        }
    }

    // CPU Info
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 4
        
        DetailRow {
            label: "Model:"
            value: {
                // Parse model name from /proc/cpuinfo
                var txt = cpuInfoFile.text();
                if (!txt) return "Unknown";
                var lines = txt.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].includes("model name")) {
                        var parts = lines[i].split(":");
                        if (parts.length > 1)
                            return parts[1].trim();
                    }
                }
                return "Unknown";
            }
        }
        
        Item { height: 4; width: 1 }
        
        DetailRow {
            label: "Frequency:"
            value: {
                var freqText = freqFile.text();
                var freq = parseFloat(freqText) || 0;
                if (freq > 1000000) return (freq / 1000000).toFixed(2) + " GHz";
                if (freq > 1000) return (freq / 1000).toFixed(0) + " MHz";
                return freq + " kHz";
            }
        }
        
        DetailRow {
            label: "Cores:"
            value: root.coreModel ? root.coreModel.count : "--"
        }
    }
    
    FileView {
        id: cpuInfoFile
        path: "/proc/cpuinfo"
    }
    
    FileView {
        id: freqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    }

    // Power Profiles
    PowerProfilesController {
        id: powerProfiles
        visible: profilesAvailable
    }


}
