import QtQuick
import QtQuick.Layouts
import Quickshell 1.0
import Quickshell.Wayland 1.0
import Quickshell.Services.Mpris
import "../../panel/message/pomodoro"
import "../../panel/message"
import "../../panel/status/media"
import ".."

Variants {
    id: root
    required property LockContext context
    property var pomodoroController
    property var mprisController

    model: context && context.active ? Quickshell.screens : []

    delegate: PanelWindow {
        id: window
        property var modelData
        screen: modelData

        // WlrLayershell.layer: WlrLayer.Overlay
        // WlrLayershell.keyboardFocus: (pomodoroController && pomodoroController.overlayVisible) ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
        // exclusionMode: ExclusionMode.Ignore

        color: Config.background
        
        
        Item {
            anchors.fill: parent
            focus: true
            


            MouseArea {
                anchors.fill: parent
                onPressed: passwordInput.forceActiveFocus()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 50

                // Clock display
                Text {
                    Layout.alignment: Qt.AlignHCenter

                    property var dateValue: new Date()

                    font.family: Config.fontFamily
                    font.pixelSize: 120
                    font.bold: true
                    color: Config.foreground
                    renderType: Text.NativeRendering

                    Timer {
                        running: true
                        repeat: true
                        interval: 1000
                        onTriggered: parent.dateValue = new Date()
                    }

                    text: {
                        const hours = dateValue.getHours().toString().padStart(2, '0');
                        const minutes = dateValue.getMinutes().toString().padStart(2, '0');
                        return `${hours}:${minutes}`;
                    }
                }

                // Widgets Container
                Rectangle {
                    id: widgetsContainer
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: contentLayout.implicitHeight + 32 // Padding (16 top + 16 bottom)
                    
                    // Visibility logic
                    readonly property bool hasMedia: mprisController && mprisController.mprisPlayer && mprisController.mprisPlayer.playbackState !== MprisPlaybackState.Stopped
                    readonly property bool hasPomodoro: pomodoroController && pomodoroController.stage !== "idle"
                    readonly property bool hasNotifs: notificationList.count > 0
                    
                    visible: hasMedia || hasPomodoro || hasNotifs

                    // Styling "like the others"
                    color: Qt.alpha(Config.foreground, 0.07)
                    radius: Config.radius
                    border.color: Config.accent
                    border.width: 2

                    ColumnLayout {
                        id: contentLayout
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16 // Increased from 10
                        spacing: 12

                        // 1. Media Player
                        MprisPlayer {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            visible: widgetsContainer.hasMedia
                            
                            player: mprisController ? mprisController.mprisPlayer : null
                            trackedPosition: mprisController ? mprisController.trackedPosition : 0
                            allPlayers: mprisController ? mprisController.allPlayers : []
                        }

                        // 2. Notifications
                        NotificationList {
                            id: notificationList
                            Layout.fillWidth: true
                            Layout.maximumHeight: 300
                            showBody: false
                            
                            visible: widgetsContainer.hasNotifs
                        }

                        // 3. Pomodoro
                        PomodoroWidget {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            visible: widgetsContainer.hasPomodoro
                            
                            pomodoroController: root.pomodoroController
                            clockForceShown: false // Assuming defaults
                        }
                    }
                }

                // Authentication section
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 30

                    // Unlock options row
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 25

                        // Fingerprint option
                        ColumnLayout {
                            spacing: 10

                            Rectangle {
                                id: fingerprintCard
                                Layout.alignment: Qt.AlignHCenter
                                width: 80
                                height: 80
                                radius: Config.radius
                                color: root.context.fingerprintScanning
                                    ? Qt.alpha(Config.accent, 0.15)
                                    : Qt.alpha(Config.foreground, 0.07)
                                border.color: root.context.fingerprintSuccess
                                    ? Config.green
                                    : (root.context.fingerprintScanning ? Config.accent : "transparent")
                                border.width: root.context.fingerprintSuccess || root.context.fingerprintScanning ? 2 : 0

                                Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                                Behavior on border.color { ColorAnimation { duration: Config.animDurationRegular } }

                                // Scanning pulse animation
                                SequentialAnimation on scale {
                                    running: root.context.fingerprintScanning && !root.context.fingerprintSuccess
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.03; duration: Config.animDurationPulse; easing.type: Config.animEasingPulse }
                                    NumberAnimation { to: 1.0; duration: Config.animDurationPulse; easing.type: Config.animEasingPulse }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.context.fingerprintSuccess ? "󰄬" : "󰟀"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 36
                                    color: root.context.fingerprintSuccess
                                        ? Config.green
                                        : (root.context.fingerprintScanning ? Config.accent : Config.foreground)
                                    opacity: root.context.fingerprintScanning || root.context.fingerprintSuccess ? 1.0 : 0.6

                                    Behavior on opacity { NumberAnimation { duration: Config.animDurationRegular } }
                                    Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Fingerprint"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: root.context.fingerprintScanning ? Config.accent : Config.dimmed

                                Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                            }
                        }

                        // Divider with "or"
                        ColumnLayout {
                            spacing: 8

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 1
                                height: 25
                                color: Qt.alpha(Config.foreground, 0.2)
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "or"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: Config.dimmed
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 1
                                height: 25
                                color: Qt.alpha(Config.foreground, 0.2)
                            }
                        }

                        // Password option
                        ColumnLayout {
                            spacing: 10

                            Rectangle {
                                id: passwordCard
                                Layout.alignment: Qt.AlignHCenter
                                width: 80
                                height: 80
                                radius: Config.radius
                                color: passwordInput.activeFocus
                                    ? Qt.alpha(Config.accent, 0.15)
                                    : Qt.alpha(Config.foreground, 0.07)
                                border.color: passwordInput.activeFocus ? Config.accent : "transparent"
                                border.width: passwordInput.activeFocus ? 2 : 0

                                Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                                Behavior on border.color { ColorAnimation { duration: Config.animDurationRegular } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌆"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 36
                                    color: passwordInput.activeFocus ? Config.accent : Config.foreground
                                    opacity: passwordInput.activeFocus ? 1.0 : 0.6

                                    Behavior on opacity { NumberAnimation { duration: Config.animDurationRegular } }
                                    Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Password"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: passwordInput.activeFocus ? Config.accent : Config.dimmed

                                Behavior on color { ColorAnimation { duration: Config.animDurationRegular } }
                            }
                        }
                    }

                    // Password input field
                    Rectangle {
                        id: inputContainer
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 320
                        implicitHeight: 50
                        radius: Config.radius
                        color: Qt.alpha(Config.foreground, 0.07)
                        border.color: root.context.showFailure
                            ? Config.red
                            : (passwordInput.activeFocus ? Config.accent : "transparent")
                        border.width: root.context.showFailure || passwordInput.activeFocus ? 2 : 0

                        Behavior on border.color { ColorAnimation { duration: Config.animationDurationQuick } }

                        // Shake animation on failure
                        property real shakeOffset: 0
                        transform: Translate { x: inputContainer.shakeOffset }

                        SequentialAnimation {
                            id: shakeAnimation
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: -10; duration: Config.animDurationShake }
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: 10; duration: Config.animDurationShake }
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: -8; duration: Config.animDurationShake }
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: 8; duration: Config.animDurationShake }
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: -4; duration: Config.animDurationShake }
                            NumberAnimation { target: inputContainer; property: "shakeOffset"; to: 0; duration: Config.animDurationShake }
                        }

                        Connections {
                            target: root.context
                            function onShowFailureChanged() {
                                if (root.context.showFailure) {
                                    shakeAnimation.start();
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onPressed: passwordInput.forceActiveFocus()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 10

                            // Lock icon
                            Text {
                                text: "󰌆"
                                font.family: Config.iconFontFamily
                                font.pixelSize: 18
                                color: Config.dimmed
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // Placeholder text
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Enter password..."
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    color: Config.dimmed
                                    visible: passwordInput.text === ""
                                }

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter

                                    focus: true
                                    selectByMouse: true
                                    enabled: !root.context.unlockInProgress
                                    echoMode: TextInput.Password
                                    passwordCharacter: "•"
                                    passwordMaskDelay: 0
                                    inputMethodHints: Qt.ImhSensitiveData

                                    color: Config.foreground
                                    selectionColor: Config.accent
                                    selectedTextColor: Config.background

                                    font.family: Config.fontFamily
                                    font.pixelSize: 16
                                    


                                    Component.onCompleted: {
                                        if (root.context.active) {
                                            focusTimer.start();
                                        }
                                    }

                                    onTextChanged: {
                                        if (passwordInput.activeFocus) {
                                            root.context.currentText = this.text;
                                        }
                                    }

                                    onAccepted: {
                                        if (this.text !== "") {
                                            root.context.tryUnlock();
                                        }
                                    }

                                    Connections {
                                        target: root.context
                                        function onActiveChanged() {
                                            if (root.context.active) {
                                                focusTimer.start();
                                            }
                                        }

                                        function onCurrentTextChanged() {
                                            if (!passwordInput.activeFocus) {
                                                passwordInput.text = root.context.currentText;
                                            }
                                        }
                                    }

                                    Timer {
                                        id: focusTimer
                                        interval: 200
                                        onTriggered: {
                                            passwordInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            // Submit arrow (visible when text entered)
                            Text {
                                text: "󰁔"
                                font.family: Config.iconFontFamily
                                font.pixelSize: 18
                                color: passwordInput.text.length > 0 ? Config.accent : "transparent"
                                opacity: root.context.unlockInProgress ? 0.5 : 1.0

                                Behavior on color { ColorAnimation { duration: Config.animationDurationQuick } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: passwordInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (passwordInput.text !== "") {
                                            root.context.tryUnlock();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Error message with warning styling
                    Rectangle {
                        id: errorContainer
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: errorRow.implicitWidth + 24
                        implicitHeight: 36
                        radius: Config.itemRadius
                        color: Qt.alpha(Config.red, 0.15)
                        visible: root.context.showFailure
                        opacity: root.context.showFailure ? 1.0 : 0.0

                        Behavior on opacity { NumberAnimation { duration: Config.animDurationRegular } }

                        RowLayout {
                            id: errorRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰀦"
                                font.family: Config.iconFontFamily
                                font.pixelSize: 16
                                color: Config.red
                            }

                            Text {
                                text: root.context.configError !== "" ? root.context.configError : "Authentication failed"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Config.red
                            }
                        }
                    }
                }
            }
        }
    }
}
