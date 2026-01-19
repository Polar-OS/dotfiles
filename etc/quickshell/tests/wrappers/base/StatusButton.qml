import "."
import ".."
import QtQuick
import ".."

BaseButton {
    id: root

    property real fillPercentage: 0
    property color fillColor: Config.statusGood
    property string icon: ""
    property int iconPixelSize: 18

    // Override BaseButton defaults
    baseColor: Qt.alpha(Config.foreground, 0.06)
    
    implicitWidth: 40
    implicitHeight: 40

    // Progress Bar Fill
    Rectangle {
        id: fillRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        // Clamp height to parent
        height: parent.height * (Math.max(0, Math.min(100, root.fillPercentage)) / 100)
        radius: parent.radius
        
        // Match parent radius at bottom, but maybe flat at top if filling? 
        // Original code just said radius: parent.radius.
        
        color: root.fillColor
        opacity: 0.2
        border.width: 1
        border.color: root.fillColor
        
        Behavior on height {
            NumberAnimation {
                duration: Config.animationDurationSlow
                easing.type: Config.animEasingStandard
            }
        }
    }

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Config.iconFontFamily
        font.pixelSize: root.iconPixelSize
        color: Config.iconColor
        
        style: Text.Outline
        styleColor: Qt.rgba(Config.background.r, Config.background.g, Config.background.b, 0.5)
        visible: root.icon !== ""
    }
}
