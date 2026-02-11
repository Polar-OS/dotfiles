import "."
import QtQuick
import QtQuick.Effects
import Quickshell
import ".."

Item {
    id: root

    property var model: []
    property Component delegate
    property int initialIndex: 0
    
    signal selected(var modelData)
    
    // Style props
    property int cardWidth: 150
    property int cardHeight: 84
    property int itemPadding: 30
    
    // Scale properties
    property real sideScale: 0.85 
    property real selectedScale: 1.0 // Allows overriding default (e.g. 1.1)
    
    // Allow customizing how many items fit
    property int visibleItems: 5

    // Calculated item width including padding
    // We want the current item to take full cardWidth
    // Side items are scaled down, but we allocate space based on scaled size?
    // PathView distributes items evenly along path.
    // If we want spacing, we need to ensure the path length is sufficient.
    
    // Let's assume we want tighter spacing.
    readonly property int itemWidth: Math.round(cardWidth * sideScale) + itemPadding * 2

    // Expose common API
    property alias currentIndex: pathView.currentIndex
    property alias count: pathView.count
    function incrementCurrentIndex() { pathView.incrementCurrentIndex() }
    function decrementCurrentIndex() { pathView.decrementCurrentIndex() }

    // Sync initial index
    onInitialIndexChanged: {
        if (model.length > 0) {
            pathView.currentIndex = initialIndex
        }
    }

    PathView {
        id: pathView
        anchors.centerIn: parent
        
        // Strictly fit parent
        width: parent.width
        height: parent.height
        clip: false

        model: root.model

        pathItemCount: root.visibleItems + 2
        cacheItemCount: 4

        snapMode: PathView.SnapToItem
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        
        // Smoother movement
        highlightMoveDuration: 300

        delegate: Item {
            id: delegateRoot
            
            required property int index
            required property var modelData
            
            // Expose status for easier binding
            readonly property bool isCurrent: PathView.isCurrentItem

            // Scale logic
            scale: PathView.isCurrentItem ? root.selectedScale : (PathView.onPath ? root.sideScale : 0)
            opacity: PathView.onPath ? (PathView.isCurrentItem ? 1 : 0.6) : 0
            z: PathView.isCurrentItem ? 100 : 1

            Behavior on scale { NumberAnimation { duration: Config.animDurationRegular; easing.type: Config.animEasingStandard } }
            Behavior on opacity { NumberAnimation { duration: Config.animDurationRegular } }

            // Size is fixed to full size
            implicitWidth: root.cardWidth
            implicitHeight: root.cardHeight

            // Shadow (Common)
            Rectangle {
                anchors.centerIn: parent
                width: root.cardWidth
                height: root.cardHeight
                anchors.margins: -4
                radius: Config.radius + 3
                color: "transparent"
                
                opacity: delegateRoot.PathView.isCurrentItem ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Config.animDurationRegular } }
                
                layer.enabled: delegateRoot.PathView.isCurrentItem
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.8
                    shadowColor: Config.shadow
                    shadowVerticalOffset: 4
                }
            }

            // Actual Delegate Content
            Loader {
                id: loader
                anchors.centerIn: parent
                width: root.cardWidth
                height: root.cardHeight
                
                sourceComponent: root.delegate
                
                Binding {
                    target: loader.item
                    property: "modelData"
                    value: delegateRoot.modelData
                    when: loader.status === Loader.Ready
                }
                
                Binding {
                    target: loader.item
                    property: "index"
                    value: delegateRoot.index
                    when: loader.status === Loader.Ready
                }
                
                Binding {
                    target: loader.item
                    property: "isCurrentItem"
                    value: delegateRoot.isCurrent
                    when: loader.status === Loader.Ready
                }
            }
            
            // Click handler
            MouseArea {
                anchors.centerIn: parent
                width: root.cardWidth
                height: root.cardHeight
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pathView.currentIndex = delegateRoot.index
                    root.selected(delegateRoot.modelData)
                }
            }
        }

        path: Path {
            startX: -root.cardWidth / 2
            startY: pathView.height / 2

            PathAttribute { name: "z"; value: 0 }

            PathLine {
                x: pathView.width / 2
                y: pathView.height / 2
            }

            PathAttribute { name: "z"; value: 100 }

            PathLine {
                x: pathView.width + root.cardWidth / 2
                y: pathView.height / 2
            }
        }
    }
}
