import QtQuick
import Quickshell 1.0
import Quickshell.Io 1.0
import ".."

Item {
    id: root

    property alias model: iconThemeModel
    property var iconThemes: []
    property string currentIconTheme: Config.iconTheme

    signal iconThemeSelected(string name)

    ListModel {
        id: iconThemeModel
    }

    function load() {
        iconThemeModel.clear();
        iconThemes = [];
        collectedThemes = "";
        scanner.running = true;
    }

    function activate(item) {
        if (!item || !item.name) return true;
        
        // Use ConfigLoader to write user config
        ConfigLoader.writeUserConfig({ iconTheme: item.name }, function(success) {
            if (success) {
                console.log("Icon theme applied:", item.name);
                root.iconThemeSelected(item.name);
                
                // Try to set system icon theme via gsettings (common for GTK/QT apps)
                Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", item.name]);
                
                // Trigger reload to update Config.iconTheme binding
                Config.reload(); 
            } else {
                console.error("Failed to apply icon theme:", item.name);
            }
        });

        return true;
    }

    property string collectedThemes: ""

    Process {
        id: scanner
        // Find directories containing index.theme, extract name and try to find a representative icon
        command: ["sh", "-c", "
            find /usr/share/icons ~/.local/share/icons -mindepth 2 -maxdepth 2 -name index.theme 2>/dev/null | xargs -n 1 dirname | sort | uniq | while read theme_dir; do
                name=$(basename \"$theme_dir\")
                # Try to find a representative icon (folder, home, etc)
                # We look for png/svg in standard places (places, apps, etc)
                icon=$(find \"$theme_dir\" -type f \\( -name \"folder.png\" -o -name \"folder.svg\" -o -name \"user-home.png\" -o -name \"user-home.svg\" -o -name \"system-file-manager.png\" -o -name \"system-file-manager.svg\" \\) | head -n 1)
                
                # If no icon found, try to look for any png/svg to at least show something (fallback)
                if [ -z \"$icon\" ]; then
                     icon=$(find \"$theme_dir\" -type f \\( -name \"*.png\" -o -name \"*.svg\" \\) | head -n 1)
                fi

                echo \"$name|$icon\"
            done
        "]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.collectedThemes += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                iconThemeModel.clear();
                var lines = root.collectedThemes.trim().split("\n");
                root.iconThemes = [];
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    
                    var parts = line.split("|");
                    var name = parts[0];
                    var iconPath = parts.length > 1 ? parts[1] : "";
                    
                    // If we found a path, use it. If not, fallback to 'folder' 
                    // but 'folder' might fail if the current theme doesn't have it (unlikely but possible)
                    // We prioritize the path so the preview is accurate to the theme.
                    var displayIcon = iconPath.length > 0 ? iconPath : "folder";
                    
                    root.iconThemes.push({name: name, icon: displayIcon});
                }
                
                root.collectedThemes = "";
                root.filter("");
            } else {
                console.error("IconThemeProvider: failed to scan icon themes");
            }
        }
    }

    function filter(text) {
        iconThemeModel.clear();
        var searchLower = text.toLowerCase();

        for (var i = 0; i < iconThemes.length; i++) {
            var item = iconThemes[i];
            var themeName = item.name;
            var themeLower = themeName.toLowerCase();

            if (searchLower === "" || themeLower.indexOf(searchLower) !== -1) {
                iconThemeModel.append({
                    "name": themeName,
                    "icon": item.icon, 
                    "desc": "Apply " + themeName,
                    "action": "iconTheme:" + themeName,
                    "identifier": themeName,
                    "provider": "iconThemes"
                });
            }
        }
    }

    Component.onCompleted: load()
}
