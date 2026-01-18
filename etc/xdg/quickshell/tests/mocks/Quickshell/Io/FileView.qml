import QtQuick 2.0
Item {
    property string path
    property var files: []
    signal loadFailed
    signal loaded
}
