import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower 1.0
import "../../../ui/indicators" // BaseIndicator
import ".."
import "../base"

BaseIndicator {
    id: root

    property int percentage: UPower.displayDevice.percentage * 100
    property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging

    // Power profile support (optional - only if PowerProfiles module is available)
    property bool powerProfilesAvailable: typeof PowerProfiles !== "undefined"
    property int powerProfile: powerProfilesAvailable ? PowerProfiles.profile : 0

    function getBatteryColor() {
        if (root.percentage <= 10)
            return Config.statusCritical;
        if (root.percentage <= 20)
            return Config.statusWarning;
        if (root.percentage <= 50)
            return Config.statusMedium;
        return Config.accent;
    }

    function getBatteryIcon() {
        var p = root.percentage / 100.0;
        if (root.charging) {
            // Charging icons by level
            if (p <= 0.1) return "󰢜";
            if (p <= 0.2) return "󰂆";
            if (p <= 0.3) return "󰂇";
            if (p <= 0.4) return "󰂈";
            if (p <= 0.5) return "󰢝";
            if (p <= 0.6) return "󰂉";
            if (p <= 0.7) return "󰢞";
            if (p <= 0.8) return "󰂊";
            if (p <= 0.9) return "󰂋";
            return "󰂅";
        }
        // Discharging icons by level
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

    // BaseIndicator config
    fillPercentage: root.percentage
    fillColor: root.charging ? Config.accent : getBatteryColor()
    icon: getBatteryIcon()
    iconPixelSize: 18
}
