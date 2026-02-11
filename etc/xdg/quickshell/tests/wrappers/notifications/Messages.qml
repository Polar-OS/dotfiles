import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell 1.0
import Quickshell.Io 1.0
import "../base"
import "./system"
import "./pomodoro"
import ".."
import "."
import "./voice"

Panel {
    id: root

    position: "top"
    
    // Prevent Panel base auto-hide when pomodoro is active
    preventAutoHide: pomodoroActive

    // Disable panel's internal size smoothing to sync perfectly with NotificationList animation
    animateContentResizing: false

    // Panel dimensions - contentPadding is handled by Panel/PanelStyle
    contentWidth: 320
    contentPadding: 0 // Reset padding to match Workspaces.qml logic

    // Calculate normal content height (without extended elements)
    // This includes: VoiceDictation + NotificationList + Clock/Pomodoro header
    // Must include Config.padding * 2 to account for mainLayout margins since contentPadding is 0
    property real normalContentHeight: {
        var h = 0;
        // VoiceDictation
        h += voiceDictation.visible ? voiceDictation.implicitHeight + 12 : 0;
        // NotificationList
        h += notificationList.visible ? notificationList.implicitHeight + 12 : 0;
        // Clock/Pomodoro header (fixed height 36)
        h += 36;
        
        return h + (Config.padding * 2);
    }

    // Extended section height - base only (detail panel adds dynamically)
    // property real extendedSectionBaseHeight: 32 + 8 + 1 + 12 // Tray row + spacing + separator + spacing

    contentHeight: normalContentHeight
    // Dynamic height: base + extended layout content + spacing
    extendedContentHeight: normalContentHeight + extendedLayout.implicitHeight + 12

    // Extended mode for SystemTray
    hasExtendedMode: true

    property bool clockForceShown: false
    
    // Track if user manually hid the panel via IPC while pomodoro is active
    property bool pomodoroForceHidden: false

    // Pomodoro is active when running work or break (not idle, not paused)
    readonly property bool pomodoroActive: pomodoroController && 
        pomodoroController.stage !== "idle" && 
        pomodoroController.stage !== "paused"

    // Auto-hide timer for normal mode (not extended)
    // Does NOT auto-hide when pomodoro is active (unless force hidden) - use IPC to hide manually
    Timer {
        id: autoHideTimer
        interval: 5000
        onTriggered: {
            if (!root.isHovered && !root.extended && 
                (!root.pomodoroActive) && 
                !notificationList.notificationForceShown && !voiceDictation.active) {
                root.revealed = false;
            }
        }
    }

    // Timer to restore revealed state after Panel base closes it (e.g., Escape key)
    Timer {
        id: revealRestoreTimer
        interval: 1
        onTriggered: {
            if (root.pomodoroActive && !root.pomodoroForceHidden) {
                root.revealed = true;
            }
        }
    }

    // Start/stop auto-hide timer based on reveal state
    // Also restore revealed if pomodoro is active and it was closed externally (e.g., click outside, Escape)
    onRevealedChanged: {
        if (revealed) {
            if (!extended && (!pomodoroActive)) {
                autoHideTimer.restart();
            } else {
                autoHideTimer.stop();
            }
        } else {
            autoHideTimer.stop();
            // Schedule restore if pomodoro is active and not force hidden
            if (pomodoroActive && !pomodoroForceHidden) {
                revealRestoreTimer.start();
            }
        }
    }

    onExtendedChanged: {
        if (extended) {
            autoHideTimer.stop();
        } else {
            // When closing extended mode, keep revealed if pomodoro is active
            if (pomodoroActive) {
                revealed = true;
            } else if (revealed) {
                autoHideTimer.restart();
            }
        }
    }

    onIsHoveredChanged: {
        if (isHovered) {
            autoHideTimer.stop();
        } else if (revealed && !extended && (!pomodoroActive || pomodoroForceHidden)) {
            autoHideTimer.restart();
        }
    }

    // When pomodoro becomes active, reveal panel (unless force hidden); when it stops, restart timer
    onPomodoroActiveChanged: {
        if (pomodoroActive) {
            autoHideTimer.stop();
            if (!pomodoroForceHidden) {
                revealed = true;
            }
        } else {
            pomodoroForceHidden = false;
            if (revealed && !extended && !isHovered) {
                autoHideTimer.restart();
            }
        }
    }

    // IPC handler to toggle notifications panel (oculto → normal → extended → oculto)
    IpcHandler {
        target: "ui.panel.notifications"
        function toggle(): void {
            // If hiding while pomodoro is active, mark as force hidden
            if (root.revealed && !root.extended && root.pomodoroActive) {
                root.pomodoroForceHidden = true;
            }
            root._ipcActivated = !root.revealed || root.extended;
            root.toggle();
        }
    }

    property bool wasRevealedBeforeNotification: false
    property string activeDetailPanel: ""

    Connections {
        target: notificationList
        function onNotificationForceShownChanged() {
            if (notificationList.notificationForceShown) {
                root.wasRevealedBeforeNotification = root.revealed;
                root.revealed = true;
            } else {
                if (!root.wasRevealedBeforeNotification && !root.isHovered) {
                    root.revealed = false;
                }
            }
        }
    }

    Connections {
        target: pomodoroController
        function onStageChanged() {
            // Reset force hidden on any stage change and reveal panel
            root.pomodoroForceHidden = false;
            if (pomodoroController.stage !== "idle" && pomodoroController.stage !== "paused") {
                 root.revealed = true;
            }
        }
    }

    // Content Structure
    property var pomodoroController // Injected from parent
    
    // Content Structure - ColumnLayout fills the content container (padding handled by Panel)
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Config.padding // Add manual padding since we disabled it on Panel
        spacing: 12

            // Content Area: System Tray + Indicators + Details
            Item {
                id: extendedContent
                Layout.fillWidth: true
                // Bind height to the window animation: Available space = Current - Normal - Spacing(12)
                // We subtract 12 because as soon as this item becomes visible, the ColumnLayout adds 12px spacing.
                // We want the total visual height added (Item + Spacing) to match the Window growth.
                Layout.preferredHeight: Math.max(0, root.currentContentHeight - root.normalContentHeight - 12)
                clip: true
                visible: Layout.preferredHeight > 0

                // Removed opacity animation to prevent content fading out before window closes
                opacity: 1.0

                // Focus first indicator when extended mode activates
                onVisibleChanged: {
                    if (visible && root.extended) {
                        Qt.callLater(() => {
                            if (cpuIndicator) cpuIndicator.forceActiveFocus();
                        });
                    }
                }

                ColumnLayout {
                    id: extendedLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 8

                // Top Row: System Tray and Indicators
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SystemTray {
                        id: systemTray
                        Layout.fillWidth: true
                        parentWindow: root.panelWindow
                    }

                    // Indicators (Horizontal, Right of Tray)
                    CpuIndicator {
                        id: cpuIndicator
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onExtendRequested: {
                            if (root.activeDetailPanel === "cpu") {
                                root.activeDetailPanel = "";
                            } else {
                                root.activeDetailPanel = "cpu";
                            }
                        }

                        KeyNavigation.right: memoryIndicator
                    }

                    MemoryIndicator {
                        id: memoryIndicator
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onExtendRequested: {
                            if (root.activeDetailPanel === "memory") {
                                root.activeDetailPanel = "";
                            } else {
                                root.activeDetailPanel = "memory";
                            }
                        }

                        KeyNavigation.left: cpuIndicator
                        KeyNavigation.right: netSpeedIndicator
                    }

                    NetSpeedIndicator {
                        id: netSpeedIndicator
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onExtendRequested: {
                            if (root.activeDetailPanel === "netspeed") {
                                root.activeDetailPanel = "";
                            } else {
                                root.activeDetailPanel = "netspeed";
                            }
                        }

                        KeyNavigation.left: memoryIndicator
                    }
                }

                // Bottom Area: Detail Managers (Height animates when indicator clicked)
                Item {
                    id: detailPanelContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: detailAnimatedHeight
                    clip: true


                    property real detailContentHeight: {
                        if (root.activeDetailPanel === "cpu") return cpuManager.implicitHeight;
                        if (root.activeDetailPanel === "memory") return memoryManager.implicitHeight;
                        if (root.activeDetailPanel === "netspeed") return netSpeedManager.implicitHeight;
                        return 0;
                    }

                    property real detailTargetHeight: (root.activeDetailPanel !== "" && root.activeDetailPanel !== "tray") ? detailContentHeight : 0
                    property real detailAnimatedHeight: detailTargetHeight

                    Behavior on detailAnimatedHeight {
                        NumberAnimation {
                            duration: Config.animationDurationMedium
                            easing.type: Config.animEasingStandard
                        }
                    }

                    CpuManager {
                        id: cpuManager
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: root.activeDetailPanel === "cpu"
                        cpuUsage: cpuIndicator.cpuUsage
                        coreModel: cpuIndicator.coreModel
                    }

                    MemoryManager {
                        id: memoryManager
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: root.activeDetailPanel === "memory"
                        memoryUsage: memoryIndicator.memoryUsage
                        memTotal: memoryIndicator.memTotal
                        memAvailable: memoryIndicator.memAvailable
                        memFree: memoryIndicator.memFree
                        buffers: memoryIndicator.buffers
                        cached: memoryIndicator.cached
                        swapTotal: memoryIndicator.swapTotal
                        swapFree: memoryIndicator.swapFree
                    }

                    NetSpeedManager {
                        id: netSpeedManager
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: root.activeDetailPanel === "netspeed"
                        downloadSpeed: netSpeedIndicator.downloadSpeed
                        uploadSpeed: netSpeedIndicator.uploadSpeed
                        activeInterface: netSpeedIndicator.activeInterface
                    }
                }

                // Separator between tray/details and clock/pomodoro
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Config.dimmed
                    opacity: 0.3
                }
            }
        }


        VoiceDictation {
            id: voiceDictation

            // Auto-reveal panel when active
            onActiveChanged: {
                if (active) {
                    root.wasRevealedBeforeNotification = root.revealed;
                    root.revealed = true;
                }
            }
        }

        // Notification List (Auto-shown when notifications exist)
        NotificationList {
            id: notificationList
            Layout.fillWidth: true
        }

        // Header: Clock & Pomodoro Indicators
        Item {
            Layout.fillWidth: true
            implicitHeight: 36

            RowLayout {
                anchors.fill: parent
                spacing: 12

                // Clock / Pomodoro Toggle Area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    PomodoroWidget {
                        anchors.fill: parent
                        pomodoroController: root.pomodoroController
                        clockForceShown: root.clockForceShown
                    }
                }
            }
        }
    }
}
