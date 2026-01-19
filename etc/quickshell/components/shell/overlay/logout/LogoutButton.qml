import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property string command: ""
    required property string text
    required property string icon
    property int keybind: -1
    property var action: null // Optional JS function callback

    function exec() {
        if (action) {
            action();
        } else if (command !== "") {
            Quickshell.execDetached(["sh", "-c", command]);
        }
    }
}
