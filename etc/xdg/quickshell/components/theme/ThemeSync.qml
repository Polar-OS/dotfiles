import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Item {
    id: root

    readonly property string matugenPath: Quickshell.env("HOME") + "/.cargo/bin/matugen"
    readonly property string tintyPath: Quickshell.env("HOME") + "/.cargo/bin/tinty"
    readonly property string niriPath: "niri"
    readonly property string tmuxPath: "tmux"

    property string currentTheme: Config.currentTheme
    property string currentWallpaper: Config.wallpaperPath

    Timer {
        id: syncTimer
        interval: 500
        repeat: false
        onTriggered: root.applyTheme()
    }

    Component.onCompleted: {
        console.log("[ThemeSync] INSTANTIATED. Checking initial state...")
        syncTimer.restart()
    }

    onCurrentThemeChanged: {
        console.log("[ThemeSync] Theme Changed:", currentTheme);
        syncTimer.restart();
    }
    
    onCurrentWallpaperChanged: {
        console.log("[ThemeSync] Wallpaper Changed:", currentWallpaper);
        syncTimer.restart();
    }

    Process {
        id: matugenProc
        stdout: SplitParser { onRead: data => console.log("[Matugen out]", data) }
        stderr: SplitParser { onRead: data => console.error("[Matugen err]", data) }
        
        onExited: (code, status) => {
            if (code === 0) {
                console.log("[ThemeSync] Matugen applied successfully.");
                root.reloadApps();
            } else {
                console.error("[ThemeSync] Matugen failed with code " + code);
            }
        }
    }

    property string pendingScheme: "" 
    property bool isInstalling: false

    Process {
        id: tintyProc
        stdout: SplitParser { onRead: data => console.log("[Tinty out]", data) }
        stderr: SplitParser { onRead: data => console.error("[Tinty err]", data) }
        
        onExited: (code, status) => {
            if (code === 0) {
                if (root.isInstalling) {
                    console.log("[ThemeSync] Tinty install complete. Retrying apply...");
                    root.isInstalling = false;
                    if (root.pendingScheme) {
                         tintyProc.command = [root.tintyPath, "apply", root.pendingScheme];
                         tintyProc.running = true;
                         root.pendingScheme = "";
                    }
                } else {
                    console.log("[ThemeSync] Tinty applied successfully.");
                    
                    // Fetch colors to update QuickShell immediately
                    // We need to know which scheme was applied.
                    // Since pendingScheme is cleared, we reconstruct it from currentTheme
                    var scheme = currentTheme.startsWith("base16-") ? currentTheme : ("base16-" + currentTheme);
                    
                    tintyInfoProc.schemeId = scheme;
                    tintyInfoProc.output = "";
                    tintyInfoProc.command = [root.tintyPath, "info", scheme];
                    tintyInfoProc.running = true;

                    root.reloadApps();
                }
            } else {
                console.error("[ThemeSync] Tinty failed with code " + code);
                
                if (!root.isInstalling) {
                    console.log("[ThemeSync] Attempting auto-repair (tinty install)...");
                    root.isInstalling = true;
                    tintyProc.command = [root.tintyPath, "install"];
                    tintyProc.running = true;
                } else {
                    root.isInstalling = false;
                    root.pendingScheme = "";
                }
            }
        }
    }

    Process {
        id: tintyInfoProc
        property string schemeId: ""
        property string output: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => tintyInfoProc.output += data
        }
        
        onExited: (code) => {
            if (code === 0) {
                var colors = root._parseTintyInfoFull(output, schemeId);
                root._writeStaticColors(colors);
            }
        }
    }
    
    Process {
        id: staticColorsWriter
        // command set dynamically
    }
    
    function _writeStaticColors(colors) {
        var data = {
            "current": {
                "name": colors.name,
                "colors": colors
            }
        };
        
        var json = JSON.stringify(data, null, 2);
        // Escape for shell echo
        var escaped = json.replace(/'/g, "'\\''");
        
        staticColorsWriter.command = ["sh", "-c", 
            "printf '%s' '" + escaped + "' > '" + Quickshell.shellDir + "/static-colors.json'"
        ];
        staticColorsWriter.running = true;
    }
    
    function _parseTintyInfoFull(output, schemeId) {
        var lines = output.split("\n");
        var colors = {
            name: schemeId,
            background: "#1a1b26",
            foreground: "#c0caf5", 
            accent: "#7aa2f7"
        };
        
        var base = {};
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            
            if (line.indexOf("Name:") === 0) {
                colors.name = line.substring(5).trim();
            }
            
            var match = line.match(/\|\s*base(\w+)\s*\|\s*(#[0-9a-fA-F]{6})/);
            if (match) {
                var baseNum = match[1];
                var hex = match[2];
                base[baseNum] = hex;
            }
        }
        
        // Map base16 to QuickShell colors
        if (base["00"]) colors.background = base["00"];
        if (base["05"]) colors.foreground = base["05"];
        if (base["0D"]) colors.accent = base["0D"];
        
        if (base["08"]) colors.red = base["08"];
        if (base["0B"]) colors.green = base["0B"];
        if (base["0A"]) colors.yellow = base["0A"];
        if (base["09"]) colors.orange = base["09"];
        if (base["0C"]) colors.cyan = base["0C"];
        
        // Synthesize status colors
        colors.statusCritical = base["08"] || "#ff0000";
        colors.statusWarning = base["09"] || "#ff8800";
        colors.statusMedium = base["0A"] || "#ffff00";
        colors.statusGood = base["0B"] || "#00ff00";
        
        return colors;
    }

    Process {
        id: niriReload
        command: [root.niriPath, "msg", "action", "reload-config"]
        onExited: (code) => console.log("[ThemeSync] Niri reload finished:", code)
    }
    
    Process {
        id: tmuxReload
        command: [root.tmuxPath, "source-file", Quickshell.env("HOME") + "/.config/tmux/colors.conf"]
    }

    function applyTheme() {
        if (!currentTheme) return;

        console.log("[ThemeSync] Applying theme '" + currentTheme + "'...");

        var wpPath = currentWallpaper;
        if (wpPath.startsWith("~")) {
            wpPath = Quickshell.env("HOME") + wpPath.substring(1);
        } else if (wpPath.startsWith("./")) {
             wpPath = Quickshell.shellDir + "/" + wpPath.substring(2);
        }

        if (currentTheme === "dynamic" || currentTheme === "dynamic-inverted") {
            var mode = (currentTheme === "dynamic-inverted") ? "light" : "dark";
            
            console.log("[ThemeSync] Executing Matugen on " + wpPath + " (" + mode + ")");
            matugenProc.command = [root.matugenPath, "image", wpPath, "--mode", mode];
            matugenProc.running = true;
            
        } else if (currentTheme === "current") {
            // "current" is a placeholder theme that shows Tinty's last applied colors
            // No action needed - just reload apps to pick up any pending changes
            console.log("[ThemeSync] Theme 'current' - no external sync needed");
            root.reloadApps();
            
        } else {
            // For base16 themes - add prefix only if not already present
            var scheme = currentTheme.startsWith("base16-") ? currentTheme : ("base16-" + currentTheme);
            
            console.log("[ThemeSync] Executing Tinty apply " + scheme);
            root.pendingScheme = scheme; 
            tintyProc.command = [root.tintyPath, "apply", scheme];
            tintyProc.running = true;
        }
    }

    function reloadApps() {
        console.log("[ThemeSync] Reloading applications...");
        niriReload.running = true;
        tmuxReload.running = true;
    }
}
