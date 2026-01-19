import QtQuick 2.15
import "framework"
import "wrappers/notifications"
import Quickshell.Services.Notifications 1.0

SimpleTest {
    name: "NotificationLogic"

    NotificationList {
        id: notifList
        width: 300
        height: 500
    }

    function test_grouping() {
        // Add first notification
        var n1 = {
            appName: "Discord",
            summary: "Msg 1",
            body: "Hello",
            urgency: 1,
            tracked: false,
            appIcon: "",
            icon: "",
            dismiss: function() {}
        };
        notifList.notificationServer.addMock(n1);
        
        // Add second notification (same app)
        var n2 = {
            appName: "Discord",
            summary: "Msg 2",
            body: "World",
            urgency: 1,
            tracked: false,
            appIcon: "",
            icon: "",
            dismiss: function() {}
        };
        notifList.notificationServer.addMock(n2);
        
        // Add third notification (diff app)
        var n3 = {
            appName: "Slack",
            summary: "Msg 3",
            body: "Work",
            urgency: 1,
            tracked: false,
            appIcon: "",
            icon: "",
            dismiss: function() {}
        };
        notifList.notificationServer.addMock(n3);
        
        // Wait for repeaters to instantiate
        // Since we run in same frame, might need to wait?
        // SimpleTest has a timer loop, but `addMock` is sync.
        // Let's verify children count.
        
        // notifList children include: Timer, Repeater (logic), and the instantiated Delegates.
        // We filter for the delegates (Rectangles).
        
        var delegates = [];
        
        // Traverse to find delegates
        // notifList -> Flickable -> ColumnLayout -> Delegates
        
        function findDelegates(item) {
            for (var i = 0; i < item.children.length; i++) {
                var child = item.children[i];
                if (child.hasOwnProperty("isGrouped")) {
                    delegates.push(child);
                } else {
                    findDelegates(child);
                }
            }
        }
        
        findDelegates(notifList);
        
        // Sort delegates by y position to ensure order
        delegates.sort(function(a, b) { return a.y - b.y });

        verify(delegates.length === 3, "Created 3 delegates");
        
        // Check grouping
        // Delegate 0: Discord (Leader) -> isGrouped: false
        // Delegate 1: Discord (Follower) -> isGrouped: true
        // Delegate 2: Slack (Leader) -> isGrouped: false
        
        // Note: Repeater order matches model order.
        
        verify(delegates[0].isGrouped === false, "First item not grouped");
        verify(delegates[1].isGrouped === true, "Second item is grouped");
        verify(delegates[2].isGrouped === false, "Third item not grouped");
        
        verify(delegates[0].isGroupLeader === true, "First item is leader");
        verify(delegates[1].isGroupLeader === false, "Second item not leader");
    }
}
