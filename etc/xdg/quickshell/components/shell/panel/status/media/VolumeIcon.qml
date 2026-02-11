import QtQuick
import "../../../../ui/panel"
import "../../../../config"
import "../../../../ui/button"

BaseButton {
    id: root

    property real volume: 0
    property bool muted: false
    property int pixelSize: 18
    
    // Match original behavior
    clickMargin: -10
    enableHoverEffect: false
    baseColor: "transparent"
    activeColor: "transparent"

    signal toggled()
    onClicked: toggled()

    implicitWidth: 40
    implicitHeight: 30

    Text {
        anchors.centerIn: parent
        text: {
            if (root.muted || root.volume === 0)
                return "󰝟";
            var vol = root.volume * 100;
            if (vol < 33)
                return "󰕿";
            if (vol < 66)
                return "󰖀";
            return "󰕾";
        }
        font.pixelSize: root.pixelSize
        color: Config.foreground
        font.family: Config.iconFontFamily
    }
}
