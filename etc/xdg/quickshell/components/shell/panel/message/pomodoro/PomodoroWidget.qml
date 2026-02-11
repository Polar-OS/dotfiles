import QtQuick
import QtQuick.Layouts
import "../../../../config"
import ".." // For Clock.qml which is in message/

MouseArea {
    id: root
    
    property var pomodoroController
    property bool clockForceShown: false
    
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    
    onClicked: mouse => {
        // Middle Click or Ctrl+LeftClick -> Toggle Type
        var isCtrlClick = (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier));
        if (mouse.button === Qt.MiddleButton || isCtrlClick) {
            pomodoroController.toggleType();
            return;
        }

        // Start if idle
        if (pomodoroController.stage === "idle") {
            if (mouse.button === Qt.LeftButton) {
                pomodoroController.startWork();
            }
            return;
        }

        // Running controls
        if (mouse.button === Qt.LeftButton) {
            pomodoroController.pause();
        } else if (mouse.button === Qt.RightButton) {
            pomodoroController.stop();
        }
    }

    // Container / Track for Progress Bar
    Rectangle {
        id: timerContainer
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.06) // Match notification background
        radius: Config.itemRadius
        clip: true

        // Progress Bar Fill
        Rectangle {
            id: progressBar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * (pomodoroController.percentage / 100)
            visible: pomodoroController.stage !== "idle"
            opacity: 0.2

            radius: Config.itemRadius

            readonly property color statusColor: {
                if (pomodoroController.stage === "paused")
                    return Config.dimmed; // Grey
                if (pomodoroController.stage.includes("work")) {
                    return (pomodoroController.percentage < 5) ? Config.orange : Config.accent;
                }
                if (pomodoroController.stage.includes("break"))
                    return Config.cyan; // Cyan for break
                return Config.accent;
            }

            color: statusColor
            border.width: 1
            border.color: statusColor

            SequentialAnimation {
                id: blinkAnim
                running: pomodoroController.stage === "paused" && progressBar.visible
                loops: Animation.Infinite

                NumberAnimation {
                    target: progressBar
                    property: "opacity"
                    to: 0.1
                    duration: Config.animDurationPulse
                    easing.type: Config.animEasingSoft
                }
                NumberAnimation {
                    target: progressBar
                    property: "opacity"
                    to: 0.3
                    duration: Config.animDurationPulse
                    easing.type: Config.animEasingSoft
                }

                onRunningChanged: {
                    if (!running)
                        progressBar.opacity = 0.2;
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Config.animationDurationSlow
                }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            Clock {
                id: clock
                Layout.alignment: Qt.AlignVCenter
                visible: true
                forceShown: root.clockForceShown
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignVCenter
                color: Config.dimmed
                visible: pomodoroController.stage !== "idle"
            }

            // Pomodoro Cycle Dots
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                visible: pomodoroController.stage !== "idle"

                Repeater {
                    model: Config.pomodoroCycleCount
                    Rectangle {
                        width: 6
                        height: 6
                        radius: Config.itemRadius
                        color: {
                            if (index < (pomodoroController.cycleCount % Config.pomodoroCycleCount))
                                return Config.accent;
                            if (index === (pomodoroController.cycleCount % Config.pomodoroCycleCount))
                                return Config.foreground;
                            return Qt.alpha(Config.dimmed, 0.3);
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: pomodoroController.statusText
                visible: pomodoroController.stage !== "idle"
                color: progressBar.statusColor
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
