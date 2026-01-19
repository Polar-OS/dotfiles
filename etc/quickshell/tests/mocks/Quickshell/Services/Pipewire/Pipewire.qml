pragma Singleton
import QtQuick 2.0
Item {
    property var defaultAudioSink: QtObject {
        property var audio: QtObject {
             property double volume: 0.4
             property bool muted: false
        }
        property string description: "Mock Speakers"
        property var audioNode: QtObject { property int id: 1 }
    }
    property var nodes: []
}
