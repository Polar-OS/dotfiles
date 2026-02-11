import QtQuick 2.0
Item {
    property var model: []
    property Component delegate
    
    Repeater {
        model: parent.model
        delegate: parent.delegate
    }
}
