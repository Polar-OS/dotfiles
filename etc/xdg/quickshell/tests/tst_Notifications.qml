import QtQuick 2.15
import "framework"
import "wrappers/notifications"
import Quickshell.Services.Notifications 1.0

SimpleTest {
    name: "NotificationComponents"

    NotificationList {
        id: notifList
        width: 300
        height: 500
    }

    function test_notifications() {
        verify(!notifList.hasNotifications, "Initially empty")
        
        var n = {
            appName: "TestApp",
            summary: "Hello",
            body: "World",
            urgency: 1,
            tracked: false,
            dismiss: function() { console.error("Dismissed") }
        }
        
        notifList.notificationServer.addMock(n)
        
        verify(notifList.hasNotifications, "Has notifications after add")
        verify(notifList.visible, "List visible")
    }
}
