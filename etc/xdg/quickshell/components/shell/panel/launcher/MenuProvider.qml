import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"

Item {
    id: root

    property alias model: menuModel
    property string currentSubmenu: ""

    signal itemActivated(string action)

    ListModel {
        id: menuModel
    }

    function load() {
        menuModel.clear();
        currentSubmenu = "";
        // Trigger reload if not loaded yet
        if (!ConfigLoader.menusLoaded) {
            ConfigLoader.reload();
        } else {
            filter("");
        }
    }

    // React to ConfigLoader changes
    Connections {
        target: ConfigLoader
        function onMenusLoadedChanged() {
            if (ConfigLoader.menusLoaded) {
                root.filter("");
            }
        }
    }

    function filter(text) {
        var menuData = ConfigLoader.menus;
        if (!menuData) return;

        menuModel.clear();
        var items = currentSubmenu ? menuData.submenus[currentSubmenu] : menuData.menus;
        if (!items) return;

        var searchLower = text.toLowerCase();
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            
            // Skip disabled items (ConfigLoader already filters, but double-check)
            if (item.enabled === false) continue;
            
            var nameLower = (item.name || "").toLowerCase();
            var descLower = (item.desc || "").toLowerCase();

            if (searchLower === "" || nameLower.indexOf(searchLower) !== -1 || descLower.indexOf(searchLower) !== -1) {
                menuModel.append({
                    "name": item.name || "",
                    "icon": item.icon || "",
                    "desc": item.desc || "",
                    "action": item.action || "",
                    "identifier": item.name || "",
                    "provider": "menus"
                });
            }
        }
    }

    function activate(item) {
        if (!item) return false;

        var action = item.action || "";
        if (action === "") return false;

        console.log("MenuProvider activating:", action);

        if (action.indexOf("submenu:") === 0) {
            var submenuName = action.substring(8);
            currentSubmenu = submenuName;
            filter("");
            return false;
        }

        if (action.indexOf("ipc:") === 0) {
            var ipcCmd = action.substring(4);
            var parts = ipcCmd.split(".");
            if (parts.length >= 2) {
                var func = parts.pop();
                var target = parts.join(".");
                console.log("Calling IPC:", target, func);
                
                // Use qs ipc call which is standard for IpcHandler functions
                Quickshell.execDetached(["qs", "ipc", "call", target, func]);
                
                // Don't close launcher if targeting launcher itself
                if (target === "launcher") return false;
            }
            return true;
        }

        if (action.indexOf("exec:") === 0) {
            var cmd = action.substring(5);
            console.log("Executing command:", cmd);
            Quickshell.execDetached(["sh", "-c", cmd]);
            return true;
        }

        root.itemActivated(action);
        return true;
    }

    function goBack() {
        if (currentSubmenu !== "") {
            currentSubmenu = "";
            filter("");
            return true;
        }
        return false;
    }

    Component.onCompleted: load()
}
