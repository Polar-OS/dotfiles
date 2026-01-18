import QtQuick
import ".."
import ".."
import "."

BaseButton {
    id: root

    property string icon: ""
    property string activeIcon: ""
    property int size: Config.buttonSize
    
    // Override implicit sizes with the 'size' property
    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.active && root.activeIcon !== "" ? root.activeIcon : root.icon
        // Inverted colors when active
        color: root.active ? Config.background : Config.foreground
        font.family: Config.iconFontFamily
        font.pixelSize: Config.iconSize
    }
}
