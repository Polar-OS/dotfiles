import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../theme"

// Component to manage the wallpaper on all screens
Scope {
    id: root

    property string defaultWallpaper: Quickshell.env("HOME") + "/.config/quickshell/assets/wallpaper.png"
    property string currentWallpaper: ""

    // Failsafe timer in case color generation hangs
    Timer {
        id: failsafeTimer
        interval: 3000
        repeat: false
        onTriggered: {
            console.log("Dynamic Theme: Color generation timed out, updating wallpaper anyway")
            updateWallpaper()
        }
    }

    // Watch Config.wallpaperPath for changes
    Connections {
        target: Config
        function onWallpaperPathChanged() {
            if (!Config.dynamicThemeEnabled) {
                updateWallpaper();
            } else {
                failsafeTimer.restart();
            }
        }
    }

    Connections {
        target: DynamicThemeGenerator
        function onColorsGenerated() {
            if (Config.dynamicThemeEnabled) {
                failsafeTimer.stop();
                updateWallpaper();
            }
        }
    }

    function updateWallpaper() {
        var path = Config.wallpaperPath || root.defaultWallpaper;
        if (path && path.length > 0) {
            var newUrl = "file://" + path;
            if (root.currentWallpaper !== newUrl) {
                root.currentWallpaper = newUrl;
            }
        }
    }

    Component.onCompleted: {
        // Initial load with small delay to ensure Config is loaded
        Qt.callLater(updateWallpaper);
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: wallpaperWindow
            // This property is required for Variants to work correctly
            property var modelData
            
            screen: modelData
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            exclusiveZone: -1
            
            color: "transparent"

            property bool showingFront: true
            property string nextSource: ""

            // Trigger load when wallpaper changes
            Connections {
                target: root
                function onCurrentWallpaperChanged() {
                    wallpaperWindow.nextSource = root.currentWallpaper
                    if (wallpaperWindow.showingFront) {
                        backImg.source = wallpaperWindow.nextSource
                    } else {
                        frontImg.source = wallpaperWindow.nextSource
                    }
                }
            }

            Image {
                id: backImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: wallpaperWindow.showingFront ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Config.animDurationBackground; easing.type: Config.animEasingSoft } }
                
                onStatusChanged: {
                    if (status === Image.Ready && source == wallpaperWindow.nextSource && wallpaperWindow.showingFront) {
                        wallpaperWindow.showingFront = false
                    }
                }
            }

            Image {
                id: frontImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: wallpaperWindow.showingFront ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Config.animDurationBackground; easing.type: Config.animEasingSoft } }
                
                onStatusChanged: {
                    if (status === Image.Ready && source == wallpaperWindow.nextSource && !wallpaperWindow.showingFront) {
                        wallpaperWindow.showingFront = true
                    }
                }
            }

            Component.onCompleted: {
                frontImg.source = root.currentWallpaper
                nextSource = root.currentWallpaper
            }
        }
    }
}
