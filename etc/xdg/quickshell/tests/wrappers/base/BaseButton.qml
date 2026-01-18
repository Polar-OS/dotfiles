import QtQuick
import ".."

Rectangle {
    id: root

    // === INTERFACE ===
    property bool active: false
    property bool hovered: mouseArea.containsMouse
    
    // Configurable visuals
    property color baseColor: Qt.alpha(Config.foreground, 0.1)
    property color activeColor: Config.foreground
    property color hoverColor: Qt.alpha(Config.foreground, 0.2) // slightly lighter
    
    signal clicked()
    signal rightClicked()

    // === STATE ===
    implicitWidth: Config.buttonSize
    implicitHeight: Config.buttonSize
    radius: Config.itemRadius
    
    property int clickMargin: 0
    property bool enableHoverEffect: true

    // Default color logic
    color: active ? activeColor : baseColor

    // Hover effect (Opacity based, matching original behavior)
    opacity: (enableHoverEffect && hovered) ? 0.8 : 1.0

    // === BEHAVIOR ===
    Behavior on color {
        ColorAnimation { duration: Config.animDurationFast }
    }
    
    Behavior on opacity {
        NumberAnimation { duration: Config.animDurationFast }
    }

    // === FOCUS ===
    activeFocusOnTab: true
    border.width: activeFocus ? 2 : 0
    border.color: Config.accent
    
    Behavior on border.width {
        NumberAnimation { duration: Config.animDurationFast }
    }

    // === INPUT ===
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: root.clickMargin
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            } else {
                root.clicked()
            }
        }
    }
    
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
}
