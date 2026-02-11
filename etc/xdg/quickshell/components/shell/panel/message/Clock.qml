import QtQuick
import "../../../config"

// Clock display component
Item {
    id: root

    property bool forceShown: false

    // Clock Timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let currentTime = new Date();
            clockText.text = Qt.formatDateTime(currentTime, "HH:mm");
            if (currentTime.getSeconds() === 0 && (currentTime.getMinutes() === 0 || currentTime.getMinutes() === 30)) {
                showBriefly();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: root.forceShown = false
    }

    function showBriefly() {
        root.forceShown = true;
        hideTimer.restart();
    }

    function toggle() {
        root.forceShown = !root.forceShown;
        if (root.forceShown) {
            hideTimer.restart();
        }
    }

    // Initialize clock
    Component.onCompleted: {
        clockText.text = Qt.formatDateTime(new Date(), "HH:mm");
    }

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        anchors.centerIn: parent

        // Styling
        color: Config.foreground
        font.family: Config.fontFamily
        font.pixelSize: 16
        font.bold: true
    }
}
