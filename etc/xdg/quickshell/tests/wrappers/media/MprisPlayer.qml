import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../base"
import "../../../../ui/button"
import ".."

Item {
    id: root

    property var player: null
    property real trackedPosition: 0
    property var allPlayers: []

    // Expose navigation targets
    property alias prevButton: prevBtn
    property alias playButton: playBtn
    property alias nextButton: nextBtn

    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true

    // Delayed visibility for album art container
    property bool _layoutReady: false
    onWidthChanged: if (width > 0 && height > 0) albumArtDelayTimer.restart()
    onHeightChanged: if (width > 0 && height > 0) albumArtDelayTimer.restart()
    onVisibleChanged: {
        if (visible && width > 0 && height > 0) {
            albumArtDelayTimer.restart();
        } else if (!visible) {
            _layoutReady = false;
            albumArtDelayTimer.stop();
        }
    }

    Timer {
        id: albumArtDelayTimer
        interval: 100
        onTriggered: root._layoutReady = true
    }

    // Mask source for album art
    Rectangle {
        id: albumArtMask
        anchors.fill: albumArtContainer
        radius: Config.radius
        visible: false
        layer.enabled: true
    }

    Item {
        id: albumArtContainer
        anchors.fill: parent
        visible: root.player?.trackArtUrl !== "" && root._layoutReady
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: albumArtMask
        }
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Config.animationDurationQuick }
        }

        Image {
            id: albumArt
            anchors.fill: parent
            source: root.player?.trackArtUrl || ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3
            asynchronous: true
            cache: true

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animationDurationMedium
                    easing.type: Config.animEasingStandard
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 50
            color: "transparent"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Config.background
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 50
            color: "transparent"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Config.background
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 50
            color: "transparent"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Config.background
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 50
            color: "transparent"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Config.background
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 15
        visible: root.player !== null

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 300
            text: root.player?.trackTitle || "No media playing"
            font.family: Config.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Config.foreground
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter

            style: Config.isLightTheme ? Text.Normal : Text.Outline
            styleColor: Config.shadow
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 300
            text: root.player?.trackArtist || ""
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Qt.alpha(Config.foreground, 0.7)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter

            style: Config.isLightTheme ? Text.Normal : Text.Outline
            styleColor: Config.shadow
        }

        RowLayout {
            id: controlsRow
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            QuickButton {
                id: prevBtn
                size: 40
                icon: "󰒮"
                visible: root.player?.canGoPrevious || false
                onClicked: root.player?.previous()
            }

            QuickButton {
                id: playBtn
                size: 50
                icon: root.player?.isPlaying ? "󰏤" : "󰐊"
                visible: root.player?.canTogglePlaying || false
                onClicked: root.player?.togglePlaying()
            }

            QuickButton {
                id: nextBtn
                size: 40
                icon: "󰒭"
                visible: root.player?.canGoNext || false
                onClicked: root.player?.next()
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: controlsRow.width
            Layout.preferredHeight: 6
            radius: Config.itemRadius
            color: Qt.alpha(Config.foreground, 0.2)
            visible: root.player?.lengthSupported || false

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.player?.length > 0 ? (root.trackedPosition / root.player.length) * parent.width : 0
                radius: parent.radius
                color: Config.accent

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDurationRegular
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (root.player?.canSeek) {
                        var position = mouse.x / parent.width * root.player.length;
                        root.player.position = position;
                        root.trackedPosition = position;
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: {
            if (root.allPlayers.length === 0) {
                return "No media player detected";
            } else if (root.allPlayers.length > 1) {
                return "Multiple players available\n(Using: " + (root.player?.identity || "unknown") + ")";
            } else {
                return "No track playing";
            }
        }
        font.family: Config.fontFamily
        font.pixelSize: 14
        color: Qt.alpha(Config.foreground, 0.5)
        visible: root.player === null
        horizontalAlignment: Text.AlignHCenter
    }
}
