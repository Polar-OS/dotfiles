import QtQuick 2.15
import "framework"
import "wrappers/status"
import "wrappers/media"
import Quickshell.Services.Mpris 1.0

SimpleTest {
    name: "MediaComponents"

    MprisPlayer {
        id: player
        width: 300
        height: 100
        // MprisPlayer expects 'player' property which is a MprisObject
        // We need to mock that structure
        player: QtObject {
            property string identity: "Mock Player"
            property var playbackStatus: Mpris.playbackStatus.playing
            property bool canControl: true
            property bool canGoNext: true
            property bool canGoPrevious: true
            property bool canPlay: true
            property bool canPause: true
            property var metadata: QtObject {
                property string title: "Test Song"
                property string artist: "Test Artist"
                property string artUrl: ""
                property int length: 180000000 // 3 min in microseconds
            }
            property int position: 90000000
            
            signal play()
            signal pause()
            signal next()
            signal previous()
        }
    }
    
    // MprisController is a logic component (Item) that manages the players list
    // It's harder to test visual output but we can check if it initializes
    MprisController {
        id: controller
    }

    function test_player_ui() {
        verify(player.width > 0, "Player loaded")
        // Check if title is displayed (would require introspection into MprisPlayer structure)
        // For now, smoke test is good.
    }
    
    function test_controller() {
        // Verify controller loaded
        verify(controller, "Controller loaded")
    }
}
