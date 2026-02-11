import QtQuick
import ".."

Rectangle {
    id: root

    property bool active: false
    property real progress: 0
    property alias content: contentItem.data
    
    // Sync opacity with panel expansion/contraction
    // Use a behavior for smooth transitions between different extended panels
    opacity: active ? progress : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animationDurationFast || 200
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: Config.panelWidth
    implicitHeight: parent.height - Config.padding * 2

    // Position relative to the LEFT edge of the panel (which moves as panel expands)
    x: Config.padding
    anchors.verticalCenter: parent.verticalCenter
    width: implicitWidth
    height: implicitHeight

    color: Qt.rgba(0, 0, 0, 0.2)
    radius: Config.itemRadius
    clip: true
    layer.enabled: true

    // Content Wrapper
    Item {
        id: contentItem
        anchors.fill: parent
    }
}
