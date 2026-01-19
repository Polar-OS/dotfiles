import "."
import ".."
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../config"

Scope {
    id: root

    property bool active: false
    property var model: []
    property Component delegate
    property int initialIndex: 0
    property string title: ""
    property int cardWidth: 150
    property int cardHeight: 84
    property int visibleItems: 5

    signal selected(var modelData)
    signal canceled()

    Variants {
        model: root.active ? Quickshell.screens : []

        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            color: "transparent"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            contentItem {
                focus: true
                Keys.onEscapePressed: root.canceled()
                Keys.onLeftPressed: carousel.decrementCurrentIndex()
                Keys.onRightPressed: carousel.incrementCurrentIndex()
                Keys.onReturnPressed: {
                    if (root.model.length > 0) {
                        root.selected(root.model[carousel.currentIndex])
                    }
                }
            }

            // Dark overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.8)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.canceled()
                }
            }

            // Container
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: carousel.cardHeight + 60

                CarouselView {
                    id: carousel
                    anchors.centerIn: parent
                    width: parent.width
                    
                    cardWidth: root.cardWidth
                    cardHeight: root.cardHeight
                    visibleItems: root.visibleItems

                    model: root.model
                    delegate: root.delegate
                    initialIndex: root.initialIndex
                    
                    onSelected: (data) => root.selected(data)
                }
            }
        }
    }
}
