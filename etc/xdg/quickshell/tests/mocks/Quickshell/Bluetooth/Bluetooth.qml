pragma Singleton
import QtQuick 2.0
Item {
    property var defaultAdapter: QtObject {
        property bool enabled: true
        property bool discovering: false
        property var devices: []
    }
}
