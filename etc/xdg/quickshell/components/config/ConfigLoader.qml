pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Paths
    readonly property string projectRoot: Quickshell.shellDir
    // userRoot is XDG_CONFIG_HOME/polar/shell/ for user overrides
    readonly property string userRoot: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/polar/shell"

    // Loaded and merged data
    property var config: ({})
    property var themes: ({})
    property var menus: ({})
    property var sessions: ([])

    // Loading state
    property bool configLoaded: false
    property bool themesLoaded: false
    property bool menusLoaded: false
    property bool sessionsLoaded: false
    property bool allLoaded: configLoaded && themesLoaded && menusLoaded && sessionsLoaded
    property bool readyToWatch: false
    property bool _isLoading: false
    property bool _pendingReload: false

    signal configReloaded()

    function reload() {
        if (_isLoading) {
            _pendingReload = true;
            return;
        }
        _isLoading = true;
        _pendingReload = false;
        configLoaded = false;
        themesLoaded = false;
        menusLoaded = false;
        sessionsLoaded = false;
        _projectThemesJson = "";
        _userThemesJson = "";
        _dynamicColorsJson = "";
        _projectConfigJson = "";
        _userConfigJson = "";
        _projectMenusJson = "";
        _userMenusJson = "";
        _projectSessionsJson = "";
        _userSessionsJson = "";
        _loadThemes();
        _loadMenus();
        _loadSessions();
    }

    function _checkLoadComplete() {
        if (allLoaded) {
            _isLoading = false;
            if (_pendingReload) {
                Qt.callLater(reload);
            }
        }
    }

    function init() {
        _initUserEnv.running = true;
    }

    Process {
        id: _initUserEnv
        command: ["sh", "-c", 
            "mkdir -p '" + root.userRoot + "' && " +
            "if [ ! -f '" + root.userRoot + "/config.json' ]; then echo '{}' > '" + root.userRoot + "/config.json'; fi && " +
            "if [ ! -f '" + root.userRoot + "/themes.json' ]; then echo '{\"themes\":{}}' > '" + root.userRoot + "/themes.json'; fi && " +
            "if [ ! -f '" + root.userRoot + "/menus.json' ]; then echo '{\"menus\":[], \"submenus\":{}}' > '" + root.userRoot + "/menus.json'; fi && " +
            "if [ ! -f '" + root.userRoot + "/sessions.json' ]; then echo '{\"sessions\":[]}' > '" + root.userRoot + "/sessions.json'; fi"
        ]
        onExited: (code) => {
            console.log("ConfigLoader: User environment initialized.");
            root.readyToWatch = true;
            root.reload();
        }
    }

    // ========== Deep Merge Utilities ==========

    // Deep merge: user overrides project, arrays are replaced, objects are merged
    function deepMerge(project, user) {
        if (user === undefined || user === null) return project;
        if (project === undefined || project === null) return user;

        // Arrays: user replaces project
        if (Array.isArray(project) || Array.isArray(user)) {
            return user;
        }

        // Objects: deep merge
        if (typeof project === 'object' && typeof user === 'object') {
            var result = {};
            // Copy all project keys
            for (var key in project) {
                if (project.hasOwnProperty(key)) {
                    result[key] = project[key];
                }
            }
            // Merge/override with user keys
            for (var ukey in user) {
                if (user.hasOwnProperty(ukey)) {
                    if (result.hasOwnProperty(ukey)) {
                        result[ukey] = deepMerge(result[ukey], user[ukey]);
                    } else {
                        result[ukey] = user[ukey];
                    }
                }
            }
            return result;
        }

        // Primitives: user wins
        return user;
    }

    // Merge menus: items with same name are replaced, new items are added
    // enabled: false items are filtered out
    function mergeMenuItems(projectItems, userItems) {
        if (!projectItems) projectItems = [];
        if (!userItems) userItems = [];

        // Create map by name for O(1) lookup
        var resultMap = {};
        var order = [];

        // Add all project items
        for (var i = 0; i < projectItems.length; i++) {
            var item = projectItems[i];
            var name = item.name || "";
            resultMap[name] = Object.assign({}, item);
            if (item.enabled === undefined) {
                resultMap[name].enabled = true;
            }
            order.push(name);
        }

        // Override/add user items
        for (var j = 0; j < userItems.length; j++) {
            var uitem = userItems[j];
            var uname = uitem.name || "";
            if (resultMap.hasOwnProperty(uname)) {
                // Replace (merge properties)
                resultMap[uname] = Object.assign({}, resultMap[uname], uitem);
            } else {
                // New item
                resultMap[uname] = Object.assign({ enabled: true }, uitem);
                order.push(uname);
            }
        }

        // Build result array, filtering disabled items
        var result = [];
        for (var k = 0; k < order.length; k++) {
            var n = order[k];
            if (resultMap[n] && resultMap[n].enabled !== false) {
                result.push(resultMap[n]);
            }
        }
        return result;
    }

    // Merge full menus structure
    function mergeMenus(project, user) {
        var result = { menus: [], submenus: {} };

        var pMenus = (project && project.menus) ? project.menus : [];
        var uMenus = (user && user.menus) ? user.menus : [];
        result.menus = mergeMenuItems(pMenus, uMenus);

        // Merge submenus
        var pSubs = (project && project.submenus) ? project.submenus : {};
        var uSubs = (user && user.submenus) ? user.submenus : {};

        var allSubKeys = {};
        for (var pk in pSubs) allSubKeys[pk] = true;
        for (var uk in uSubs) allSubKeys[uk] = true;

        for (var key in allSubKeys) {
            var pItems = pSubs[key] || [];
            var uItems = uSubs[key] || [];
            result.submenus[key] = mergeMenuItems(pItems, uItems);
        }

        return result;
    }

    // Merge themes: user can add new themes or override properties of existing ones
    function mergeThemes(project, user) {
        var result = {};

        var pThemes = (project && project.themes) ? project.themes : {};
        var uThemes = (user && user.themes) ? user.themes : {};

        // Copy project themes
        for (var pk in pThemes) {
            result[pk] = JSON.parse(JSON.stringify(pThemes[pk]));
        }

        // Merge user themes
        for (var uk in uThemes) {
            if (result.hasOwnProperty(uk)) {
                result[uk] = deepMerge(result[uk], uThemes[uk]);
            } else {
                result[uk] = JSON.parse(JSON.stringify(uThemes[uk]));
            }
        }

        // Filter disabled themes (if enabled: false)
        for (var key in result) {
            if (result[key].enabled === false) {
                delete result[key];
            }
        }

        return result;
    }

    // Merge sessions: user items with same name replace, new items are added
    function mergeSessions(project, user) {
        if (!project) project = [];
        if (!user) user = [];

        var resultMap = {};
        var order = [];

        for (var i = 0; i < project.length; i++) {
            var s = project[i];
            var name = s.name || ("session_" + i);
            resultMap[name] = Object.assign({}, s);
            order.push(name);
        }

        for (var j = 0; j < user.length; j++) {
            var us = user[j];
            var uname = us.name || ("user_session_" + j);
            if (resultMap.hasOwnProperty(uname)) {
                resultMap[uname] = Object.assign({}, resultMap[uname], us);
            } else {
                resultMap[uname] = Object.assign({}, us);
                order.push(uname);
            }
        }

        var result = [];
        for (var k = 0; k < order.length; k++) {
            result.push(resultMap[order[k]]);
        }
        return result;
    }

    // ========== File Loading ==========

    property string _projectThemesJson: ""
    property string _userThemesJson: ""
    property string _dynamicColorsJson: ""
    property string _staticColorsJson: ""
    property string _projectMenusJson: ""
    property string _userMenusJson: ""
    property string _projectSessionsJson: ""
    property string _userSessionsJson: ""
    property string _projectConfigJson: ""
    property string _userConfigJson: ""

    // ----- Themes -----
    function _loadThemes() {
        _projectThemesJson = "";
        _userThemesJson = "";
        _projectThemesReader.running = true;
    }

    Process {
        id: _projectThemesReader
        command: ["cat", root.projectRoot + "/themes.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._projectThemesJson += data
        }
        onExited: (code) => {
            if (_userThemesReader) _userThemesReader.running = true;
        }
    }

    Process {
        id: _userThemesReader
        command: ["cat", root.userRoot + "/themes.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._userThemesJson += data
        }
        onExited: (code) => {
            // Now read dynamic-colors.json
            if (_dynamicColorsReader) _dynamicColorsReader.running = true;
        }
    }

    Process {
        id: _dynamicColorsReader
        command: ["cat", root.projectRoot + "/dynamic-colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._dynamicColorsJson += data
        }
        onExited: (code) => {
            if (_staticColorsReader) _staticColorsReader.running = true;
        }
    }

    Process {
        id: _staticColorsReader
        command: ["cat", root.projectRoot + "/static-colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._staticColorsJson += data
        }
        onExited: (code) => {
            var projectData = null;
            var userData = null;
            var dynamicData = null;
            var staticData = null;
            try {
                if (root._projectThemesJson.trim()) {
                    projectData = JSON.parse(root._projectThemesJson);
                }
            } catch (e) {
                console.error("ConfigLoader: Failed to parse project themes.json:", e);
            }
            try {
                if (root._userThemesJson.trim()) {
                    userData = JSON.parse(root._userThemesJson);
                }
            } catch (e) {
                // User file may not exist, that's fine
            }
            try {
                if (root._dynamicColorsJson.trim()) {
                    dynamicData = JSON.parse(root._dynamicColorsJson);
                }
            } catch (e) {
                // Dynamic colors file may not exist yet
            }
            try {
                if (root._staticColorsJson.trim()) {
                    staticData = JSON.parse(root._staticColorsJson);
                }
            } catch (e) {
                // Static colors file may not exist yet
            }

            // Merge: project themes + user themes
            var merged = root.mergeThemes(projectData, userData);

            // Override dynamic/dynamic-inverted with matugen-generated colors
            if (dynamicData) {
                if (dynamicData["dynamic"]) {
                    merged["dynamic"] = root.deepMerge(merged["dynamic"] || {}, dynamicData["dynamic"]);
                }
                if (dynamicData["dynamic-inverted"]) {
                    merged["dynamic-inverted"] = root.deepMerge(merged["dynamic-inverted"] || {}, dynamicData["dynamic-inverted"]);
                }
            }

            // Override "current" theme with tinty-generated static colors
            if (staticData && staticData["current"]) {
                merged["current"] = root.deepMerge(merged["current"] || {}, staticData["current"]);
            }

            root.themes = merged;
            root._projectThemesJson = "";
            root._userThemesJson = "";
            root._dynamicColorsJson = "";
            root._staticColorsJson = "";
            root.themesLoaded = true;
            // Now load config (depends on themes)
            root._loadConfig();
        }
    }

    // ----- Config -----
    function _loadConfig() {
        _projectConfigJson = "";
        _userConfigJson = "";
        _projectConfigReader.running = true;
    }

    Process {
        id: _projectConfigReader
        command: ["cat", root.projectRoot + "/config.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._projectConfigJson += data
        }
        onExited: (code) => {
            if (_userConfigReader) _userConfigReader.running = true;
        }
    }

    Process {
        id: _userConfigReader
        command: ["cat", root.userRoot + "/config.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._userConfigJson += data
        }
        onExited: (code) => {
            var projectData = null;
            var userData = null;
            try {
                if (root._projectConfigJson.trim()) {
                    projectData = JSON.parse(root._projectConfigJson);
                }
            } catch (e) {
                console.error("ConfigLoader: Failed to parse project config.json:", e);
            }
            try {
                if (root._userConfigJson.trim()) {
                    userData = JSON.parse(root._userConfigJson);
                }
            } catch (e) {
                // User file may not exist
            }
            root.config = root.deepMerge(projectData || {}, userData || {});
            root._projectConfigJson = "";
            root._userConfigJson = "";
            root.configLoaded = true;
            root._checkLoadComplete();
            root.configReloaded();
        }
    }

    // ----- Menus -----
    function _loadMenus() {
        _projectMenusJson = "";
        _userMenusJson = "";
        _projectMenusReader.running = true;
    }

    Process {
        id: _projectMenusReader
        command: ["cat", root.projectRoot + "/menus.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._projectMenusJson += data
        }
        onExited: (code) => {
            if (_userMenusReader) _userMenusReader.running = true;
        }
    }

    Process {
        id: _userMenusReader
        command: ["cat", root.userRoot + "/menus.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._userMenusJson += data
        }
        onExited: (code) => {
            var projectData = null;
            var userData = null;
            try {
                if (root._projectMenusJson.trim()) {
                    projectData = JSON.parse(root._projectMenusJson);
                }
            } catch (e) {
                console.error("ConfigLoader: Failed to parse project menus.json:", e);
            }
            try {
                if (root._userMenusJson.trim()) {
                    userData = JSON.parse(root._userMenusJson);
                }
            } catch (e) {
                // User file may not exist
            }
            root.menus = root.mergeMenus(projectData, userData);
            root._projectMenusJson = "";
            root._userMenusJson = "";
            root.menusLoaded = true;
            root._checkLoadComplete();
        }
    }

    // ----- Sessions -----
    function _loadSessions() {
        _projectSessionsJson = "";
        _userSessionsJson = "";
        _projectSessionsReader.running = true;
    }

    Process {
        id: _projectSessionsReader
        command: ["cat", root.projectRoot + "/sessions.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._projectSessionsJson += data
        }
        onExited: (code) => {
            if (_userSessionsReader) _userSessionsReader.running = true;
        }
    }

    Process {
        id: _userSessionsReader
        command: ["cat", root.userRoot + "/sessions.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._userSessionsJson += data
        }
        onExited: (code) => {
            var projectData = null;
            var userData = null;
            try {
                if (root._projectSessionsJson.trim()) {
                    var pJson = JSON.parse(root._projectSessionsJson);
                    projectData = pJson.sessions || [];
                }
            } catch (e) {
                console.error("ConfigLoader: Failed to parse project sessions.json:", e);
            }
            try {
                if (root._userSessionsJson.trim()) {
                    var uJson = JSON.parse(root._userSessionsJson);
                    userData = uJson.sessions || [];
                }
            } catch (e) {
                // User file may not exist
            }
            root.sessions = root.mergeSessions(projectData || [], userData || []);
            root._projectSessionsJson = "";
            root._userSessionsJson = "";
            root.sessionsLoaded = true;
            root._checkLoadComplete();
        }
    }

    // ========== User Config Writing ==========

    // Current user-only config (what's actually in user's config.json, not merged)
    property var _userOnlyConfig: ({})
    property string _readUserConfigJson: ""

    // Read user config for merging before write
    function _readUserConfigForWrite(updates, callback) {
        _pendingUpdates = updates;
        _pendingWriteCallback = callback;
        _readUserConfigJson = "";
        _userConfigForWriteReader.running = true;
    }

    property var _pendingUpdates: ({})

    Process {
        id: _userConfigForWriteReader
        command: ["cat", root.userRoot + "/config.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._readUserConfigJson += data
        }
        onExited: (code) => {
            var existingConfig = {};
            try {
                if (root._readUserConfigJson.trim()) {
                    existingConfig = JSON.parse(root._readUserConfigJson);
                }
            } catch (e) {
                // File doesn't exist or invalid, start fresh
            }
            root._readUserConfigJson = "";
            
            // Merge updates into existing config
            var merged = root.deepMerge(existingConfig, root._pendingUpdates);
            root._writeUserConfigInternal(merged);
        }
    }

    function _writeUserConfigInternal(mergedConfig) {
        var json = JSON.stringify(mergedConfig, null, 2);
        var escaped = json.replace(/'/g, "'\\''");
        _userConfigWriter.command = ["sh", "-c", 
            "mkdir -p '" + userRoot + "' && printf '%s' '" + escaped + "' > '" + userRoot + "/config.json'"
        ];
        _userConfigWriter.running = true;
    }

    // Write user config.json (for theme/wallpaper/font changes)
    // Updates are merged with existing user config
    function writeUserConfig(updates, callback) {
        _readUserConfigForWrite(updates, callback);
    }

    property var _pendingWriteCallback: null

    Process {
        id: _userConfigWriter
        onExited: (code) => {
            if (root._pendingWriteCallback) {
                root._pendingWriteCallback(code === 0);
                root._pendingWriteCallback = null;
            }
            if (code === 0) {
                root.reload();
            }
        }
    }

    // ========== File Watchers for Hot Reload ==========

    // Watch user config files for changes
    FileView {
        id: _userConfigWatcher
        path: root.readyToWatch ? root.userRoot + "/config.json" : ""
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: User config.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _userThemesWatcher
        path: root.readyToWatch ? root.userRoot + "/themes.json" : ""
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: User themes.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _userMenusWatcher
        path: root.readyToWatch ? root.userRoot + "/menus.json" : ""
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: User menus.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _userSessionsWatcher
        path: root.readyToWatch ? root.userRoot + "/sessions.json" : ""
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: User sessions.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    // Watch project config files for changes (in case user edits them directly)
    FileView {
        id: _projectConfigWatcher
        path: root.projectRoot + "/config.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: Project config.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _projectThemesWatcher
        path: root.projectRoot + "/themes.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: Project themes.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _dynamicColorsWatcher
        path: root.projectRoot + "/dynamic-colors.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: dynamic-colors.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _staticColorsWatcher
        path: root.projectRoot + "/static-colors.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: static-colors.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _projectMenusWatcher
        path: root.projectRoot + "/menus.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: Project menus.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    FileView {
        id: _projectSessionsWatcher
        path: root.projectRoot + "/sessions.json"
        watchChanges: true
        onFileChanged: {
            console.log("ConfigLoader: Project sessions.json changed, reloading...");
            Qt.callLater(root.reload);
        }
    }

    Component.onCompleted: Qt.callLater(init)
}
