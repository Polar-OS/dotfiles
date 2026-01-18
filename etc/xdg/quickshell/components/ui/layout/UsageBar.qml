import "."
import QtQuick
import QtQuick.Layouts
import "../../config" // For Config

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 8
    radius: Config.itemRadius
    color: Qt.alpha(Config.foreground, 0.1)
    
    property real value: 0 // 0 to 100
    property color barColor: {
        if (value >= 90) return Config.statusCritical;
        if (value >= 70) return Config.statusWarning;
        if (value >= 50) return Config.statusMedium;
        return Config.statusGood;
    }
    
    Rectangle {
        height: parent.height
        width: parent.width * (Math.min(100, Math.max(0, root.value)) / 100.0)
        radius: Config.itemRadius
        color: root.barColor
        
        Behavior on width {
            NumberAnimation { duration: Config.animDurationRegular }
        }
    }
}
