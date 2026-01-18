import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"

Item {
    id: root

    property alias model: sessionModel
    property var sessions: []

    signal sessionActivated(string sessionName)

    ListModel {
        id: sessionModel
    }

    function load() {
        sessionModel.clear();
        sessions = [];
        
        if (!ConfigLoader.sessionsLoaded) {
            ConfigLoader.reload();
        } else {
            _buildSessionsList();
        }
    }

    // React to ConfigLoader changes
    Connections {
        target: ConfigLoader
        function onSessionsLoadedChanged() {
            if (ConfigLoader.sessionsLoaded) {
                root._buildSessionsList();
            }
        }
    }

    function _buildSessionsList() {
        root.sessions = ConfigLoader.sessions || [];
        root.filter("");
    }

    function filter(text) {
        sessionModel.clear();
        var searchLower = text.toLowerCase();

        for (var i = 0; i < sessions.length; i++) {
            var session = sessions[i];
            var nameLower = (session.name || "").toLowerCase();
            var descLower = (session.desc || "").toLowerCase();

            if (searchLower === "" || nameLower.indexOf(searchLower) !== -1 || descLower.indexOf(searchLower) !== -1) {
                sessionModel.append({
                    "name": session.name || "",
                    "icon": session.icon || "󰐥",
                    "desc": session.desc || "",
                    "action": "session:" + i,
                    "identifier": "session_" + i,
                    "provider": "sessions",
                    "sessionIndex": i
                });
            }
        }
    }

    function activate(item) {
        if (!item) return false;

        var idx = item.sessionIndex;
        if (idx === undefined || idx < 0 || idx >= sessions.length) return false;

        var session = sessions[idx];
        if (!session || !session.apps) return false;

        console.log("SessionProvider: Launching session:", session.name);

        // Group apps by workspace
        var workspaceApps = {};
        var workspaceOrder = [];
        
        for (var i = 0; i < session.apps.length; i++) {
            var app = session.apps[i];
            var ws = app.workspace || "__current__";
            
            if (!workspaceApps[ws]) {
                workspaceApps[ws] = [];
                workspaceOrder.push(ws);
            }
            workspaceApps[ws].push(app.command);
        }

        // Launch apps grouped by workspace
        for (var j = 0; j < workspaceOrder.length; j++) {
            var workspace = workspaceOrder[j];
            var commands = workspaceApps[workspace];
            launchAppsInWorkspace(commands, workspace === "__current__" ? "" : workspace);
        }

        root.sessionActivated(session.name);
        return true;
    }

    function launchAppsInWorkspace(commands, workspace) {
        if (!commands || commands.length === 0) return;

        // Build the launch script:
        // For named workspaces: create new workspace, name it, spawn all apps
        // For current workspace: just spawn
        var script = "";
        
        if (workspace && workspace !== "") {
            // Create a named workspace:
            // 1. Create a new empty workspace (focus-workspace-down from last)
            // 2. Name it with set-workspace-name
            // 3. Spawn all apps
            script = "niri msg action focus-workspace-down";
            script += " && niri msg action set-workspace-name '" + workspace + "'";
            script += " && sleep 0.1";
            
            for (var i = 0; i < commands.length; i++) {
                script += " && niri msg action spawn -- " + commands[i];
                if (i < commands.length - 1) {
                    script += " && sleep 0.05";
                }
            }
        } else {
            // No workspace specified, just spawn in current
            for (var i = 0; i < commands.length; i++) {
                if (i > 0) script += " && sleep 0.05 && ";
                script += "niri msg action spawn -- " + commands[i];
            }
        }

        console.log("SessionProvider: Executing:", script);
        Quickshell.execDetached(["sh", "-c", script]);
    }

    function goBack() {
        return false;
    }

    Component.onCompleted: load()
}
