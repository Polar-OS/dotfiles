import QtQuick 2.0
Item {
    property var trackedNotifications: []
    signal notification(var notification)
    
    function addMock(n) {
        var list = [];
        for(var i=0; i<trackedNotifications.length; i++) list.push(trackedNotifications[i]);
        list.push(n);
        trackedNotifications = list;
        notification(n);
    }
}
