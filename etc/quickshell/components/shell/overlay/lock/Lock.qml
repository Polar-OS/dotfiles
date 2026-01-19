import QtQuick
import Quickshell

Scope {
    id: root
    
    // Expose lockContext for external access (e.g., from Logout)
    property alias context: lockContext
    property var pomodoroController
    property var mprisController
    
    LockContext {
        id: lockContext
    }

    LockSurface {
        id: lockscreen
        context: lockContext
        pomodoroController: root.pomodoroController
        mprisController: root.mprisController
    }
}
