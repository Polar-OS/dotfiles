import QtQuick 2.15
import "framework"
import "wrappers/notifications"
import "wrappers/pomodoro"

SimpleTest {
    name: "NotificationWidgets"

    Clock {
        id: clock
    }
    
    Pomodoro {
        id: pomodoro
    }
    
    // SystemTray uses Quickshell.Services.SystemTray
    SystemTray {
        id: tray
        
    }

    function test_clock() {
        verify(clock.visible, "Clock is visible")
        // It has a Timer that updates text.
    }
    
    function test_pomodoro() {
        // Pomodoro is logical component
        // Config.pomodoroDuration is used
        verify(pomodoro, "Pomodoro loaded")
    }
    
    function test_tray() {
        verify(tray, "Tray loaded")
        // Tray relies on SystemTray service, mocked.
    }
}
