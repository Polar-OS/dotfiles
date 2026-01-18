import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"

Item {
    id: root

    property alias model: themeModel
    property var themes: []
    property var currentList: []
    property int currentIndex: 0
    property string currentFilter: ""

    signal themeSelected(string themeId)

    ListModel {
        id: themeModel
    }

    property string currentThemeId: ""
    property bool loading: false
    
    property var _pendingThemes: []
    property int _currentLoadIndex: 0
    property bool _colorsLoading: false

    function load() {
        if (loading) return;
        loading = true;
        currentFilter = ""; // Reset filter on load
        // Use shellTheme if set, otherwise fallback to theme
        currentThemeId = ConfigLoader.config.shellTheme || Config.currentTheme;
        
        if (!ConfigLoader.themesLoaded) {
            ConfigLoader.reload();
        } else {
            _buildInitialList();
        }
    }

    Connections {
        target: ConfigLoader
        function onThemesLoadedChanged() {
            if (ConfigLoader.themesLoaded && loading) {
                root._buildInitialList();
            }
        }
    }

    function _buildInitialList() {
        var themesData = ConfigLoader.themes || {};
        var enabledThemes = ConfigLoader.config.enabledThemes || [];
        var themeKeys = enabledThemes.length > 0 ? enabledThemes : Object.keys(themesData);
        
        _pendingThemes = [];
        themes = [];
        
        for (var i = 0; i < themeKeys.length; i++) {
            var key = themeKeys[i];
            var t = themesData[key];
            
            if (t && t.colors) {
                themes.push({
                    id: key,
                    name: t.name || _formatThemeName(key),
                    background: t.colors.background || "#1a1b26",
                    foreground: t.colors.foreground || "#c0caf5",
                    accent: t.colors.accent || "#7aa2f7",
                    loaded: true
                });
            } else {
                themes.push({
                    id: key,
                    name: _formatThemeName(key),
                    background: "#2d2d2d",
                    foreground: "#888888",
                    accent: "#555555",
                    loaded: false
                });
                if (key.startsWith("base16-")) {
                    _pendingThemes.push(i);
                }
            }
        }
        
        filter(currentFilter);
        loading = false;
        
        if (_pendingThemes.length > 0 && !_colorsLoading) {
            _currentLoadIndex = 0;
            _colorsLoading = true;
            _loadNextThemeColors();
        }
    }
    
    function _loadNextThemeColors() {
        if (_currentLoadIndex >= _pendingThemes.length) {
            _colorsLoading = false;
            return;
        }
        
        var themeIdx = _pendingThemes[_currentLoadIndex];
        var schemeId = themes[themeIdx].id;
        _tintyInfoProc.themeIndex = themeIdx;
        _tintyInfoProc.schemeId = schemeId;
        _tintyInfoProc.output = "";
        _tintyInfoProc.command = ["tinty", "info", schemeId];
        _tintyInfoProc.running = true;
    }
    
    Process {
        id: _tintyInfoProc
        property int themeIndex: -1
        property string schemeId: ""
        property string output: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _tintyInfoProc.output += data
        }
        
        onExited: (code) => {
            if (code === 0 && themeIndex >= 0 && themeIndex < root.themes.length) {
                var colors = root._parseTintyInfo(output, schemeId);
                root._updateThemeColors(themeIndex, colors);
            }
            root._currentLoadIndex++;
            Qt.callLater(root._loadNextThemeColors);
        }
    }
    
    function _updateThemeColors(idx, colors) {
        if (idx < 0 || idx >= themes.length) return;
        
        var theme = themes[idx];
        theme.name = colors.name;
        theme.background = colors.background;
        theme.foreground = colors.foreground;
        theme.accent = colors.accent;
        theme.loaded = true;
        themes[idx] = theme;
        
        for (var i = 0; i < themeModel.count; i++) {
            if (themeModel.get(i).themeId === theme.id) {
                themeModel.setProperty(i, "name", colors.name);
                themeModel.setProperty(i, "background", colors.background);
                themeModel.setProperty(i, "foreground", colors.foreground);
                themeModel.setProperty(i, "accent", colors.accent);
                break;
            }
        }
        
        for (var j = 0; j < currentList.length; j++) {
            if (currentList[j].id === theme.id) {
                currentList[j].name = colors.name;
                currentList[j].background = colors.background;
                currentList[j].foreground = colors.foreground;
                currentList[j].accent = colors.accent;
                currentList = currentList.slice();
                break;
            }
        }
    }
    
    function _parseTintyInfo(output, schemeId) {
        var lines = output.split("\n");
        var colors = {
            name: _formatThemeName(schemeId),
            background: "#1a1b26",
            foreground: "#c0caf5", 
            accent: "#7aa2f7"
        };
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            
            if (line.indexOf("Name:") === 0) {
                colors.name = line.substring(5).trim();
            }
            
            var match = line.match(/\|\s*base(\w+)\s*\|\s*(#[0-9a-fA-F]{6})/);
            if (match) {
                var baseNum = match[1];
                var hex = match[2];
                
                if (baseNum === "00") colors.background = hex;
                else if (baseNum === "05") colors.foreground = hex;
                else if (baseNum === "0D") colors.accent = hex;
            }
        }
        
        return colors;
    }
    
    function _formatThemeName(id) {
        var name = id.replace(/^base16-/, "");
        return name.split("-").map(function(word) {
            return word.charAt(0).toUpperCase() + word.slice(1);
        }).join(" ");
    }

    function filter(text) {
        root.currentFilter = text;
        themeModel.clear();
        var newList = [];
        var searchLower = text.toLowerCase();
        var foundIndex = 0;

        for (var i = 0; i < themes.length; i++) {
            var theme = themes[i];
            var nameLower = theme.name.toLowerCase();

            if (searchLower === "" || nameLower.indexOf(searchLower) !== -1) {
                themeModel.append({
                    "name": theme.name,
                    "icon": "",
                    "desc": theme.id,
                    "action": "shelltheme:" + theme.id,
                    "themeId": theme.id,
                    "background": theme.background,
                    "foreground": theme.foreground,
                    "accent": theme.accent,
                    "identifier": theme.id,
                    "provider": "shellthemes"
                });
                
                newList.push({
                    id: theme.id,
                    name: theme.name,
                    background: theme.background,
                    foreground: theme.foreground,
                    accent: theme.accent,
                    themeId: theme.id
                });
                
                if (theme.id === root.currentThemeId) {
                    foundIndex = newList.length - 1;
                }
            }
        }
        root.currentList = newList;
        root.currentIndex = foundIndex;
    }

    // Process to get tinty colors on demand
    Process {
        id: tintyColorFetchProc
        property string themeId: ""
        property var callback: null
        property string output: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => tintyColorFetchProc.output += data
        }
        
        onExited: (code) => {
            if (code === 0 && callback) {
                var colors = root._parseTintyInfo(output, themeId);
                callback(colors);
            } else if (callback) {
                callback(null);
            }
            callback = null;
        }
    }

    function activate(item) {
        if (!item || !item.themeId) return true;

        console.log("[ShellThemeProvider] Activating shell theme:", item.themeId);
        
        // Find the theme data to get colors
        var themeData = null;
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].id === item.themeId) {
                themeData = themes[i];
                break;
            }
        }
        
        if (!themeData) {
            console.error("[ShellThemeProvider] Theme not found:", item.themeId);
            return false;
        }
        
        // Function to write config with colors
        function writeConfig(shellColors) {
            var updates = { shellTheme: item.themeId };
            if (shellColors) {
                updates.shellColors = shellColors;
            }
            
            ConfigLoader.writeUserConfig(updates, function(success) {
                console.log("[ShellThemeProvider] writeUserConfig result:", success);
                if (success) {
                    root.currentThemeId = item.themeId;
                    root.themeSelected(item.themeId);
                }
            });
        }
        
        // Get full theme colors from ConfigLoader
        var fullTheme = ConfigLoader.themes[item.themeId];
        
        // If we have full theme colors, use them
        if (fullTheme && fullTheme.colors) {
            writeConfig(fullTheme.colors);
        } 
        // If theme is loaded in our cache, use those colors
        else if (themeData.loaded) {
            var shellColors = {
                background: themeData.background,
                foreground: themeData.foreground,
                accent: themeData.accent
            };
            writeConfig(shellColors);
        }
        // If it's a base16 theme and colors aren't loaded yet, fetch them
        else if (item.themeId.startsWith("base16-")) {
            console.log("[ShellThemeProvider] Fetching colors for", item.themeId);
            tintyColorFetchProc.themeId = item.themeId;
            tintyColorFetchProc.output = "";
            tintyColorFetchProc.callback = function(colors) {
                if (colors) {
                    var shellColors = {
                        background: colors.background,
                        foreground: colors.foreground,
                        accent: colors.accent
                    };
                    writeConfig(shellColors);
                } else {
                    // Fallback: write without colors
                    writeConfig(null);
                }
            };
            tintyColorFetchProc.command = ["tinty", "info", item.themeId];
            tintyColorFetchProc.running = true;
        }
        // Fallback: write without colors
        else {
            writeConfig(null);
        }

        return true;
    }

    function goBack() {
        return false;
    }

    Component.onCompleted: load()
}
