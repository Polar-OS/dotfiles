pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Input: wallpaper path to analyze
    property string wallpaperPath: ""
    property bool inverted: false

    // Output: ready state
    property bool ready: false

    // Signal when colors are generated (file updated)
    signal colorsGenerated()

    // Path to dynamic colors file
    readonly property string dynamicColorsPath: Quickshell.shellDir + "/dynamic-colors.json"

    // Trigger regeneration when wallpaper changes
    onWallpaperPathChanged: {
        if (wallpaperPath && wallpaperPath.length > 0) {
            ready = false;
            // ThemeSync will handle running matugen
            // We just track when the file changes
        }
    }

    // Force regeneration (called when switching TO dynamic theme)
    function regenerate() {
        if (wallpaperPath && wallpaperPath.length > 0) {
            ready = false;
            // ThemeSync will run matugen which generates dynamic-colors.json
            // ConfigLoader watches that file and will reload themes
        }
    }

    // Watch the dynamic-colors.json file for changes
    FileView {
        id: dynamicColorsWatcher
        path: root.dynamicColorsPath
        watchChanges: true
        onFileChanged: {
            console.log("DynamicTheme: dynamic-colors.json updated");
            root.ready = true;
            root.colorsGenerated();
        }
    }

    // Also watch wallpaper file for changes
    FileView {
        id: wallpaperWatcher
        path: root.wallpaperPath
        watchChanges: true
        onFileChanged: {
            console.log("DynamicTheme: Wallpaper file changed");
            root.ready = false;
            // ThemeSync will pick up the wallpaper change and run matugen
        }
    }
}
