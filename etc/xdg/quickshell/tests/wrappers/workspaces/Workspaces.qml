import QtQuick
import QtQuick.Layouts
import "../base"
import ".."

Panel {
    id: root

    position: "left"

    // Niri object passed from shell.qml
    required property var niri

    property bool showByChange: false

    preventAutoHide: showByChange

    onShowByChangeChanged: {
        if (showByChange) {
            root.revealed = true
        } else {
            if (!root.isHovered) {
                root.revealed = false
            }
        }
    }

    property real verticalPadding: Config.padding
    property real horizontalPadding: Config.padding - 2

    contentWidth: horizontalPadding * 2 + 24
    contentHeight: workspacesLayout.implicitHeight + verticalPadding * 2
    contentPadding: 0

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.showByChange = false
    }

    ColumnLayout {
        id: workspacesLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        width: 24
        Layout.topMargin: root.verticalPadding
        Layout.bottomMargin: root.verticalPadding
        spacing: Config.spacing

        Repeater {
            // Use the real Niri workspaces model
            model: root.niri.workspaces

            Rectangle {
                // Niri model properties: id, name, idx, isActive, isFocused, etc.
                property bool isActive: modelData.isActive
                property var workspaceId: modelData.id

                // Trigger to show OSD when this workspace becomes active
                onIsActiveChanged: {
                    if (isActive) {
                        root.showByChange = true;
                        hideTimer.restart();
                    }
                }

                Layout.alignment: Qt.AlignHCenter
                width: 24
                height: 24
                radius: Config.itemRadius // Unified with volume bar (4px)

                // Background: Config.foreground if active, very dimmed otherwise (placeholder)
                color: isActive ? Config.foreground : Qt.alpha(Config.foreground, 0.08)

                // Smooth color animation
                Behavior on color {
                    ColorAnimation {
                        duration: Config.animationDuration
                    }
                }

                // Click to change workspace
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.niri.focusWorkspaceById(parent.workspaceId)
                }
            }
        }
    }
}
