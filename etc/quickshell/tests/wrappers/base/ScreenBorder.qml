import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import ".."
import "."

// Screen border with exclusive zone on all edges and inverted corners
Scope {
    id: root

    property int borderSize: Config.screenBorderSize
    property int cornerSize: Config.screenCornerRadius
    property color borderColor: Config.background

    // Top border
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: topBorder
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            
            // Explicitly re-evaluate when borderSize changes
            implicitHeight: {
                 var h = root.borderSize
                 return h
            }
            
            color: root.borderColor
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
        }
    }

    // Bottom border
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bottomBorder
            property var modelData
            screen: modelData

            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            
            // Explicitly re-evaluate when borderSize changes
            implicitHeight: {
                 var h = root.borderSize
                 return h
            }

            color: root.borderColor
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
        }
    }

    // Left border
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: leftBorder
            property var modelData
            screen: modelData

            anchors.left: true
            anchors.top: true
            anchors.bottom: true
            exclusiveZone: 0
            
            // Explicitly re-evaluate when borderSize changes
            implicitWidth: {
                 var w = root.borderSize
                 return w
            }

            color: root.borderColor
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
        }
    }

    // Right border
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rightBorder
            property var modelData
            screen: modelData

            anchors.right: true
            anchors.top: true
            anchors.bottom: true
            exclusiveZone: 0
            
            // Explicitly re-evaluate when borderSize changes
            implicitWidth: {
                 var w = root.borderSize
                 return w
            }

            color: root.borderColor
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
        }
    }

    // Inverted corners - one window per corner per screen
    // Top-left corner
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            exclusiveZone: 0
            implicitWidth: root.cornerSize + root.borderSize
            implicitHeight: root.cornerSize + root.borderSize
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay

            InvertedCorner {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                size: root.cornerSize
                curveRadius: Config.screenCornerRadius
                cornerColor: root.borderColor
                cornerRotation: 0
            }
        }
    }

    // Top-right corner
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.right: true
            exclusiveZone: 0
            implicitWidth: root.cornerSize + Math.max(0, root.borderSize - 1)
            implicitHeight: root.cornerSize + root.borderSize
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay

            InvertedCorner {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                size: root.cornerSize
                curveRadius: Config.screenCornerRadius
                cornerColor: root.borderColor
                cornerRotation: 90
            }
        }
    }

    // Bottom-right corner
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors.bottom: true
            anchors.right: true
            exclusiveZone: 0
            implicitWidth: root.cornerSize + Math.max(0, root.borderSize - 1)
            implicitHeight: root.cornerSize + Math.max(0, root.borderSize - 1)
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay

            InvertedCorner {
                anchors.top: parent.top
                anchors.left: parent.left
                size: root.cornerSize
                curveRadius: Config.screenCornerRadius
                cornerColor: root.borderColor
                cornerRotation: 180
            }
        }
    }

    // Bottom-left corner
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors.bottom: true
            anchors.left: true
            exclusiveZone: 0
            implicitWidth: root.cornerSize + root.borderSize
            implicitHeight: root.cornerSize + Math.max(0, root.borderSize - 1)
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay

            InvertedCorner {
                anchors.top: parent.top
                anchors.right: parent.right
                size: root.cornerSize
                curveRadius: Config.screenCornerRadius
                cornerColor: root.borderColor
                cornerRotation: 270
            }
        }
    }
}
