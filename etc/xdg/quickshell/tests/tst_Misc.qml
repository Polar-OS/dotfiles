import QtQuick 2.15
import "framework"
import "wrappers/lock"
import "wrappers/logout"
import "wrappers/workspaces"

SimpleTest {
    name: "MiscComponents"

    // Mock Niri object for Workspaces
    property var niriMock: QtObject {
        property var workspaces: []
        function focusWorkspaceById(id) {}
    }

    Workspaces {
        id: workspaces
        niri: niriMock
    }
    
    Logout {
        id: logout
        // Needs mocking for shutdown command if it runs immediately
    }
    
    Lock {
        id: lock
    }

    function test_workspaces() {
        verify(workspaces, "Workspaces loaded")
    }
    
    function test_logout() {
        verify(logout, "Logout loaded")
    }
    
    function test_lock() {
        verify(lock, "Lock loaded")
    }
}
