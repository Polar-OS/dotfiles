import QtQuick
import "../../../../config"

Rectangle {
    id: root

    property var pomodoro
    
    // Logic state
    property bool forceHidden: false
    
    // Computed active state for parent visibility
    readonly property bool isWorkEnding: pomodoro && pomodoro.stage === "work" && pomodoro.timeLeft <= 5
    readonly property bool isBreak: pomodoro && pomodoro.stage.includes("break")
    readonly property bool shouldShow: (isWorkEnding || isBreak) && !forceHidden

    color: Qt.rgba(0, 0, 0, 0.9)
    
    // Animation properties
    opacity: shouldShow ? 1.0 : 0.0
    scale: shouldShow ? 1.0 : 1.1
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Config.animDurationRegular; easing.type: Config.animEasingStandard }
    }
    Behavior on scale {
        NumberAnimation { duration: Config.animDurationRegular; easing.type: Config.animEasingStandard }
    }

    // Reshow timer for break mode
    Timer {
        id: reshowTimer
        interval: 30000 // 30 seconds
        repeat: false
        onTriggered: {
            if (root.isBreak) {
                root.forceHidden = false
            }
        }
    }

    function dismiss() {
        if (root.shouldShow) {
            root.forceHidden = true
            if (root.isBreak) {
                reshowTimer.restart()
            }
        }
    }
    
    Connections {
        target: pomodoro
        function onInternalStageChanged() {
            // Reset hidden state when stage changes (e.g. work -> break)
            root.forceHidden = false
            reshowTimer.stop()
        }
    }
    
    // Input handling
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onClicked: root.dismiss()
        onPositionChanged: root.dismiss()
        onWheel: root.dismiss()
    }

    // Focus handling
    focus: visible
    
    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        }
    }

    Keys.onPressed: (event) => {
        // Any key dismisses
        root.dismiss()
        event.accepted = true
    }

    Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pomodoro ? (pomodoro.stage === "work" ? "Get Ready for Break!" : "Break Time") : ""
            color: Config.accent
            font.pixelSize: 40
            font.bold: true
            font.family: Config.fontFamily
            visible: pomodoro && (pomodoro.stage !== "work" || pomodoro.timeLeft <= 5)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pomodoro ? pomodoro.statusText : ""
            color: "white"
            font.pixelSize: 200
            font.bold: true
            font.family: Config.fontFamily
        }
    }
    
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Move mouse or press any key to dismiss"
        color: "white"
        opacity: 0.5
        font.pixelSize: 20
        font.family: Config.fontFamily
    }
}
