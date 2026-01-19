pragma Singleton
import QtQuick 2.0
Item {
    property var players: QtObject { property var values: [] }
    // Properties must be lowercase in QML
    property var playbackStatus: QtObject {
        property int playing: 0
        property int paused: 1
        property int stopped: 2
    }
}
