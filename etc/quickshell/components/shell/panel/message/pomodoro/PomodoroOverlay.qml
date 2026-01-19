import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../../config" // For Config

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    color: "transparent"

    property var pomodoro
    property bool forceHidden: false
    
    // Reshow timer for break mode
    // Timer {
    //     id: reshowTimer
    //     interval: 30000 // 30 seconds
    //     repeat: false
    //     onTriggered: {
    //         if (root.isBreak) {
    //             root.forceHidden = false
    //         }
    //     }
    // }

    function dismiss() {
        if (root.visible) {
            root.forceHidden = true
            // if (root.isBreak) {
            //     reshowTimer.restart()
            // }
        }
    }

    property bool isLockScreenActive: false
    
    // Work ending countdown (last 5 seconds, including 0)
    readonly property bool isWorkEnding: pomodoro && pomodoro.stage === "work" && pomodoro.timeLeft <= 5
    readonly property bool isBreak: pomodoro && pomodoro.stage.includes("break")
    
    // Keep visible during transition: once shown during work ending, stay visible through break
    // Logic: Show if (WorkEnding OR Break) AND (Not ForceHidden)
    readonly property bool shouldShow: (isWorkEnding || isBreak) && !forceHidden
    
    // Trigger to force restacking (bring to top)
    property bool restackTrigger: true
    
    // Sync visibility state to controller for focus coordination
    onVisibleChanged: {
        if (pomodoro) {
            pomodoro.overlayVisible = visible
        }
    }
    
    // Window visibility tied to content opacity to allow fade out
    visible: contentRect.opacity > 0 && restackTrigger
    
    onIsLockScreenActiveChanged: {
        // If lock screen activates while we are showing, toggle visibility to pop to top
        if (isLockScreenActive && shouldShow) {
            restackTrigger = false
            Qt.callLater(() => { restackTrigger = true })
        }
    }
    
    Connections {
        target: pomodoro
        function onInternalStageChanged() {
            // Reset hidden state on any stage change
            // This ensures that if the user dismissed the "Work Ending" countdown,
            // it reappears when the Break actually starts.
            root.forceHidden = false
        }
    }
    
    Rectangle {
        id: contentRect
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        opacity: root.shouldShow ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDurationRegular
                easing.type: Config.animEasingStandard
            }
        }
        
        // Ensure this rectangle gets focus
        focus: root.visible
        
        // Input handling
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onClicked: root.dismiss()
            onPositionChanged: root.dismiss()
            onWheel: root.dismiss()
        }

        Keys.onPressed: (event) => {
            // Any key dismisses during break
            root.dismiss()
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
}
