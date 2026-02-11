import QtQuick 2.15
import "framework"
import "wrappers/workspaces"

SimpleTest {
    id: root
    name: "WorkspaceInteractions"

    property var lastFocusedId: -1
    property var niriMock: QtObject {
        property var workspaces: [
            { id: 10, idx: 1, isActive: true },
            { id: 20, idx: 2, isActive: false }
        ]
        function focusWorkspaceById(id) {
            root.lastFocusedId = id
        }
    }

    Workspaces {
        id: workspaces
        niri: niriMock
        width: 100
        height: 300
    }

    function findRepeaterItems(rootItem) {
        var found = [];
        
        function traverse(item) {
            if (!item) return;
            
            // Special handling for Window/PanelWindow which uses contentItem
            try {
                if (item.contentItem && typeof item.contentItem === 'object') {
                    traverse(item.contentItem);
                }
            } catch(e) {}

            // Check if item has children property safely
            // In QML, checking property existence on QtObject can be tricky
            var hasChildren = false;
            try { hasChildren = typeof item.children !== "undefined"; } catch(e) {}
            
            if (hasChildren && item.children) {
                for (var i = 0; i < item.children.length; i++) {
                    var child = item.children[i];
                    try {
                        if (child.hasOwnProperty("workspaceId")) {
                            found.push(child);
                        }
                    } catch(e) {}
                    traverse(child);
                }
            }
        }
        traverse(rootItem);
        return found;
    }

    function test_workspace_click() {
        var items = findRepeaterItems(workspaces);
        
        if (items.length === 0) {
            console.error("No items found. Dumping children of root:");
            if (workspaces.children) {
                for(var k=0; k<workspaces.children.length; k++) console.error(" - " + workspaces.children[k]);
            }
        }
        
        verify(items.length === 2, "Found 2 workspace items");
        
        var ws2 = null;
        for(var i=0; i<items.length; i++) {
            if (items[i].workspaceId === 20) {
                ws2 = items[i];
                break;
            }
        }
        verify(ws2, "Workspace 20 found");
        
        // Find MouseArea inside ws2
        var ma = null;
        if (ws2.children) {
            for(var j=0; j<ws2.children.length; j++) {
                if (ws2.children[j].toString().indexOf("QQuickMouseArea") !== -1) {
                    ma = ws2.children[j];
                    break;
                }
            }
        }
        
        verify(ma, "MouseArea found");
        mouseClick(ma);
        
        verify(lastFocusedId === 20, "Niri focus called with correct ID");
    }
}
