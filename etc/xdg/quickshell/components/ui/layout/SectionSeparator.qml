import "."
import QtQuick
import QtQuick.Layouts
import "../../config" // For Config

ColumnLayout {
    Layout.fillWidth: true
    spacing: 5
    
    property string title: ""
    
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Config.foreground
        opacity: 0.1
        Layout.topMargin: 5
        Layout.bottomMargin: 5
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: parent.title
        font.family: Config.fontFamily
        font.pixelSize: 14
        font.bold: true
        color: Config.foreground
        visible: text !== ""
    }
}
