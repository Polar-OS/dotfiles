import QtQuick
import QtQuick.Shapes
import ".."

// Inverted rounded corner for screen borders
Item {
    id: root

    implicitWidth: size
    implicitHeight: size

    property color cornerColor: "black"
    property int size: Config.panelCornerRadius
    property real curveRadius: size
    property real cornerRotation: 0

    rotation: root.cornerRotation
    transformOrigin: Item.Center

    Shape {
        anchors.fill: parent
        // Use layer for antialiasing
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.cornerColor

            // Start at Top-Left (Solid Corner)
            startX: 0
            startY: 0

            // Line to Top-Right limit of the curve
            PathLine { x: root.curveRadius; y: 0 }

            // Concave Arc to Bottom-Left limit of the curve
            // Connects (r,0) to (0,r) curving inwards towards (r,r)
            PathArc {
                x: 0
                y: root.curveRadius
                radiusX: root.curveRadius
                radiusY: root.curveRadius
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }

            // Close back to start
            PathLine { x: 0; y: 0 }
        }
    }
}
