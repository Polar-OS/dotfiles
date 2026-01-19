import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io

// Component that manages MPRIS player connections and position tracking
Item {
    id: root

    // Mpris player (first available player)
    property var mprisPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property var allPlayers: Mpris.players.values

    // Track playback position manually since Mpris.position doesn't update in real-time
    property real trackedPosition: 0
    property real lastKnownPosition: 0
    property real lastUpdateTime: 0

    // ==================== COMPONENT LIFECYCLE ====================
    Component.onCompleted: {
        console.log("MPRIS Players available:", Mpris.players.values.length);
        for (let i = 0; i < Mpris.players.values.length; i++) {
            console.log("  Player", i, ":", Mpris.players.values[i].identity, Mpris.players.values[i].dbusName);
        }
        // Initialize tracked position
        if (root.mprisPlayer !== null) {
            root.lastKnownPosition = root.mprisPlayer.position;
            root.trackedPosition = root.lastKnownPosition;
            root.lastUpdateTime = root.mprisPlayer.playbackState === MprisPlaybackState.Playing ? new Date().getTime() : 0;
            console.log("Track art URL:", root.mprisPlayer.trackArtUrl);
        }
    }

    // ==================== MPRIS CONNECTIONS ====================
    // Log track changes for debugging
    Connections {
        target: root.mprisPlayer
        function onTrackChanged() {
            if (root.mprisPlayer !== null) {
                console.log("Track changed - Art URL:", root.mprisPlayer.trackArtUrl);
                console.log("Title:", root.mprisPlayer.trackTitle);
            }
        }
        function onPostTrackChanged() {
            if (root.mprisPlayer !== null) {
                console.log("Post track changed - Art URL:", root.mprisPlayer.trackArtUrl);
            }
        }
    }

    // Sync tracked position with actual MPRIS position when it changes
    Connections {
        target: root.mprisPlayer
        function onPositionChanged() {
            if (root.mprisPlayer !== null) {
                root.lastKnownPosition = root.mprisPlayer.position;
                root.trackedPosition = root.lastKnownPosition;
                root.lastUpdateTime = new Date().getTime();
            }
        }
        function onPlaybackStateChanged() {
            if (root.mprisPlayer !== null) {
                if (root.mprisPlayer.playbackState !== MprisPlaybackState.Playing) {
                    // Reset update time when not playing
                    root.lastUpdateTime = 0;
                } else {
                    // Sync position when starting to play
                    root.lastKnownPosition = root.mprisPlayer.position;
                    root.trackedPosition = root.lastKnownPosition;
                    root.lastUpdateTime = new Date().getTime();
                }
            }
        }
    }

    // ==================== TIMERS ====================
    // Timer to update MPRIS position continuously when playing (every 3 seconds)
    Timer {
        interval: 3000
        repeat: true
        running: root.mprisPlayer !== null && root.mprisPlayer.playbackState === MprisPlaybackState.Playing
        onTriggered: {
            if (root.mprisPlayer !== null) {
                // Update tracked position by adding to elapsed time
                var currentTime = new Date().getTime();
                if (root.lastUpdateTime > 0) {
                    var deltaTime = (currentTime - root.lastUpdateTime) / 1000; // Convert to seconds
                    root.trackedPosition += deltaTime;
                }
                root.lastUpdateTime = currentTime;
            }
        }
    }

    // ==================== IPC HANDLERS ====================
    // IPC handler to list MPRIS players
    IpcHandler {
        target: "ui.media.list"

        function list(): void {
            console.log("MPRIS Players:", Mpris.players.values.length);
            for (let i = 0; i < Mpris.players.values.length; i++) {
                console.log(`  ${i}: ${Mpris.players.values[i].identity} (${Mpris.players.values[i].dbusName})`);
            }
        }
    }
}
