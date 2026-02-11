import "."
import QtQuick
import QtQuick.Layouts
import ".." // For Config

Text {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 0
    font.family: Config.fontFamily
    font.pixelSize: 16
    font.bold: true
    color: Config.foreground
}
