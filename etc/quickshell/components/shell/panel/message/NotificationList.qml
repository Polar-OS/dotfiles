import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../config"

// Notification list component
Item {
    id: root

    property var notificationServer: NotificationServer {
        onNotification: (n) => {
            n.tracked = true;
            root.notificationForceShown = true;
            notificationHideTimer.restart();
        }
    }

    property bool hasNotifications: notificationRepeater.count > 0
    property bool notificationForceShown: false
    property alias count: notificationRepeater.count
    property bool showBody: true

    // Limit height to allow scrolling when list is long
    // If layout is small, use layout height. If large, cap at 600.
    implicitHeight: Math.min(layout.implicitHeight, 600)
    
    // Pass Layout properties to parent
    Layout.fillWidth: true
    
    Timer {
        id: notificationHideTimer
        interval: 10000
        onTriggered: root.notificationForceShown = false
    }

    visible: root.hasNotifications || root.notificationForceShown
    opacity: visible ? 1 : 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: Config.animationDurationSlow
            easing.type: Config.animEasingStandard
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: layout.implicitHeight
        contentWidth: width
        clip: true
        
        // Auto-scroll to bottom when content grows
        // Only if we are already at the bottom or if it's a new message
        onContentHeightChanged: {
            if (contentHeight > height) {
                 contentY = contentHeight - height;
            }
        }

        ColumnLayout {
            id: layout
            width: parent.width
            spacing: 0 // Handled by margins in delegate

            Repeater {
                id: notificationRepeater
                model: notificationServer.trackedNotifications

                delegate: Rectangle {
            id: notifRect
            readonly property var notifData: modelData
            
            // Animation state for smooth entry/exit
            property bool animationComplete: false
            property bool dismissing: false
            
            // Check Previous (Am I following same app?)
            readonly property bool isGrouped: {
                if (index === 0) return false;
                var list = root.notificationServer.trackedNotifications;
                if (list && index < list.length && list[index - 1].appName === notifData.appName) return true;
                return false;
            }

            // Check Next (Am I leading same app?)
            readonly property bool isGroupLeader: {
                var list = root.notificationServer.trackedNotifications;
                if (list && index < list.length - 1 && list[index + 1].appName === notifData.appName) return true;
                return false;
            }

            // Target height for this notification
            readonly property real targetHeight: layout.implicitHeight + 20

            // Function to dismiss with animation
            function dismiss() {
                if (!dismissing) {
                    dismissing = true;
                    animationComplete = false;
                    dismissTimer.start();
                }
            }

            // Timer to actually remove after exit animation
            Timer {
                id: dismissTimer
                interval: 350 // Slightly longer than animation
                onTriggered: {
                    // Safe removal: just stop tracking.
                    // The shell handles the cleanup. calling close() on an already 
                    // destroying notification causes C++ errors.
                    if (notifRect.notifData && notifRect.notifData.tracked) {
                        try {
                            notifRect.notifData.tracked = false;
                        } catch (e) {
                            console.warn("Error untracking notification:", e);
                        }
                    }
                }
            }

            // Auto-dismiss timer
            Timer {
                interval: 10000
                running: notifData.urgency !== NotificationUrgency.Critical && !mouseArea.containsMouse && !dismissing
                onTriggered: {
                    notifRect.dismiss();
                }
            }

            Layout.fillWidth: true
            // Animate height: 0 -> targetHeight on entry, targetHeight -> 0 on exit
            Layout.preferredHeight: animationComplete ? targetHeight : 0
            Layout.topMargin: index === 0 ? 0 : (isGrouped ? 1 : 8)
            Layout.bottomMargin: 0
            
            radius: Config.itemRadius
            clip: true
            opacity: animationComplete ? 1 : 0

            // Entry animation
            Component.onCompleted: {
                animationComplete = true;
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Config.animationDurationMedium
                    easing.type: Config.animEasingStandard
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDurationRegular
                    easing.type: Config.animEasingStandard
                }
            }

            // Corner Flattening Patches
            // Flatten Top if grouped (following)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
                visible: isGrouped
            }

            // Flatten Bottom if leader (followed)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
                visible: isGroupLeader
            }

            // Solid color calculation to avoid alpha overlap artifacts
            // Mix Config.background (#1a1b26) with White 6% or Red 15%
            readonly property color backgroundColor: {
                if (notifData.urgency === NotificationUrgency.Critical) {
                    return Qt.tint(Config.background, Qt.rgba(1, 0, 0, 0.15));
                } else {
                    return Qt.tint(Config.background, Qt.rgba(1, 1, 1, 0.06));
                }
            }

            color: backgroundColor

            border.width: notifData.urgency === NotificationUrgency.Critical ? 1 : 0
            border.color: Config.red

            Behavior on color {
                ColorAnimation { duration: Config.animationDurationQuick }
            }

            // Corner Flattening Patches (Seamless with solid color)
            // Flatten Top if grouped (following)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
                visible: isGrouped
            }

            // Flatten Bottom if leader (followed)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
                visible: isGroupLeader
            }

            RowLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                    // Icon (Only first in group)
                Item {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    visible: !isGrouped

                    readonly property string rawIcon: notifData.appIcon || notifData.icon || ""
                    
                    readonly property string resolvedIcon: {
                        return rawIcon;
                    }

                    property bool isFontIcon: {
                        if (resolvedIcon.length === 0) return false;
                        var cp = resolvedIcon.codePointAt(0);
                        return (cp >= 0xE000 && cp <= 0xF8FF) || (cp >= 0xF0000 && cp <= 0xFFFFD) || (cp >= 0x100000 && cp <= 0x10FFFD);
                    }

                    property bool hasIcon: resolvedIcon !== ""

                    // Try to load app icon
                    Image {
                        id: appIconImage
                        anchors.fill: parent
                        source: (parent.hasIcon && !parent.isFontIcon) ? "image://icon/" + parent.resolvedIcon : ""
                        asynchronous: true
                        sourceSize: Qt.size(32, 32)
                        visible: parent.hasIcon && !parent.isFontIcon
                    }

                    // Fallback icon using font (or if resolved icon is a font glyph)
                    Text {
                        anchors.centerIn: parent
                        text: parent.isFontIcon ? parent.resolvedIcon : "󰂚"
                        font.family: Config.iconFontFamily
                        font.pixelSize: 20
                        color: Config.dimmed
                        visible: !parent.hasIcon || parent.isFontIcon
                    }
                }

                // Spacer for indented content if grouped
                Item {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    visible: isGrouped && (notifData.appIcon || notifData.icon)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: notifData.summary
                            color: Config.foreground
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: notifData.appName
                            color: notifData.urgency === NotificationUrgency.Critical ? Config.red : Config.dimmed
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: notifData.urgency === NotificationUrgency.Critical
                            visible: !isGrouped
                        }
                    }

                    Text {
                        text: notifData.body
                        color: Config.dimmed
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        visible: root.showBody
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    notifRect.dismiss();
                }
            }
        }
    }
}
}
}
