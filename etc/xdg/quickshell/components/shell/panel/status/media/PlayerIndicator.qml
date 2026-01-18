import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../../../ui/indicators" // BaseIndicator
import "../../../../config"
import "../../../../ui/panel"

BaseIndicator {
    id: root

    property var player: null
    property bool isPlaying: false

    Component.onCompleted: {
        updatePlayerStatus();
    }

    function updatePlayerStatus() {
        if (root.player !== null) {
            root.isPlaying = root.player.playbackState === MprisPlaybackState.Playing;
        } else {
            root.isPlaying = false;
        }
    }

    function getPlayerIcon() {
        if (root.player === null) {
            return "󰝚"; // Music icon (no player)
        }
        if (root.isPlaying) {
            return "󰐊"; // Play icon (playing)
        }
        return "󰏤"; // Pause icon (paused)
    }

    Connections {
        target: root.player
        function onPlaybackStateChanged() {
            updatePlayerStatus();
        }
    }

    // BaseIndicator config
    fillPercentage: 0
    icon: getPlayerIcon()
    iconPixelSize: 18
}
