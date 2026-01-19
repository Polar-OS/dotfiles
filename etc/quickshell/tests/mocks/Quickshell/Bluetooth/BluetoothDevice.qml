import QtQuick 2.0
Item {
    property string name
    property string icon
    property bool connected
    property bool paired
    property int state: 0 // Disconnected
    property bool batteryAvailable: false
    property double battery: 0.0
    
    function connect() { connected = true; }
    function disconnect() { connected = false; }
}
