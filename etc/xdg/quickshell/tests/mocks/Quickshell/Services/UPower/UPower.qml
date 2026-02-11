pragma Singleton
import QtQuick 2.0
Item {
    property var displayDevice: QtObject {
        property int state: 2 
        property double percentage: 0.75
        property string iconName: "battery-080"
    }
}
