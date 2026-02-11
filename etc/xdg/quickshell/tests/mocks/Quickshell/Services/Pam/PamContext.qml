import QtQuick 2.0
Item {
    signal authSuccess
    signal authError
    signal info
    signal error
    signal completed(bool success)
    property string config
    property string configDirectory
    signal pamMessage(string message, int type)
    function authenticate(pass) { authSuccess() }
}
