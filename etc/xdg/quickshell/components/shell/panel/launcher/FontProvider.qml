import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"

Item {
    id: root

    property alias model: fontModel
    property var fonts: []

    signal fontSelected(string name)

    ListModel {
        id: fontModel
    }

    property bool fcListAvailable: false
    property bool dependencyChecked: false

    Process {
        id: dependencyCheck
        command: ["which", "fc-list"]
        onExited: (code) => {
            root.fcListAvailable = (code === 0);
            root.dependencyChecked = true;
            if (root.fcListAvailable) {
                scanner.running = true;
            } else {
                fontModel.clear();
                fontModel.append({
                    "name": "Missing Dependency: fontconfig",
                    "icon": "󰀦",
                    "desc": "Install 'fontconfig' to list system fonts",
                    "action": "error",
                    "identifier": "error",
                    "provider": "fonts"
                });
            }
        }
    }

    function load() {
        fontModel.clear();
        fonts = [];
        collectedFonts = "";
        scanner.running = false;
        
        // Check dependency first
        dependencyCheck.running = true;
    }

    function filter(text) {
        if (dependencyChecked && !fcListAvailable) {
            // Keep the error message
            if (fontModel.count === 0) {
                 fontModel.append({
                    "name": "Missing Dependency: fontconfig",
                    "icon": "󰀦",
                    "desc": "Install 'fontconfig' to list system fonts",
                    "action": "error",
                    "identifier": "error",
                    "provider": "fonts"
                });
            }
            return;
        }

        fontModel.clear();
        var searchLower = text.toLowerCase();

        for (var i = 0; i < fonts.length; i++) {
            var fontName = fonts[i];
            var fontLower = fontName.toLowerCase();

            if (searchLower === "" || fontLower.indexOf(searchLower) !== -1) {
                fontModel.append({
                    "name": fontName,
                    "icon": "󰛖",
                    "desc": "Apply " + fontName,
                    "action": "font:" + fontName,
                    "identifier": fontName,
                    "provider": "fonts"
                });
            }
        }
    }

    function activate(item) {
        if (!item || !item.name) return true;
        
        // Use ConfigLoader to write user config
        ConfigLoader.writeUserConfig({ fonts: { family: item.name } }, function(success) {
            if (success) {
                console.log("Font applied:", item.name);
                root.fontSelected(item.name);
            } else {
                console.error("Failed to apply font:", item.name);
            }
        });

        return true;
    }

    function goBack() {
        return false;
    }

    property string collectedFonts: ""

    Process {
        id: scanner
        // Get unique font families, sorted
        command: ["sh", "-c", "fc-list : family | cut -d',' -f1 | sort | uniq"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.collectedFonts += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                var list = root.collectedFonts.trim().split("\n").filter(f => f.length > 0);
                root.fonts = list;
                root.collectedFonts = "";
                root.filter("");
            } else {
                console.error("FontProvider: failed to scan fonts");
            }
        }
    }

    Component.onCompleted: load()
}
