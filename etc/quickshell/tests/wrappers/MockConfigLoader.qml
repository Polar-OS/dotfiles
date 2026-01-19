pragma Singleton
import QtQuick

Item {
    id: root
    property var config: ({ "theme": "dynamic", "enabledThemes": ["dynamic", "base16-catppuccin"] })
    property var themes: ({
        "dynamic": { "name": "Dynamic", "id": "dynamic" },
        "base16-catppuccin": { "name": "Catppuccin", "id": "base16-catppuccin" }
    })
    
    signal configReloaded()
    // signal themesLoadedChanged() - AUTOMATICALLY GENERATED
    property bool themesLoaded: true
    
    function writeUserConfig(updates, callback) {
        console.log("MockConfigLoader: writeUserConfig", JSON.stringify(updates));
        if (updates.theme) config.theme = updates.theme;
        if (callback) callback(true);
        configReloaded();
    }
    
    function reload() {
        configReloaded();
    }
}
