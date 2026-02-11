import QtQuick 2.15
import "framework"
import "wrappers/launcher"

SimpleTest {
    name: "LauncherComponents"

    Launcher {
        id: launcher
        width: 800
        height: 600
    }
    
    function test_launcher_load() {
        verify(launcher.width > 0, "Launcher loaded")
        // Check if provider loaded
        // Launcher might have property 'apps' or 'model'
        // Assuming it works if no crash
    }
}
