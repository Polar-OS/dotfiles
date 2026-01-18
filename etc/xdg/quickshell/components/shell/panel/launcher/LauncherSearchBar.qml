import QtQuick
import QtQuick.Layouts
import "../../../config"

Rectangle {
    id: root
    
    // signal textChanged(string text) -- Removed to avoid conflict with property alias signal
    signal accepted()
    signal upPressed()
    signal downPressed()
    
    property alias text: input.text
    property alias inputFocus: input.focus

    Layout.fillWidth: true
    Layout.preferredHeight: 50
    color: Qt.alpha(Config.foreground, 0.1)
    radius: Config.itemRadius
    border.color: input.activeFocus ? Config.foreground : "transparent"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        TextInput {
            id: input
            Layout.fillWidth: true
            text: ""
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: 16
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            
            // onTextChanged handled by alias
            onAccepted: root.accepted()
            
            Keys.onUpPressed: root.upPressed()
            Keys.onDownPressed: root.downPressed()
            
            // Fix: ensure the input always accepts focus
            focus: true
        }
    }
}
