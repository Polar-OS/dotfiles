import "."
import QtQuick
import QtQuick.Layouts
import ".." // For Config

RowLayout {
    Layout.fillWidth: true
    
    property string label: ""
    property string value: ""
    
    Text {
        text: parent.label
        color: Config.dimmed
        font.pixelSize: 13
        font.family: Config.fontFamily
    }

    Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        text: parent.value
        color: Config.foreground
        font.pixelSize: 13
        font.bold: true
        font.family: Config.fontFamily
        elide: Text.ElideMiddle
    }
}
