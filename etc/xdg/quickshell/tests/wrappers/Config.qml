pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "."

Item {
    id: root

    // ConfigLoader reference
    property var loader: ConfigLoader

    // Dynamic theme enabled
    property bool dynamicThemeEnabled: false

    // Reload function
    function reload() {
        ConfigLoader.reload();
    }

    // Helper to resolve ~ paths
    function resolvePath(path) {
        if (!path) return "";
        if (path.startsWith("~")) {
            return Quickshell.env("HOME") + path.substring(1);
        }
        return path;
    }

    // Apply config when ConfigLoader finishes
    Connections {
        target: ConfigLoader
        function onConfigReloaded() {
            root._applyConfig();
        }
    }

    // Apply dynamic theme colors when generated
    Connections {
        target: DynamicThemeGenerator
        function onColorsGenerated() {
            if (root.dynamicThemeEnabled) {
                root._applyDynamicColors();
            }
        }
    }

    // Apply colors from DynamicThemeGenerator
    function _applyDynamicColors() {
        if (!DynamicThemeGenerator.ready) return;

        root.background = DynamicThemeGenerator.background;
        root.foreground = DynamicThemeGenerator.foreground;
        root.accent = DynamicThemeGenerator.accent;
        root.red = DynamicThemeGenerator.red;
        root.green = DynamicThemeGenerator.green;
        root.yellow = DynamicThemeGenerator.yellow;
        root.orange = DynamicThemeGenerator.orange;
        root.cyan = DynamicThemeGenerator.cyan;
        root.blue = DynamicThemeGenerator.blue;
        root.purple = DynamicThemeGenerator.purple;
        root.magenta = DynamicThemeGenerator.magenta;
        root.statusCritical = DynamicThemeGenerator.statusCritical;
        root.statusWarning = DynamicThemeGenerator.statusWarning;
        root.statusMedium = DynamicThemeGenerator.statusMedium;
        root.statusGood = DynamicThemeGenerator.statusGood;
    }

    // Apply merged config and themes
    function _applyConfig() {
        var cfg = ConfigLoader.config || {};
        console.log("DEBUG: Config loaded. Animations section: " + JSON.stringify(cfg.animations));
        var themes = ConfigLoader.themes || {};

        // Apply wallpaper first (needed for dynamic theme)
        if (cfg.wallpaper) {
            root.wallpaperPath = root.resolvePath(cfg.wallpaper);
        }

        // Check if dynamic theme is selected
        root.dynamicThemeEnabled = (cfg.theme === "dynamic" || cfg.theme === "dynamic-inverted");

        if (root.dynamicThemeEnabled) {
            // Dynamic theme: generate colors from wallpaper
            root.currentTheme = cfg.theme;
            DynamicThemeGenerator.wallpaperPath = root.wallpaperPath;
            DynamicThemeGenerator.inverted = (cfg.theme === "dynamic-inverted");
            // Force regeneration in case wallpaper path didn't change
            DynamicThemeGenerator.regenerate();
            // Colors will be applied via onColorsGenerated signal
        } else {
            // Apply static theme
            if (cfg.theme && themes[cfg.theme]) {
                root.currentTheme = cfg.theme;
                var theme = themes[cfg.theme];

                // Apply theme colors
                if (theme.colors) {
                    if (theme.colors.background) root.background = theme.colors.background;
                    if (theme.colors.foreground) root.foreground = theme.colors.foreground;
                    if (theme.colors.accent) root.accent = theme.colors.accent;
                    if (theme.colors.red) root.red = theme.colors.red;
                    if (theme.colors.green) root.green = theme.colors.green;
                    if (theme.colors.yellow) root.yellow = theme.colors.yellow;
                    if (theme.colors.orange) root.orange = theme.colors.orange;
                    if (theme.colors.cyan) root.cyan = theme.colors.cyan;
                    if (theme.colors.blue) root.blue = theme.colors.blue;
                    if (theme.colors.purple) root.purple = theme.colors.purple;
                    if (theme.colors.magenta) root.magenta = theme.colors.magenta;
                    if (theme.colors.statusCritical) root.statusCritical = theme.colors.statusCritical;
                    if (theme.colors.statusWarning) root.statusWarning = theme.colors.statusWarning;
                    if (theme.colors.statusMedium) root.statusMedium = theme.colors.statusMedium;
                    if (theme.colors.statusGood) root.statusGood = theme.colors.statusGood;
                }

                // Apply theme layout
                if (theme.layout) {
                    if (theme.layout.radius !== undefined) root.radius = theme.layout.radius;
                    if (theme.layout.itemRadius !== undefined) root.itemRadius = theme.layout.itemRadius;
                    if (theme.layout.screenCornerRadius !== undefined) root.screenCornerRadius = theme.layout.screenCornerRadius;
                    if (theme.layout.panelCornerRadius !== undefined) root.panelCornerRadius = theme.layout.panelCornerRadius;
                    if (theme.layout.screenBorderSize !== undefined) root.screenBorderSize = theme.layout.screenBorderSize;
                }
            }

            // Override with explicit config values (colors override theme)
            if (cfg.colors) {
                if (cfg.colors.background) root.background = cfg.colors.background;
                if (cfg.colors.foreground) root.foreground = cfg.colors.foreground;
                if (cfg.colors.accent) root.accent = cfg.colors.accent;
                if (cfg.colors.red) root.red = cfg.colors.red;
                if (cfg.colors.green) root.green = cfg.colors.green;
                if (cfg.colors.yellow) root.yellow = cfg.colors.yellow;
                if (cfg.colors.orange) root.orange = cfg.colors.orange;
                if (cfg.colors.cyan) root.cyan = cfg.colors.cyan;
                if (cfg.colors.blue) root.blue = cfg.colors.blue;
                if (cfg.colors.purple) root.purple = cfg.colors.purple;
                if (cfg.colors.magenta) root.magenta = cfg.colors.magenta;
                if (cfg.colors.statusCritical) root.statusCritical = cfg.colors.statusCritical;
                if (cfg.colors.statusWarning) root.statusWarning = cfg.colors.statusWarning;
                if (cfg.colors.statusMedium) root.statusMedium = cfg.colors.statusMedium;
                if (cfg.colors.statusGood) root.statusGood = cfg.colors.statusGood;
            }
        }

        // Layout overrides (always apply, even with dynamic theme)
        if (cfg.layout) {
            if (cfg.layout.radius !== undefined) root.radius = cfg.layout.radius;
            if (cfg.layout.itemRadius !== undefined) root.itemRadius = cfg.layout.itemRadius;
            if (cfg.layout.screenCornerRadius !== undefined) root.screenCornerRadius = cfg.layout.screenCornerRadius;
            if (cfg.layout.panelCornerRadius !== undefined) root.panelCornerRadius = cfg.layout.panelCornerRadius;
            if (cfg.layout.screenBorderSize !== undefined) root.screenBorderSize = cfg.layout.screenBorderSize;
            if (cfg.layout.panelEdgeRevealDelay !== undefined) root.panelEdgeRevealDelay = cfg.layout.panelEdgeRevealDelay;
            if (cfg.layout.padding !== undefined) root.padding = cfg.layout.padding;
            if (cfg.layout.spacing !== undefined) root.spacing = cfg.layout.spacing;
            if (cfg.layout.buttonSize !== undefined) root.buttonSize = cfg.layout.buttonSize;
            if (cfg.layout.iconSize !== undefined) root.iconSize = cfg.layout.iconSize;
            if (cfg.layout.panelWidth !== undefined) root.panelWidth = cfg.layout.panelWidth;
        }

    // Animation overrides
        if (cfg.animations) {
            // New Structured Config Support
            if (cfg.animations.global) {
                if (cfg.animations.global.fast !== undefined) root.animDurationFast = cfg.animations.global.fast;
                if (cfg.animations.global.regular !== undefined) root.animDurationRegular = cfg.animations.global.regular;
                if (cfg.animations.global.slow !== undefined) root.animationDurationSlow = cfg.animations.global.slow;
                if (cfg.animations.global.easing) root.animEasingStandard = root._resolveEasing(cfg.animations.global.easing);
                
                // Backwards compat aliases
                root.animationDurationQuick = root.animDurationFast;
                root.animationDurationMedium = root.animDurationRegular;
                root.animationDuration = root.animDurationRegular;
            }
            
            if (cfg.animations.panel) {
                if (cfg.animations.panel.reveal !== undefined) root.animationDurationLong = cfg.animations.panel.reveal;
                if (cfg.animations.panel.autoHideDelay !== undefined) root.autoHideDelay = cfg.animations.panel.autoHideDelay;
                
                // Reset to default before checking
                root.animCurvePanel = null;
                
                if (cfg.animations.panel.easing) {
                    root.animEasingPanel = root._resolveEasing(cfg.animations.panel.easing);
                    // Special case for Polar Bezier
                    if (cfg.animations.panel.easing === "Polar") {
                        console.log("Config: Enabling Polar Bezier for Panels");
                        root.animCurvePanel = root.animCurvePolar;
                    }
                }
            }
            
            if (cfg.animations.feedback) {
                if (cfg.animations.feedback.hover !== undefined) root.animDurationHover = cfg.animations.feedback.hover;
                if (cfg.animations.feedback.shake !== undefined) root.animDurationShake = cfg.animations.feedback.shake;
                if (cfg.animations.feedback.pulse !== undefined) root.animDurationPulse = cfg.animations.feedback.pulse;
                if (cfg.animations.feedback.easingPulse) root.animEasingPulse = root._resolveEasing(cfg.animations.feedback.easingPulse);
                if (cfg.animations.feedback.easingBounce) root.animEasingBounce = root._resolveEasing(cfg.animations.feedback.easingBounce);
            }
            
            if (cfg.animations.screensaver) {
                if (cfg.animations.screensaver.step !== undefined) root.animDurationSaverStep = cfg.animations.screensaver.step;
                if (cfg.animations.screensaver.fast !== undefined) root.animDurationSaverFast = cfg.animations.screensaver.fast;
                if (cfg.animations.screensaver.medium !== undefined) root.animDurationSaverMedium = cfg.animations.screensaver.medium;
                if (cfg.animations.screensaver.slow !== undefined) root.animDurationSaverSlow = cfg.animations.screensaver.slow;
                if (cfg.animations.screensaver.verySlow !== undefined) root.animDurationSaverVerySlow = cfg.animations.screensaver.verySlow;
            }
            
            if (cfg.animations.misc) {
                if (cfg.animations.misc.background !== undefined) root.animDurationBackground = cfg.animations.misc.background;
                if (cfg.animations.misc.pause !== undefined) root.animDurationPause = cfg.animations.misc.pause;
            }

            // Fallback for flat structure (legacy support)
            if (cfg.animations.durationQuick !== undefined) root.animationDurationQuick = cfg.animations.durationQuick;
            if (cfg.animations.durationMedium !== undefined) root.animationDurationMedium = cfg.animations.durationMedium;
            if (cfg.animations.durationSlow !== undefined) root.animationDurationSlow = cfg.animations.durationSlow;
            if (cfg.animations.autoHideDelay !== undefined) root.autoHideDelay = cfg.animations.autoHideDelay;
            
            if (cfg.animations.durationFast !== undefined) root.animDurationFast = cfg.animations.durationFast;
            if (cfg.animations.durationRegular !== undefined) root.animDurationRegular = cfg.animations.durationRegular;
            if (cfg.animations.durationHover !== undefined) root.animDurationHover = cfg.animations.durationHover;
            if (cfg.animations.durationShake !== undefined) root.animDurationShake = cfg.animations.durationShake;
            if (cfg.animations.durationPulse !== undefined) root.animDurationPulse = cfg.animations.durationPulse;
            if (cfg.animations.durationBackground !== undefined) root.animDurationBackground = cfg.animations.durationBackground;
            if (cfg.animations.durationPause !== undefined) root.animDurationPause = cfg.animations.durationPause;
            
            if (cfg.animations.saverStep !== undefined) root.animDurationSaverStep = cfg.animations.saverStep;
            if (cfg.animations.saverFast !== undefined) root.animDurationSaverFast = cfg.animations.saverFast;
            if (cfg.animations.saverMedium !== undefined) root.animDurationSaverMedium = cfg.animations.saverMedium;
            if (cfg.animations.saverSlow !== undefined) root.animDurationSaverSlow = cfg.animations.saverSlow;
            if (cfg.animations.saverVerySlow !== undefined) root.animDurationSaverVerySlow = cfg.animations.saverVerySlow;
        }

        // Fonts
        if (cfg.fonts) {
            if (cfg.fonts.family) root.fontFamily = cfg.fonts.family;
            if (cfg.fonts.iconFamily) root.iconFontFamily = cfg.fonts.iconFamily;
        }

        // Pomodoro
        if (cfg.pomodoro) {
            if (cfg.pomodoro.duration !== undefined) root.pomodoroDuration = cfg.pomodoro.duration;
            if (cfg.pomodoro.breakDuration !== undefined) root.pomodoroBreakDuration = cfg.pomodoro.breakDuration;
            if (cfg.pomodoro.longBreakDuration !== undefined) root.pomodoroLongBreakDuration = cfg.pomodoro.longBreakDuration;
            if (cfg.pomodoro.cycleCount !== undefined) root.pomodoroCycleCount = cfg.pomodoro.cycleCount;
        }

        // Screensavers list
        if (cfg.screensavers && Array.isArray(cfg.screensavers)) {
             root.activeScreensavers = cfg.screensavers;
        }

        console.log("Config applied: theme=" + root.currentTheme);
    }

    function _resolveEasing(name) {
        switch(name) {
            case "Linear": return Easing.Linear;
            case "InQuad": return Easing.InQuad; case "OutQuad": return Easing.OutQuad; case "InOutQuad": return Easing.InOutQuad;
            case "InCubic": return Easing.InCubic; case "OutCubic": return Easing.OutCubic; case "InOutCubic": return Easing.InOutCubic;
            case "InQuart": return Easing.InQuart; case "OutQuart": return Easing.OutQuart; case "InOutQuart": return Easing.InOutQuart;
            case "InQuint": return Easing.InQuint; case "OutQuint": return Easing.OutQuint; case "InOutQuint": return Easing.InOutQuint;
            case "InSine": return Easing.InSine; case "OutSine": return Easing.OutSine; case "InOutSine": return Easing.InOutSine;
            case "InExpo": return Easing.InExpo; case "OutExpo": return Easing.OutExpo; case "InOutExpo": return Easing.InOutExpo;
            case "InCirc": return Easing.InCirc; case "OutCirc": return Easing.OutCirc; case "InOutCirc": return Easing.InOutCirc;
            case "InBack": return Easing.InBack; case "OutBack": return Easing.OutBack; case "InOutBack": return Easing.InOutBack;
            case "InBounce": return Easing.InBounce; case "OutBounce": return Easing.OutBounce; case "InOutBounce": return Easing.InOutBounce;
            case "Polar": return Easing.Bezier; 
            default: return Easing.OutCubic;
        }
    }

    // Wallpaper path (resolved to absolute)
    property string wallpaperPath: Quickshell.env("HOME") + "/.config/quickshell/assets/wallpaper.png"

    // Current theme name
    property string currentTheme: "tokyo-night"

    // Colors (defaults from Tokyo Night)
    property color background: "#1a1b26"
    Behavior on background { ColorAnimation { duration: root.animationDuration } }

    property color foreground: "#c0caf5"
    Behavior on foreground { ColorAnimation { duration: root.animationDuration } }

    // Color for text or inactive elements (50% opacity)
    property color dimmed: Qt.alpha(foreground, 0.5)

    property color accent: "#7aa2f7"
    Behavior on accent { ColorAnimation { duration: root.animationDuration } }

    property color red: "#f7768e"
    Behavior on red { ColorAnimation { duration: root.animationDuration } }

    property color green: "#9ece6a"
    Behavior on green { ColorAnimation { duration: root.animationDuration } }

    property color yellow: "#e0af68"
    Behavior on yellow { ColorAnimation { duration: root.animationDuration } }

    property color orange: "#ff9e64"
    Behavior on orange { ColorAnimation { duration: root.animationDuration } }

    property color cyan: "#7dcfff"
    Behavior on cyan { ColorAnimation { duration: root.animationDuration } }

    property color blue: "#7aa2f7"
    Behavior on blue { ColorAnimation { duration: root.animationDuration } }

    property color purple: "#bb9af7"
    Behavior on purple { ColorAnimation { duration: root.animationDuration } }

    property color magenta: "#bb9af7"
    Behavior on magenta { ColorAnimation { duration: root.animationDuration } }

    // Status colors
    property color statusCritical: "#f7768e"
    Behavior on statusCritical { ColorAnimation { duration: root.animationDuration } }

    property color statusWarning: "#ff9e64"
    Behavior on statusWarning { ColorAnimation { duration: root.animationDuration } }

    property color statusMedium: "#e0af68"
    Behavior on statusMedium { ColorAnimation { duration: root.animationDuration } }

    property color statusGood: "#9ece6a"
    Behavior on statusGood { ColorAnimation { duration: root.animationDuration } }

    // Detect if theme is light based on background luminance
    // Luminance formula: 0.299*R + 0.587*G + 0.114*B
    property bool isLightTheme: {
        var r = background.r;
        var g = background.g;
        var b = background.b;
        var luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        return luminance > 0.5;
    }

    // Icon color: dark for light themes, foreground for dark themes
    property color iconColor: isLightTheme ? Qt.darker(foreground, 1.5) : foreground

    // Radius for main window (large)
    property int radius: 10
    Behavior on radius { NumberAnimation { duration: root.animationDuration } }

    // Radius for internal elements (small, e.g. volume bar, workspaces)
    property int itemRadius: 4
    Behavior on itemRadius { NumberAnimation { duration: root.animationDuration } }

    // Corner radius for screen borders
    property int screenCornerRadius: 12
    Behavior on screenCornerRadius { NumberAnimation { duration: root.animationDuration } }

    // Corner radius for panel inverted corners
    property int panelCornerRadius: radius
    Behavior on panelCornerRadius { NumberAnimation { duration: root.animationDuration } }

    // Screen border size (thickness of edge decorations)
    property int screenBorderSize: 4

    // Panel edge reveal delay (ms to hover before panel appears)
    property int panelEdgeRevealDelay: 1000

    // Standard Layout Properties
    property int padding: 10
    property int spacing: 10
    property int buttonSize: 40
    property int iconSize: 18
    property int panelWidth: 320

    // Animation Properties (3 speeds: quick, medium, slow)
    property int animationDurationQuick: 150
    property int animationDurationMedium: 300
    property int animationDurationSlow: 500
    
    // New Standardized Durations
    property int animDurationFast: 100        // Borders, hover colors
    property int animDurationRegular: 200     // Generic UI transitions
    property int animDurationHover: 250       // Launcher hover
    property int animDurationShake: 50        // Error shake
    property int animDurationPulse: 800       // Pulse effects
    property int animDurationBackground: 600  // Wallpaper transitions
    
    // Screensaver & Misc
    property int animDurationPause: 400       // Chat typing pause
    property int animDurationSaverStep: 1000
    property int animDurationSaverFast: 2000
    property int animDurationSaverMedium: 4000
    property int animDurationSaverSlow: 5000
    property int animDurationSaverVerySlow: 10000
    
    // Easing Types
    property int animEasingStandard: Easing.OutCubic  // Standard UI movement
    property int animEasingSoft: Easing.OutQuad       // Softer transitions
    property int animEasingPanel: Easing.OutExpo      // Panel reveal
    property var animCurvePanel: null                 // Custom bezier support for panels
    
    // Global Polar Curve Support
    property var polarCurve: [0.38, 1.21, 0.22, 1.0, 1, 1]
    property int animEasingPolar: Easing.Bezier       // Maps to Bezier
    
    property int animEasingPulse: Easing.InOutSine    // Pulse/Breathing
    property int animEasingBounce: Easing.OutBack     // Bouncy entrances

    // Legacy alias for backwards compatibility
    property int animationDuration: animationDurationQuick
    property int animationDurationLong: animationDurationSlow
    property int autoHideDelay: 5000

    // Font configuration
    property string fontFamily: "Cascadia Code"
    property string iconFontFamily: "Symbols Nerd Font, FontAwesome, Cascadia Code"

    // Pomodoro
    property int pomodoroDuration: 52
    property int pomodoroBreakDuration: 17
    property int pomodoroLongBreakDuration: 30
    property int pomodoroCycleCount: 4

    // Chat persistence
    property string lastChatAgent: ""
    property string lastChatProvider: ""
    property string lastChatModel: ""
    
    // Shadow color (defaults to 50% transparent black)
    property color shadow: "#80000000"

    // Active Screensavers List
    property var activeScreensavers: [
        "NiriSaver.qml",
        "PolarSaver.qml",
        "FedoraSaver.qml",
        "QuickshellSaver.qml",
        "ArchSaver.qml",
        "UbuntuSaver.qml",
        "HyprlandSaver.qml",
        "DebianSaver.qml",
        "WaylandSaver.qml",
        "CachySaver.qml"
    ]
}
