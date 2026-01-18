import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../../ui/carousel"
import QtQuick.Controls.Basic
import Quickshell 1.0
import Quickshell.Io 1.0
import "../base"
import ".."
import "."

Panel {
    id: root

    position: "bottom"

    // Property to force display (useful for binding to shortcuts)
    property string currentProvider: "desktopapplications"

    // Prevent auto-hide when forced or focused
    preventAutoHide: searchBar.inputFocus || isWallpaperMode || isThemeMode || isChatMode

    // Disable edge reveal (only open via shortcut/IPC)
    preventEdgeReveal: true

    // Only request keyboard focus when Launcher is active
    wantsFocus: true

    // Extended Mode Configuration
    hasExtendedMode: true
    
    // Width logic for carousels
    property int wallpaperDesiredWidth: Math.min(900, screen.width - 60)
    property int themeDesiredWidth: Math.min(900, screen.width - 60)
    
    contentWidth: isWallpaperMode ? wallpaperDesiredWidth : (isThemeMode ? themeDesiredWidth : (isChatMode ? screen.width * 0.3 : screen.width * 0.3))
    property real targetHeight: (isWallpaperMode || isThemeMode) ? 220 : (isChatMode ? 750 : Math.min(mainLayout.implicitHeight + (Config.padding * 2), screen.height * 0.3))
    contentPadding: 0 // Reset padding to match other panels

    Timer {
        id: activationDebounceTimer
        interval: 400
        repeat: false
        property string mode: ""
        property var item: null
        
        onTriggered: {
            console.log("Launcher: activationDebounceTimer triggered. Mode:", mode, "Item:", item ? item.themeId : "null");
            if (mode === "wallpaper" && item) {
                 wallpaperProvider.activate(item);
            } else if (mode === "theme" && item) {
                 console.log("Launcher: Timer activating theme:", item.themeId);
                 themeProvider.activate(item);
            }
        }
    }

    Timer {
        id: heightDebounceTimer
        interval: 300
        onTriggered: root.contentHeight = root.targetHeight
    }

    Timer {
        id: filterDebounceTimer
        interval: 200
        onTriggered: {
            if (isWallpaperMode) {
                var t = searchBar.text;
                if (t.indexOf(">wallpaper") === 0) {
                    var filterText = t.substring(10).trim();
                    wallpaperProvider.filter(filterText);
                }
            } else if (isThemeMode) {
                var t = searchBar.text;
                if (t.indexOf(">theme") === 0) {
                    var filterText = t.substring(6).trim();
                    themeProvider.filter(filterText);
                }
            } else {
                root.filter(searchBar.text);
            }
        }
    }

    onTargetHeightChanged: {
        if (Math.abs(contentHeight - targetHeight) > 1) {
             if (searchBar.text === "") {
                 heightDebounceTimer.stop();
                 root.contentHeight = root.targetHeight;
             } else {
                 heightDebounceTimer.restart();
             }
        }
    }

    onRevealedChanged: {
        if (revealed) {
            heightDebounceTimer.stop();
            contentHeight = targetHeight;
        }
    }

    extendedContentWidth: contentWidth + 100
    extendedContentHeight: contentHeight + 220

    ListModel {
        id: filteredApps
    }

    // Store reference to desktop entries for launching
    property var appEntriesMap: ({})

    // App usage frequency tracking
    property var appUsageData: ({})
    property string usageCachePath: Quickshell.cacheDir + "/launcher_usage.json"
    property bool usageFileExists: false

    // Load usage data from cache on startup
    FileView {
        id: usageFileView
        path: root.usageCachePath
        
        onLoaded: {
            root.usageFileExists = true;
            root.loadUsageData();
        }
        
        onLoadFailed: {
            // File doesn't exist yet, that's fine - create it
            root.usageFileExists = false;
            root.appUsageData = {};
            initCacheProcess.running = true;
        }
    }

    // Create cache file if it doesn't exist
    Process {
        id: initCacheProcess
        command: ["sh", "-c", "mkdir -p \"$(dirname '" + root.usageCachePath + "')\" && echo '{}' > '" + root.usageCachePath + "'"]
        onRunningChanged: {
            if (!running) {
                usageFileView.reload();
            }
        }
    }

    Component.onCompleted: {
        // FileView will trigger onLoaded or onLoadFailed
        // Initial filter to populate apps if already loaded
        filterApplications("");
    }

    // React to DesktopEntries loading/changing
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            if (currentProvider === "desktopapplications") {
                filterApplications(searchBar.text);
            }
        }
    }

    function loadUsageData() {
        var text = usageFileView.text;
        if (text && text.length > 0) {
            try {
                appUsageData = JSON.parse(text);
            } catch (e) {
                console.log("Could not parse usage cache, starting fresh");
                appUsageData = {};
            }
        } else {
            appUsageData = {};
        }
    }

    Process {
        id: saveProcess
        property string dataToSave: ""
        command: ["sh", "-c", "echo '" + dataToSave.replace(/'/g, "'\\''") + "' > " + root.usageCachePath]
    }

    function saveUsageData() {
        saveProcess.dataToSave = JSON.stringify(appUsageData);
        saveProcess.running = true;
    }

    function incrementAppUsage(appId) {
        if (!appId) return;
        var count = appUsageData[appId] || 0;
        appUsageData[appId] = count + 1;
        saveUsageData();
    }

    function getAppUsageScore(appId) {
        return appUsageData[appId] || 0;
    }

    function filterApplications(text) {
        filteredApps.clear();
        appEntriesMap = {};
        var apps = DesktopEntries.applications.values;
        var searchLower = text.toLowerCase();
        var results = [];

        for (var i = 0; i < apps.length; i++) {
            var app = apps[i];
            var nameLower = app.name.toLowerCase();
            var genericLower = (app.genericName || "").toLowerCase();
            var commentLower = (app.comment || "").toLowerCase();
            var keywordsStr = (app.keywords || []).join(" ").toLowerCase();
            var appId = app.id || "";

            // Check if search matches name, genericName, comment or keywords
            if (searchLower === "" ||
                nameLower.includes(searchLower) ||
                genericLower.includes(searchLower) ||
                commentLower.includes(searchLower) ||
                keywordsStr.includes(searchLower)) {

                var matchScore = 0;
                // Prioritize exact name match
                if (searchLower !== "") {
                    if (nameLower === searchLower) matchScore = 1000;
                    else if (nameLower.startsWith(searchLower)) matchScore = 100;
                    else if (nameLower.includes(searchLower)) matchScore = 50;
                    else if (genericLower.includes(searchLower)) matchScore = 25;
                    else if (keywordsStr.includes(searchLower)) matchScore = 10;
                }

                // Add usage frequency score (capped to prevent dominance)
                var usageScore = Math.min(getAppUsageScore(appId) * 5, 200);
                var totalScore = matchScore + usageScore;

                results.push({
                    entry: app,
                    score: totalScore
                });
            }
        }

        // Sort by score (descending) then by name
        results.sort(function(a, b) {
            if (b.score !== a.score) return b.score - a.score;
            return a.entry.name.localeCompare(b.entry.name);
        });

        // Limit to 50 results and populate model
        var limit = Math.min(results.length, 50);
        for (var j = 0; j < limit; j++) {
            var entry = results[j].entry;
            var id = entry.id || ("app_" + j);
            appEntriesMap[id] = entry;
            
            // Use generic icon if app has no icon
            var iconName = entry.icon || "application-x-executable";
            
            filteredApps.append({
                "name": entry.name || "",
                "icon": iconName,
                "desc": entry.genericName || entry.comment || "",
                "identifier": id,
                "provider": "desktopapplications",
                "action": "start"
            });
        }
    }

    MenuProvider {
        id: menuProvider
        onItemActivated: action => {
            root.revealed = false;
            searchBar.inputFocus = false;
        }
    }

    FontProvider {
        id: fontProvider
    }

    IconThemeProvider {
        id: iconThemeProvider
    }

    SessionProvider {
        id: sessionProvider
        onSessionActivated: sessionName => {
            root.revealed = false;
            searchBar.inputFocus = false;
        }
    }

    WallpaperProvider {
        id: wallpaperProvider
        onWallpaperSelected: path => {
            // Don't close on selection change, allow browsing
        }
    }

    ThemeProvider {
        id: themeProvider
        onThemeSelected: themeId => {
            // Don't close on selection change, allow browsing
        }
    }

    ChatProvider {
        id: chatProvider
    }

    property bool isMenuMode: currentProvider === "menus"
    property bool isWallpaperMode: currentProvider === "wallpapers"
    property bool isThemeMode: currentProvider === "themes"
    property bool isFontMode: currentProvider === "fonts"
    property bool isIconThemeMode: currentProvider === "iconThemes"
    property bool isSessionsMode: currentProvider === "sessions"
    property bool isChatMode: currentProvider === "chat"
    
    // Hidden search query for carousel modes (wallpapers/themes)
    property string carouselSearchQuery: ""
    
    // Helper function to highlight matching text
    function highlightText(text, query, baseColor) {
        if (!query || query.length === 0) {
            return text;
        }
        var lowerText = text.toLowerCase();
        var lowerQuery = query.toLowerCase();
        var result = "";
        var lastIndex = 0;
        var index = lowerText.indexOf(lowerQuery);
        while (index !== -1) {
            result += text.substring(lastIndex, index);
            result += "<font color=\"" + Config.accent + "\"><b>" + text.substring(index, index + query.length) + "</b></font>";
            lastIndex = index + query.length;
            index = lowerText.indexOf(lowerQuery, lastIndex);
        }
        result += text.substring(lastIndex);
        return result;
    }
    
    property var activeModel: {
        if (isMenuMode) return menuProvider.model;
        if (isWallpaperMode) return wallpaperProvider.model;
        if (isThemeMode) return themeProvider.model;
        if (isFontMode) return fontProvider.model;
        if (isIconThemeMode) return iconThemeProvider.model;
        if (isSessionsMode) return sessionProvider.model;
        return filteredApps;
    }
    function showThemes() {
        if (root.revealed && root.currentProvider === "themes") {
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        root.currentProvider = "themes";
        searchBar.text = ">theme ";
        root.carouselSearchQuery = "";
        themeProvider.load();
        
        if (!root.revealed) {
            root.revealed = true;
        }
    }

    function showChat() {
        if (root.revealed && root.currentProvider === "chat") {
            root.revealed = false;
            return;
        }

        root.currentProvider = "chat";
        searchBar.text = "";
        chatProvider.init();
        
        if (!root.revealed) {
            root.revealed = true;
        }
    }

    function showWallpapers() {
        if (root.revealed && root.currentProvider === "wallpapers") {
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        root.currentProvider = "wallpapers";
        searchBar.text = ">wallpaper ";
        root.carouselSearchQuery = "";
        wallpaperProvider.load();
        
        if (!root.revealed) {
            root.revealed = true;
        }
        
        Qt.callLater(() => {
            wallpaperCarousel.forceActiveFocus();
        });
    }

    function toggleFonts() {
        if (root.revealed && root.currentProvider === "fonts") {
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        root.currentProvider = "fonts";
        searchBar.text = "";
        fontProvider.load();
        
        if (!root.revealed) {
            root.revealed = true;
        }
        
        Qt.callLater(() => {
            searchBar.inputFocus = true;
        });
    }

    function toggleIconThemes() {
        if (root.revealed && root.currentProvider === "iconThemes") {
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        root.currentProvider = "iconThemes";
        searchBar.text = "";
        iconThemeProvider.load();
        
        if (!root.revealed) {
            root.revealed = true;
        }
        
        Qt.callLater(() => {
            searchBar.inputFocus = true;
        });
    }

    IpcHandler {
        target: "ui.dialog.launcher.wallpapers"
        function toggle() { root.showWallpapers() }
        function open() { 
            if (!root.revealed || root.currentProvider !== "wallpapers") {
                root.showWallpapers()
            }
        }
        function close() {
            if (root.revealed && root.currentProvider === "wallpapers") {
                root.revealed = false;
                searchBar.inputFocus = false;
            }
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher.themes"
        function toggle() { root.showThemes() }
        function open() { 
            if (!root.revealed || root.currentProvider !== "themes") {
                root.showThemes()
            }
        }
        function close() {
            if (root.revealed && root.currentProvider === "themes") {
                root.revealed = false;
                searchBar.inputFocus = false;
            }
        }
    }

    IpcHandler {
        target: "ui.config"
        function reload() {
            Config.reload();
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher"

        function open() {
            if (!root.revealed) {
                // Default to apps if not specified, or keep current?
                // Default to apps to match toggle behavior reset
                root.currentProvider = "desktopapplications";
                searchBar.text = "";
                root.filter("");
                root.revealed = true;
                Qt.callLater(() => { searchBar.inputFocus = true; });
            }
        }

        function close() {
            root.revealed = false;
            searchBar.inputFocus = false;
        }

        function toggle() {
            if (root.revealed && root.currentProvider === "desktopapplications") {
                root.revealed = false;
                searchBar.inputFocus = false;
                return;
            }

            root.currentProvider = "desktopapplications";
            searchBar.text = "";
            root.filter("");
            
            if (!root.revealed) {
                root.revealed = true;
            }
            
            Qt.callLater(() => {
                searchBar.inputFocus = true;
            });
        }

        function toggleMenu() {
            if (root.revealed && root.currentProvider === "menus") {
                root.revealed = false;
                searchBar.inputFocus = false;
                return;
            }

            root.currentProvider = "menus";
            searchBar.text = "";
            root.filter("");
            
            if (!root.revealed) {
                root.revealed = true;
            }
            
            Qt.callLater(() => {
                searchBar.inputFocus = true;
            });
        }

        function toggleWallpapers() {
            root.showWallpapers()
        }

        function toggleFonts() {
            root.toggleFonts()
        }

        function toggleThemes() {
            root.showThemes()
        }

        function toggleSessions() {
            if (root.revealed && root.currentProvider === "sessions") {
                root.revealed = false;
                searchBar.inputFocus = false;
                return;
            }

            root.currentProvider = "sessions";
            searchBar.text = "";
            sessionProvider.load();
            
            if (!root.revealed) {
                root.revealed = true;
            }
            
            Qt.callLater(() => {
                searchBar.inputFocus = true;
            });
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher.fonts"
        function toggle() { root.toggleFonts() }
        function open() {
             root.currentProvider = "fonts";
             searchBar.text = "";
             fontProvider.load();
             root.revealed = true;
             Qt.callLater(() => { searchBar.inputFocus = true; });
        }
        function close() {
             if (root.revealed && root.currentProvider === "fonts") {
                 root.revealed = false;
                 searchBar.inputFocus = false;
             }
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher.icons"
        function toggle() { root.toggleIconThemes() }
        function open() {
             root.currentProvider = "iconThemes";
             searchBar.text = "";
             iconThemeProvider.load();
             root.revealed = true;
             Qt.callLater(() => { searchBar.inputFocus = true; });
        }
        function close() {
             if (root.revealed && root.currentProvider === "iconThemes") {
                 root.revealed = false;
                 searchBar.inputFocus = false;
             }
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher.chat"
        function toggle() { root.showChat() }
        function open() {
            if (!root.revealed || root.currentProvider !== "chat") {
                root.showChat();
            }
        }
        function close() {
            if (root.revealed && root.currentProvider === "chat") {
                root.revealed = false;
            }
        }
    }

    IpcHandler {
        target: "ui.dialog.launcher.sessions"
        function toggle() {
            if (root.revealed && root.currentProvider === "sessions") {
                root.revealed = false;
                searchBar.inputFocus = false;
                return;
            }

            root.currentProvider = "sessions";
            searchBar.text = "";
            sessionProvider.load();
            
            if (!root.revealed) {
                root.revealed = true;
            }
            
            Qt.callLater(() => {
                searchBar.inputFocus = true;
            });
        }
        function open() {
             root.currentProvider = "sessions";
             searchBar.text = "";
             sessionProvider.load();
             root.revealed = true;
             Qt.callLater(() => { searchBar.inputFocus = true; });
        }
        function close() {
             if (root.revealed && root.currentProvider === "sessions") {
                 root.revealed = false;
                 searchBar.inputFocus = false;
             }
        }
    }

        Shortcut {
            sequence: "Escape"
            enabled: root.revealed
            onActivated: {
                if (isWallpaperMode || isThemeMode) {
                    root.revealed = false;
                    searchBar.inputFocus = false;
                    return;
                }

                if (isChatMode) {
                    root.revealed = false;
                    return;
                }

                if (searchBar.text !== "") {
                    searchBar.text = "";
                    root.filter("");
                } else if (isMenuMode && menuProvider.goBack()) {
                    searchBar.text = "";
                } else {
                    root.revealed = false;
                    searchBar.inputFocus = false;
                }
            }
        }

    function filter(text) {
        if (isMenuMode) {
            menuProvider.filter(text);
        } else if (isWallpaperMode) {
            wallpaperProvider.filter(text);
        } else if (isThemeMode) {
            themeProvider.filter(text);
        } else if (isFontMode) {
            fontProvider.filter(text);
        } else if (isIconThemeMode) {
            iconThemeProvider.filter(text);
        } else if (isSessionsMode) {
            sessionProvider.filter(text);
        } else {
            filterApplications(text);
        }
    }

    function launch(item) {
        console.log("Launch called, currentProvider:", currentProvider, "item:", JSON.stringify(item));

        if (isMenuMode) {
            var shouldClose = menuProvider.activate(item);
            console.log("MenuProvider.activate returned:", shouldClose);
            
            if (shouldClose) {
                root.revealed = false;
                searchBar.inputFocus = false;
            }
            return;
        }

        if (isFontMode) {
            fontProvider.activate(item);
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        if (isIconThemeMode) {
            iconThemeProvider.activate(item);
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        if (isSessionsMode) {
            sessionProvider.activate(item);
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        if (isThemeMode) {
            themeProvider.activate(item);
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        if (isWallpaperMode) {
            wallpaperProvider.activate(item);
            root.revealed = false;
            searchBar.inputFocus = false;
            return;
        }

        // Desktop applications: use native DesktopEntry.execute()
        if (item && item.identifier) {
            var entry = appEntriesMap[item.identifier];
            if (entry) {
                console.log("Executing app:", entry.name);
                incrementAppUsage(item.identifier);
                entry.execute();
            } else {
                console.error("No desktop entry found for:", item.identifier);
            }
        }

        root.revealed = false;
        searchBar.inputFocus = false;
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Config.padding // Manual padding
        spacing: 15

        // Contenido Principal (Apps o Wallpapers)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !isWallpaperMode && !isThemeMode && !isChatMode
            implicitHeight: (isWallpaperMode || isThemeMode) ? 200 : (isChatMode ? 0 : resultsList.contentHeight)
            Layout.margins: (isWallpaperMode || isThemeMode) ? 0 : 0
            visible: !isChatMode

            // Apps List
            ListView {
                id: resultsList
                visible: !isWallpaperMode && !isThemeMode
                anchors.fill: parent
                clip: true
                model: activeModel
                spacing: 5

                highlight: Rectangle {
                    color: Config.foreground
                    radius: Config.itemRadius
                    opacity: 1
                    z: 0
                }
                highlightMoveDuration: 250
                highlightMoveVelocity: -1
                highlightResizeDuration: 0

                keyNavigationEnabled: true
                focus: !isWallpaperMode && !isThemeMode

                delegate: LauncherDelegate {
                    name: model.name
                    icon: model.icon
                    desc: model.desc
                    provider: model.provider || ""
                    index: index

                    onHovered: idx => resultsList.currentIndex = idx
                    onLaunched: {
                        console.log("Delegate onLaunched, index:", index);
                        root.launch(activeModel.get(index));
                    }
                }

                onCountChanged: {
                    if (currentIndex < 0 && count > 0) currentIndex = 0;
                }
            }

            // Wallpaper Search Label
            Text {
                visible: isWallpaperMode && root.carouselSearchQuery.length > 0
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 5
                text: "Searching: \"" + root.carouselSearchQuery + "\""
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Config.accent
                z: 100
            }

            // Wallpapers Carousel
            CarouselView {
                id: wallpaperCarousel
                visible: isWallpaperMode
                anchors.centerIn: parent
                width: parent.width
                height: 180 // Increased height for scale
                
                // Unified style with themes
                cardWidth: 220
                cardHeight: 130
                itemPadding: 20
                visibleItems: 3
                sideScale: 0.7
                selectedScale: 1.02
                clip: true
                
                model: wallpaperProvider.currentList
                
                focus: isWallpaperMode
                
                onCurrentIndexChanged: {
                    if (visible && model && model.length > 0 && currentIndex >= 0 && currentIndex < model.length) {
                        var item = model[currentIndex];
                        activationDebounceTimer.mode = "wallpaper";
                        activationDebounceTimer.item = item;
                        activationDebounceTimer.restart();
                    }
                }

                // Key Navigation for PathView
                Keys.onLeftPressed: decrementCurrentIndex()
                Keys.onRightPressed: incrementCurrentIndex()
                Keys.onReturnPressed: {
                    if (model.count > 0) {
                        var item = wallpaperProvider.model.get(currentIndex);
                        if (item) wallpaperProvider.activate(item);
                    }
                    root.revealed = false;
                    searchBar.inputFocus = false;
                }
                Keys.onPressed: (event) => {
                    // Handle backspace
                    if (event.key === Qt.Key_Backspace) {
                        if (root.carouselSearchQuery.length > 0) {
                            root.carouselSearchQuery = root.carouselSearchQuery.slice(0, -1);
                            wallpaperProvider.filter(root.carouselSearchQuery);
                        }
                        event.accepted = true;
                        return;
                    }
                    // Handle printable characters
                    if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
                        root.carouselSearchQuery += event.text;
                        wallpaperProvider.filter(root.carouselSearchQuery);
                        event.accepted = true;
                    }
                }

                // Sync with provider
                Connections {
                    target: wallpaperProvider
                    function onCurrentIndexChanged() {
                        if (wallpaperProvider.currentIndex >= 0) {
                            wallpaperCarousel.currentIndex = wallpaperProvider.currentIndex
                        }
                    }
                }
                
                // Initial sync
                onVisibleChanged: {
                    if (visible) {
                        forceActiveFocus();
                        if (wallpaperProvider.currentIndex >= 0) {
                            currentIndex = wallpaperProvider.currentIndex
                        }
                    }
                }

                onSelected: (modelData) => {
                    if (modelData) wallpaperProvider.activate(modelData)
                    root.revealed = false
                }

                delegate: Component {
                    Item {
                        property var modelData: null
                        property int index: 0
                        property bool isCurrentItem: false
                        
                        anchors.fill: parent

                        // Content (Card)
                        Rectangle {
                            id: card
                            anchors.fill: parent
                            radius: Config.radius
                            color: Config.background
                            
                            Image {
                                id: wallImg
                                anchors.fill: parent
                                source: modelData ? "file://" + modelData.path : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: width * 2
                                sourceSize.height: height * 2
                                visible: false
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: Rectangle {
                                        width: wallImg.width
                                        height: wallImg.height
                                        radius: Config.radius
                                    }
                                }
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: wallImg
                                maskEnabled: true
                                maskSource: mask
                            }

                            Rectangle {
                                id: mask
                                anchors.fill: parent
                                radius: Config.radius
                                visible: false
                                layer.enabled: true
                            }

                            // Hover State
                            Rectangle {
                                id: stateLayer
                                anchors.fill: parent
                                radius: Config.radius
                                color: "transparent"
                                z: 10
                                Behavior on color { ColorAnimation { duration: Config.animDurationFast } }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                onEntered: stateLayer.color = Qt.alpha(Config.foreground, 0.1)
                                onExited: stateLayer.color = "transparent"
                            }
                        }

                        // Selected Border - Outer Halo (Overlay)
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            color: "transparent"
                            border.color: Config.accent
                            border.width: 3
                            radius: Config.radius + 4
                            visible: isCurrentItem
                            z: 200
                        }
                    }
                }
            }

            // Theme Search Label
            Text {
                visible: isThemeMode && root.carouselSearchQuery.length > 0
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 5
                text: "Searching: \"" + root.carouselSearchQuery + "\""
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Config.accent
                z: 100
            }

            // Themes Carousel
            CarouselView {
                id: themeCarousel
                visible: isThemeMode
                anchors.centerIn: parent
                width: parent.width
                height: 180
                
                // Unified style with wallpapers
                cardWidth: 220
                cardHeight: 130
                itemPadding: 20
                visibleItems: 3
                sideScale: 0.7
                selectedScale: 1.02
                clip: true

                model: themeProvider.currentList

                focus: isThemeMode
                
                onCurrentIndexChanged: {
                    if (_skipNextActivation) return;
                    if (visible && model && model.length > 0 && currentIndex >= 0 && currentIndex < model.length) {
                        var item = model[currentIndex];
                        activationDebounceTimer.mode = "theme";
                        activationDebounceTimer.item = item;
                        activationDebounceTimer.restart();
                    }
                }
                
                Keys.onLeftPressed: decrementCurrentIndex()
                Keys.onRightPressed: incrementCurrentIndex()
                Keys.onReturnPressed: {
                    if (model.count > 0) {
                        var item = themeProvider.model.get(currentIndex);
                        if (item) themeProvider.activate(item);
                    }
                    root.revealed = false;
                    searchBar.inputFocus = false;
                }
                Keys.onPressed: (event) => {
                    // Handle backspace
                    if (event.key === Qt.Key_Backspace) {
                        if (root.carouselSearchQuery.length > 0) {
                            root.carouselSearchQuery = root.carouselSearchQuery.slice(0, -1);
                            themeProvider.filter(root.carouselSearchQuery);
                        }
                        event.accepted = true;
                        return;
                    }
                    // Handle printable characters
                    if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
                        root.carouselSearchQuery += event.text;
                        themeProvider.filter(root.carouselSearchQuery);
                        event.accepted = true;
                    }
                }

                Connections {
                    target: themeProvider
                    function onCurrentIndexChanged() {
                        if (themeProvider.currentIndex >= 0) {
                            themeCarousel.currentIndex = themeProvider.currentIndex
                        }
                    }
                }
                
                onVisibleChanged: {
                    if (visible) {
                        _skipNextActivation = true;
                        activationDebounceTimer.stop();
                        forceActiveFocus();
                        if (themeProvider.currentIndex >= 0) {
                            currentIndex = themeProvider.currentIndex
                        }
                        Qt.callLater(function() { _skipNextActivation = false; });
                    }
                }
                
                property bool _skipNextActivation: false

                onSelected: (modelData) => {
                    if (modelData) themeProvider.activate(modelData)
                    root.revealed = false
                }

                delegate: Component {
                    Item {
                        property var modelData: ({ background: Config.background, foreground: Config.foreground, name: "", accent: Config.red })
                        property int index: 0
                        property bool isCurrentItem: false
                        
                        anchors.fill: parent

                        // Content
                        Rectangle {
                            id: card
                            anchors.fill: parent
                            radius: Config.radius
                            color: modelData.background
                            
                            // Mask content to radius
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: themeMask
                            }
                            
                            Rectangle {
                                id: themeMask
                                anchors.fill: parent
                                radius: Config.radius
                                visible: false
                                layer.enabled: true
                            }

                            // Color swatches
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                spacing: 4
                                z: 2

                                Repeater {
                                    model: [
                                        modelData.foreground,
                                        modelData.accent
                                    ]
                                    
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: modelData
                                        border.width: 1
                                        border.color: Qt.alpha(Config.foreground, 0.2)
                                    }
                                }
                            }

                            // Theme name
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 12
                                z: 2
                                
                                text: root.highlightText(modelData.name, root.carouselSearchQuery, modelData.foreground)
                                textFormat: Text.RichText
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: modelData.foreground
                            }
                            
                            Rectangle {
                                id: stateLayer
                                anchors.fill: parent
                                radius: Config.radius
                                color: "transparent"
                                z: 10
                                Behavior on color { ColorAnimation { duration: Config.animDurationFast } }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                onEntered: stateLayer.color = Qt.alpha(Config.foreground, 0.08)
                                onExited: stateLayer.color = "transparent"
                            }
                        }

                        // Selected Border - Outer Halo (Overlay)
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            color: "transparent"
                            border.color: Config.accent
                            border.width: 3
                            radius: Config.radius + 4
                            visible: isCurrentItem
                            z: 200
                        }
                    }
                }
            }
        }

        // Chat View
        ChatView {
            id: chatView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: isChatMode
            isActive: isChatMode && root.revealed
            provider: chatProvider
            onCloseRequested: {
                root.revealed = false;
            }
        }
                            
        // Search Bar (Always visible at bottom in app mode)
        LauncherSearchBar {
            id: searchBar
            Layout.fillWidth: true
            visible: !isWallpaperMode && !isThemeMode && !isChatMode
            
            onTextChanged: {
                if (searchBar.text === "") {
                    filterDebounceTimer.stop();
                    if (isWallpaperMode || isThemeMode) {
                        // Carousel clean logic if needed
                    } else {
                        root.filter("");
                    }
                    return;
                }
                filterDebounceTimer.restart();
            }
            
            onAccepted: {
                if (isWallpaperMode || isThemeMode) {
                    root.revealed = false;
                } else {
                    if (activeModel.count > 0) {
                        var item = activeModel.get(resultsList.currentIndex);
                        root.launch(item);
                    }
                }
            }
            
            onUpPressed: {
                if (isWallpaperMode || isThemeMode) return;
                if (resultsList.currentIndex > 0) resultsList.currentIndex--;
            }
            onDownPressed: {
                if (isWallpaperMode || isThemeMode) return;
                if (resultsList.currentIndex < resultsList.count - 1) resultsList.currentIndex++;
            }
        }
    }
}
