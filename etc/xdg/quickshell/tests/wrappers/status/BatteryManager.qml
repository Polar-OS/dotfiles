import QtQuick
import QtQuick.Layouts
import Quickshell 1.0
import "../../../ui/layout"
import Quickshell.Io 1.0
import Quickshell.Services.UPower 1.0
import "../base"
import "../message/system"
import ".."

ColumnLayout {
    id: root
    spacing: 16
    
    // Alias to the button closest to the status bar (Right-most) for correct navigation entry
    property alias firstButton: powerProfiles.lastButton

    property var displayDevice: UPower.displayDevice
    property bool profilesAvailable: typeof PowerProfiles !== "undefined"
    
    // Title
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        text: "Battery"
        font.family: Config.fontFamily
        font.pixelSize: 18
        font.bold: true
        color: Config.foreground
    }

    // Battery Icon & Percentage
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 15

        Text {
            text: {
                if (!displayDevice) return "󰂃";
                if (displayDevice.state === UPowerDeviceState.Charging) return "󰂄";
                
                var p = displayDevice.percentage;
                if (p <= 0.1) return "󰁺";
                if (p <= 0.2) return "󰁻";
                if (p <= 0.3) return "󰁼";
                if (p <= 0.4) return "󰁽";
                if (p <= 0.5) return "󰁾";
                if (p <= 0.6) return "󰁿";
                if (p <= 0.7) return "󰂀";
                if (p <= 0.8) return "󰂁";
                if (p <= 0.9) return "󰂂";
                return "󰁹";
            }
            font.family: Config.iconFontFamily
            font.pixelSize: 48
            color: {
                 if (!displayDevice) return Config.dimmed;
                 if (displayDevice.state === UPowerDeviceState.Charging) return Config.statusGood;
                 if (displayDevice.percentage <= 0.2) return Config.statusCritical;
                 return Config.foreground;
            }
        }

        ColumnLayout {
            spacing: 2
            
            Text {
                text: displayDevice ? Math.round(displayDevice.percentage * 100) + "%" : "--%"
                font.family: Config.fontFamily
                font.pixelSize: 24
                font.bold: true
                color: Config.foreground
            }
            
            Text {
                text: {
                    if (!displayDevice) return "Unknown";
                    switch (displayDevice.state) {
                        case UPowerDeviceState.Charging: return "Charging";
                        case UPowerDeviceState.Discharging: return "Discharging";
                        case UPowerDeviceState.FullyCharged: return "Fully Charged";
                        case UPowerDeviceState.Empty: return "Empty";
                        case UPowerDeviceState.PendingCharge: return "Pending Charge";
                        case UPowerDeviceState.PendingDischarge: return "Pending Discharge";
                        default: return "Unknown";
                    }
                }
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Config.dimmed
            }
            
            Text {
                text: displayDevice ? displayDevice.model : ""
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Config.dimmed
                visible: displayDevice && displayDevice.model !== ""
            }
        }
    }

    // Stats
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 6

        // Time remaining
        DetailRow {
            visible: displayDevice && displayDevice.state !== UPowerDeviceState.FullyCharged
            label: (displayDevice && displayDevice.state === UPowerDeviceState.Charging) ? "Time to full:" : "Time to empty:"
            value: {
                if (!displayDevice) return "--";
                var s = displayDevice.state === UPowerDeviceState.Charging 
                      ? displayDevice.timeToFull 
                      : displayDevice.timeToEmpty;
                if (s <= 0) return "--";
                var h = Math.floor(s / 3600);
                var m = Math.floor((s % 3600) / 60);
                return h + "h " + m + "m";
            }
        }

        // Rate
        DetailRow {
            visible: !!displayDevice
            label: "Power Draw:"
            value: {
                if (!displayDevice) return "-- W";
                // Using changeRate from Quickshell API
                var rate = Math.abs(displayDevice.changeRate || 0);
                return rate.toFixed(1) + " W";
            }
        }
        
        // Capacity / Health
        DetailRow {
            visible: displayDevice && displayDevice.healthSupported
            label: "Capacity / Health:"
            value: {
                if (!displayDevice) return "--";
                var capacity = displayDevice.energyCapacity ? displayDevice.energyCapacity.toFixed(1) + "Wh" : "--";
                var health = displayDevice.healthPercentage ? Math.round(displayDevice.healthPercentage * 100) + "%" : "--";
                return capacity + " (" + health + ")";
            }
        }
    }

    // Power Profiles
    PowerProfilesController {
        id: powerProfiles
        visible: profilesAvailable
    }
    
    // Warning if UPower seems missing (heuristic)
    Text {
        visible: !displayDevice && !profilesAvailable
        Layout.alignment: Qt.AlignHCenter
        text: "UPower service unreachable"
        font.family: Config.fontFamily
        font.pixelSize: 12
        color: Config.statusWarning
    }

    Item { Layout.fillHeight: true } 
}
