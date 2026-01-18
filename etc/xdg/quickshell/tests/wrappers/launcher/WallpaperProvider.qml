import QtQuick
import Quickshell 1.0
import Quickshell.Io 1.0
import "../../../ui/carousel"
import ".."

Item {
    id: root

    property alias model: wallpaperModel
    property var wallpapers: []
    property var currentList: [] // Filtered list as JS Array for CarouselView
    property int currentIndex: 0
    property string currentFilter: "" // Remember current filter
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    signal wallpaperSelected(string path)

    ListModel {
        id: wallpaperModel
    }

    property string currentWallpaperPath: ""

    property bool loading: false

    function load() {
        loading = true;
        wallpaperModel.clear();
        wallpapers = [];
        scannedFiles = "";
        currentFilter = ""; // Reset filter on fresh load
        // Read current wallpaper from Config
        currentWallpaperPath = Config.wallpaperPath;
        scanner.running = false;
        scanner.running = true;
    }

    function filter(text) {
        root.currentFilter = text; // Remember the filter
        wallpaperModel.clear();
        var newList = [];
        var searchLower = text.toLowerCase();
        var foundIndex = 0;

        for (var i = 0; i < wallpapers.length; i++) {
            var path = wallpapers[i];
            var filename = path.split("/").pop().toLowerCase();

            if (searchLower === "" || filename.indexOf(searchLower) !== -1) {
                // Add to ListModel
                wallpaperModel.append({
                    "name": path.split("/").pop(),
                    "icon": "",
                    "desc": path,
                    "action": "wallpaper:" + path,
                    "path": path,
                    "identifier": path,
                    "provider": "wallpapers"
                });
                
                newList.push({
                    path: path,
                    name: path.split("/").pop()
                });

                if (path === root.currentWallpaperPath || path.split("/").pop() === root.currentWallpaperPath.split("/").pop()) {
                    foundIndex = newList.length - 1;
                }
            }
        }
        root.currentList = newList;
        root.currentIndex = foundIndex;
        loading = false;
    }

    // Helper to convert path to ~ format for config
    function toConfigPath(absolutePath) {
        var home = Quickshell.env("HOME");
        if (absolutePath.startsWith(home)) {
            return "~" + absolutePath.substring(home.length);
        }
        return absolutePath;
    }

    function activate(item) {
        if (!item || !item.path) return true;

        // Use ConfigLoader to write user config
        ConfigLoader.writeUserConfig({ wallpaper: toConfigPath(item.path) }, function(success) {
            if (success) {
                root.wallpaperSelected(item.path);
            }
        });

        return true;
    }

    function goBack() {
        return false;
    }

    property string scannedFiles: ""

    Process {
        id: scanner
        command: ["sh", "-c", "find " + root.wallpaperDir + " /usr/share/backgrounds -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \\) 2>/dev/null | head -100"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.scannedFiles += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            var files = root.scannedFiles.trim().split("\n").filter(f => f.length > 0);
            root.wallpapers = files;
            root.scannedFiles = "";
            root.filter(root.currentFilter); // Re-apply current filter
            
            if (root.wallpapers.length === 0) {
                 wallpaperModel.append({
                    "name": "No Wallpapers Found",
                    "icon": "󰋩",
                    "desc": "Check ~/Pictures/Wallpapers or /usr/share/backgrounds",
                    "action": "error",
                    "path": "",
                    "identifier": "error",
                    "provider": "wallpapers"
                });
                
                // Add a dummy item for carousel if needed to avoid crashes
                root.currentList = [{
                    path: "",
                    name: "No Wallpapers Found"
                }];
            }
        }
    }

    Component.onCompleted: load()
}
