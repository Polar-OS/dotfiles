import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../config"
import "../../../ui/indicators" // SmartIcon
import "."

Rectangle {
    id: root

    // Data from model - automatically filled by ListView roles
    property string name: ""
    property string icon: ""
    property string desc: ""
    property string provider: ""

    // Data from ListView
    property int index: -1
    property bool isCurrentItem: ListView.isCurrentItem

    signal launched
    signal hovered(int index)

    width: ListView.view ? ListView.view.width : 300
    height: 50
    radius: Config.itemRadius
    color: "transparent"
    z: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 15

        SmartIcon {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            
            // Resolve icon name or glyph locally before passing to SmartIcon
            readonly property string resolvedIcon: {
                return root.icon;
            }
            
            icon: resolvedIcon
            pixelSize: 20
            color: root.isCurrentItem ? Config.background : Config.foreground
            
            Behavior on color {
                ColorAnimation {
                    duration: Config.animDurationHover
                }
            }
            
            // Override implicit size to match layout
            width: 32
            height: 32
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            
            // Fixed height container to ensure baseline alignment
            Item {
                Layout.fillWidth: true
                implicitHeight: nameText.implicitHeight + (descText.visible ? descText.implicitHeight : 0)
                Layout.alignment: Qt.AlignVCenter

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width

                    Text {
                        id: nameText
                        width: parent.width
                        text: root.name
                        font.bold: root.provider !== "fonts"
                        font.family: root.provider === "fonts" ? root.name : Config.fontFamily
                        font.pixelSize: root.provider === "fonts" ? 18 : 14
                        color: root.isCurrentItem ? Config.background : Config.foreground
                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationHover
                            }
                        }
                        elide: Text.ElideRight
                    }

                    Text {
                        id: descText
                        width: parent.width
                        text: root.desc
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: root.isCurrentItem ? Qt.alpha(Config.background, 0.7) : Config.dimmed
                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationHover
                            }
                        }
                        elide: Text.ElideRight
                        visible: root.desc !== ""
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered(root.index)
        onClicked: root.launched()
    }
}
