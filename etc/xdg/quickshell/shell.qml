//@ pragma UseQApplication
import QtQuick
import Quickshell
import Niri 0.1
import "./components/shell/panel/launcher"
import "./components/config"
import "./components/theme"
import "./components/shell/panel/status"
import "./components/shell/panel/workspace"
import "./components/shell/panel/message"
import "./components/shell/panel/message/pomodoro"
import "./components/shell/panel/status/media"
import "./components/shell/wallpaper"
import "./components/shell/overlay/lock"
import "./components/shell/overlay/logout"
import "./components/shell/overlay/cheatsheet"
import "./components/shell/overlay/about"
import "./components/shell/screensaver"
import "./components/ui/panel"
import "./components/shell/overlay/debug"

Scope {
    ThemeSync { id: themeSync }
    // Initialize Theme Sync
    id: root

    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.log("Connected to Niri")
        onErrorOccurred: error => console.error("Niri Error:", error)
    }

    Lock {
        id: lock
        pomodoroController: globalPomodoro
        mprisController: globalMpris
    }

    Logout {
        id: logout
        lockContext: lock.context
    }

    Cheatsheet {
        id: cheatsheet
    }

    About {
        id: about
    }

    Status {
        id: volumeOsd
        logoutTarget: logout
        cheatsheetTarget: cheatsheet
        aboutTarget: about
        mprisController: globalMpris
    }

    Wallpaper {}

    // Pass the niri object to the component
    Workspaces {
        niri: niri
    }

    // Global Pomodoro Controller (Logic & Audio)
    Pomodoro {
        id: globalPomodoro
    }

    // Global Media Controller
    MprisController {
        id: globalMpris
    }

    // Pomodoro Fullscreen Overlay
    PomodoroOverlay {
        pomodoro: globalPomodoro
        isLockScreenActive: lock.context.active
    }

    Messages {
        pomodoroController: globalPomodoro
    }

    Launcher {}

    Screensaver {}

    ScreenBorder {}

    DebugPanel {
        id: debugPanel
    }
}
