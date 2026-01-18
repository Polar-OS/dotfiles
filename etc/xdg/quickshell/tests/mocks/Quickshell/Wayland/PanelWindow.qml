import QtQuick 2.0
Rectangle {
    property var screen
    property int exclusionMode
    
    // In Quickshell, contentItem is the window's content item.
    // We can simulate it by having a child item.
    property alias contentItem: internalContent
    
    Rectangle {
        id: internalContent
        anchors.fill: parent
        focus: true
    }
    
    default property alias data: internalContent.data
}
