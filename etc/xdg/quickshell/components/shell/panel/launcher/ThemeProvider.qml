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
    property bool initialized: false
    
    property var _pendingThemes: []
    property int _currentLoadIndex: 0
    property bool _colorsLoading: false

    function load(force) {
        if (loading) return;
        
        currentFilter = ""; // Reset filter on load
        
        // Always sync current theme ID
        currentThemeId = Config.currentTheme;
        
        // If already initialized and not forced, just ensure index is correct
        if (initialized && !force) {
            _updateCurrentIndex();
            return;
        }

        loading = true;
        
        // We need both themes and config (for enabledThemes)
        if (!ConfigLoader.themesLoaded || !ConfigLoader.configLoaded) {
            console.log("[ThemeProvider] Waiting for config dependencies...");
            ConfigLoader.reload();
            // We will continue in onAllLoadedChanged
        } else {
            console.log("[ThemeProvider] Loading themes. Current theme:", currentThemeId);
            _buildInitialList();
        }
    }

    Connections {
        target: ConfigLoader
        function onAllLoadedChanged() {
            if (ConfigLoader.allLoaded && loading) {
                console.log("[ThemeProvider] Dependencies loaded, building list.");
                _buildInitialList();
            }
        }
    }

    Connections {
        target: Config
        function onCurrentThemeChanged() {
            if (Config.currentTheme !== root.currentThemeId) {
                root.currentThemeId = Config.currentTheme;
                // Recalculate currentIndex to match the new theme
                root._updateCurrentIndex();
            }
        }
    }

    function _buildInitialList() {
        var themesData = ConfigLoader.themes || {};
        var enabledThemes = ConfigLoader.config.enabledThemes || [];
        
        console.log("[ThemeProvider] Building list. Enabled themes count:", enabledThemes.length);
        
        // Use enabledThemes if present, otherwise fallback to keys in themes.json
        var themeKeys = [];
        if (enabledThemes.length > 0) {
            themeKeys = enabledThemes;
        } else {
            console.log("[ThemeProvider] No enabledThemes found, falling back to themes.json keys");
            themeKeys = Object.keys(themesData).sort();
        }
        
        _pendingThemes = [];
        themes = [];
        
        for (var i = 0; i < themeKeys.length; i++) {
            var key = themeKeys[i];
            var t = themesData[key];
            
            // If it exists in config with colors, use it
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
                // Otherwise it's a unloaded tinty theme referenced in enabledThemes
                themes.push({
                    id: key,
                    name: _formatThemeName(key),
                    background: "#2d2d2d",
                    foreground: "#888888",
                    accent: "#555555",
                    loaded: false
                });
                
                // Load colors for any theme that is missing data
                // This covers base16- themes not in themes.json but in enabledThemes
                if (key.startsWith("base16-") || !t) {
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
        
        initialized = true;
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
        var foundIndex = -1; // Default to -1 (not found)

        for (var i = 0; i < themes.length; i++) {
            var theme = themes[i];
            var nameLower = theme.name.toLowerCase();

            if (searchLower === "" || nameLower.indexOf(searchLower) !== -1) {
                themeModel.append({
                    "name": theme.name,
                    "icon": "",
                    "desc": theme.id,
                    "action": "theme:" + theme.id,
                    "themeId": theme.id,
                    "background": theme.background,
                    "foreground": theme.foreground,
                    "accent": theme.accent,
                    "identifier": theme.id,
                    "provider": "themes"
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
        
        // Only update currentIndex if we found a match, otherwise keep it or set to 0 if list not empty
        if (foundIndex !== -1) {
            root.currentIndex = foundIndex;
        } else if (newList.length > 0) {
            // If not found, don't force 0 immediately to avoid jumping, 
            // but we might need a valid index. 
            // For now, let's try NOT resetting to 0 to avoid the "jump to first" issue
            // unless currentIndex is out of bounds
            if (root.currentIndex >= newList.length) {
                root.currentIndex = 0;
            }
        } else {
             root.currentIndex = -1;
        }
    }

    function _updateCurrentIndex() {
        // Find and update the current index based on currentThemeId
        for (var i = 0; i < root.currentList.length; i++) {
            if (root.currentList[i].id === root.currentThemeId) {
                root.currentIndex = i;
                return;
            }
        }
        // If not found, do not change index arbitrarily
    }

    function activate(item) {
        if (!item || !item.themeId) return true;

        console.log("[ThemeProvider] Activating theme:", item.themeId);
        // Also update shellTheme to ensure QuickShell UI updates too
        // And disable explicit shellColors so the theme can take effect
        ConfigLoader.writeUserConfig({ 
            theme: item.themeId,
            shellTheme: item.themeId,
            shellColors: false
        }, function(success) {
            console.log("[ThemeProvider] writeUserConfig result:", success);
            if (success) {
                root.currentThemeId = item.themeId;
                root.themeSelected(item.themeId);
            }
        });

        return true;
    }

    function goBack() {
        return false;
    }

    Component.onCompleted: load()
}
