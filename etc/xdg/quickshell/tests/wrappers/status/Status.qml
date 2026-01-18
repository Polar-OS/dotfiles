import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire 1.0
import "../../../ui/button"
import Quickshell.Io 1.0
import "."
import "../base"
import "./media"
import ".."

// Inherits directly from Panel
Panel {
    id: root

    position: "right"

    // Extended Mode Configuration
    hasExtendedMode: true

    // Normal Mode Dimensions (Vertical Strip)
    contentWidth: verticalContent.implicitWidth + Config.padding * 2 // Use explicit Config.padding
    contentHeight: verticalContent.implicitHeight + Config.padding * 2
    contentPadding: 0 // Disable default padding from PanelStyle


    // Extended Mode Dimensions (same height, adds extended panel to the left)
    extendedContentWidth: Config.panelWidth + Config.padding + contentWidth // Use explicit Config.padding
    extendedContentHeight: contentHeight

    required property var logoutTarget
    property var cheatsheetTarget
    property var aboutTarget
    property var mprisController

    property bool caffeineActive: false

    // Track which extended panel is active: "media", "bluetooth", or "wifi"
    property string extendedPanel: "media"

    // MPRIS controller instance (injected)
    // MprisController {
    //     id: mprisController
    // }

    // ==================== SHORTCUTS ====================
    // Escape shortcut handled by Panel.qml in extended mode
    // This shortcut only applies to non-extended mode
    Shortcut {
        sequence: "Escape"
        enabled: !root.extended
        onActivated: {
            root.revealed = false;
        }
    }

    // ==================== TIMERS ====================
    // Auto-hide timer for normal mode (not extended)
    Timer {
        id: statusHideTimer
        interval: Config.autoHideDelay
        onTriggered: {
            // If we are not hovering and not in extended mode, hide
            if (!root.isHovered && !root.extended) {
                root.revealed = false;
            }
        }
    }

    // Start/stop auto-hide timer based on reveal state
    onRevealedChanged: {
        if (revealed && !extended) {
            statusHideTimer.restart();
        } else {
            statusHideTimer.stop();
        }
    }

    onExtendedChanged: {
        if (extended) {
            statusHideTimer.stop();
        } else if (revealed) {
            statusHideTimer.restart();
        }
    }

    onIsHoveredChanged: {
        if (isHovered) {
            statusHideTimer.stop();
        } else if (revealed && !extended) {
            statusHideTimer.restart();
        }
    }

    // ==================== IPC HANDLERS ====================
    // IPC handler to toggle status panel (hidden → visible → extended → visible → hidden)
    IpcHandler {
        target: "ui.panel.status"

        function open(): void {
            root._ipcActivated = true;
            root.revealed = true;
        }

        function close(): void {
            root._ipcActivated = false;
            root.revealed = false;
            root.extended = false;
        }

        function toggle(): void {
            // Toggle IPC activation state
            if (!root.revealed) {
                root._ipcActivated = true;
            } else {
                root._ipcActivated = false;
            }
            root.toggle();
        }
    }

    // Global Overlay IPC Handlers
    IpcHandler {
        target: "ui.dialog.logout"
        function toggle() { if (logoutTarget) logoutTarget.active = !logoutTarget.active }
        function open() { if (logoutTarget) logoutTarget.active = true }
        function close() { if (logoutTarget) logoutTarget.active = false }
    }

    IpcHandler {
        target: "ui.dialog.cheatsheet"
        function toggle() { 
            if (cheatsheetTarget) {
                cheatsheetTarget.active = !cheatsheetTarget.active 
                if (cheatsheetTarget.active) cheatsheetTarget.searchQuery = ""
            }
        }
        function open() { 
            if (cheatsheetTarget) {
                cheatsheetTarget.active = true 
                cheatsheetTarget.searchQuery = ""
            }
        }
        function close() { if (cheatsheetTarget) cheatsheetTarget.active = false }
    }

    IpcHandler {
        target: "ui.dialog.about"
        function toggle() { if (aboutTarget) aboutTarget.active = !aboutTarget.active }
        function open() { if (aboutTarget) aboutTarget.active = true }
        function close() { if (aboutTarget) aboutTarget.active = false }
    }

    IpcHandler {
        target: "ui.panel.bluetooth"

        function open(): void {
            root.extendedPanel = "bluetooth";
            root.extended = true;
            root.revealed = true;
        }

        function close(): void {
            if (root.extendedPanel === "bluetooth") {
                root.extended = false;
            }
        }

        function toggle(): void {
            if (root.revealed && root.extended && root.extendedPanel === "bluetooth") {
                root.revealed = false;
                root.extended = false;
            } else {
                root.extendedPanel = "bluetooth";
                root.extended = true;
                root.revealed = true;
            }
        }
    }

    IpcHandler {
        target: "ui.panel.wifi"

        function open(): void {
            root.extendedPanel = "wifi";
            root.extended = true;
            root.revealed = true;
        }

        function close(): void {
            if (root.extendedPanel === "wifi") {
                root.extended = false;
            }
        }

        function toggle(): void {
            if (root.revealed && root.extended && root.extendedPanel === "wifi") {
                root.revealed = false;
                root.extended = false;
            } else {
                root.extendedPanel = "wifi";
                root.extended = true;
                root.revealed = true;
            }
        }
    }

    IpcHandler {
        target: "ui.panel.audio"

        function open(): void {
            root.extendedPanel = "media";
            root.extended = true;
            root.revealed = true;
        }

        function close(): void {
            if (root.extendedPanel === "media") {
                root.extended = false;
            }
        }

        function toggle(): void {
            if (root.revealed && root.extended && root.extendedPanel === "media") {
                root.revealed = false;
                root.extended = false;
            } else {
                root.extendedPanel = "media";
                root.extended = true;
                root.revealed = true;
            }
        }
    }

    IpcHandler {
        target: "ui.panel.battery"

        function open(): void {
            root.extendedPanel = "battery";
            root.extended = true;
            root.revealed = true;
        }

        function close(): void {
            if (root.extendedPanel === "battery") {
                root.extended = false;
            }
        }

        function toggle(): void {
            if (root.revealed && root.extended && root.extendedPanel === "battery") {
                root.revealed = false;
                root.extended = false;
            } else {
                root.extendedPanel = "battery";
                root.extended = true;
                root.revealed = true;
            }
        }
    }


    // Vertical layout - always anchored right for stable positioning during animations
    // In normal mode: panel width matches content, so it appears centered
    // In extended mode: panel expands left, widgets stay fixed at right edge
    ColumnLayout {
        id: verticalContent
        z: 1  // Keep above extended panels during animation
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Config.padding // Manually apply right margin
        spacing: Config.spacing
        focus: !root.extended

        VolumeBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 120
            showOnVolumeChange: true
            onShowRequested: {
                root.revealed = true;
                statusHideTimer.restart();
            }
        }

        VolumeIcon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 12
            Layout.preferredHeight: 24
            pixelSize: 18
            clickMargin: -10
            volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
            muted: Pipewire.defaultAudioSink?.audio.muted ?? false
        }

        QuickButton {
            id: caffeineBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            size: 40
            icon: "󰅶"
            active: root.caffeineActive

            onClicked: {
                root.caffeineActive = !root.caffeineActive;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: null
            KeyNavigation.down: playerIndicator

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
                width: 6
                height: 6
                radius: Config.itemRadius
                color: Config.accent
                visible: root.caffeineActive
            }
        }

        PlayerIndicator {
            id: playerIndicator
            Layout.alignment: Qt.AlignHCenter
            player: mprisController.mprisPlayer

            onExtendRequested: {
                root.extendedPanel = "media";
                root.extended = true;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: caffeineBtn
            KeyNavigation.down: batteryBtn
        }

        BatteryIndicator {
            id: batteryBtn
            Layout.alignment: Qt.AlignHCenter
            onExtendRequested: {
                root.extendedPanel = "battery";
                root.extended = true;
                root.revealed = true;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: playerIndicator
            KeyNavigation.down: bluetoothBtn
        }

        BluetoothIndicator {
            id: bluetoothBtn
            Layout.alignment: Qt.AlignHCenter

            onExtendRequested: {
                root.extendedPanel = "bluetooth";
                root.extended = true;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: batteryBtn
            KeyNavigation.down: wifiBtn
        }



        WifiIndicator {
            id: wifiBtn
            Layout.alignment: Qt.AlignHCenter

            onExtendRequested: {
                root.extendedPanel = "wifi";
                root.extended = true;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: bluetoothBtn
            KeyNavigation.down: logoutBtn
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 30
            Layout.preferredHeight: 1
            color: Config.foreground
            opacity: 0.3
        }

        QuickButton {
            id: logoutBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            size: Config.buttonSize
            icon: "󰐥"

            onClicked: {
                console.log("Logout clicked, logoutTarget:", root.logoutTarget);
                root.logoutTarget.active = true;
                root.revealed = false;
            }

            KeyNavigation.left: root.extended ? (root.extendedPanel === "wifi" ? wifiManager.firstButton : (root.extendedPanel === "bluetooth" ? bluetoothManager.firstButton : (root.extendedPanel === "battery" ? batteryManager.firstButton : (root.extendedPanel === "media" ? mprisPlayer.playButton : null)))) : null
            KeyNavigation.up: wifiBtn
        }
    }

    // Extended mode: Media Player panel
    ExtendedPanel {
        id: mediaPlayerPanel
        active: root.extended && root.extendedPanel === "media"
        progress: root.extendedProgress

        // Focus first element when extended mode activates
        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    if (mprisPlayer && mprisPlayer.playButton) mprisPlayer.playButton.forceActiveFocus();
                });
            }
        }

        // Content wrapper with delayed visibility to prevent layout flash
        Item {
            id: mediaContentWrapper
            anchors.fill: parent
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.padding
                spacing: Config.spacing

                MprisPlayer {
                    id: mprisPlayer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    player: mprisController.mprisPlayer
                    trackedPosition: mprisController.trackedPosition
                    allPlayers: mprisController.allPlayers
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.alpha(Config.foreground, 0.2)
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.extended && root.extendedPanel === "media"
                    sourceComponent: pipewireSelectorComponent
                }

                Component {
                    id: pipewireSelectorComponent
                    PipewireDeviceSelector {
                        width: parent.width
                    }
                }
            }
        }

        // Reactive key navigation bindings
        Binding {
            target: mprisPlayer.prevButton.KeyNavigation
            property: "right"
            value: mprisPlayer.playButton
        }
        Binding {
            target: mprisPlayer.playButton.KeyNavigation
            property: "left"
            value: mprisPlayer.prevButton.visible ? mprisPlayer.prevButton : null
        }
        Binding {
            target: mprisPlayer.playButton.KeyNavigation
            property: "right"
            value: mprisPlayer.nextButton.visible ? mprisPlayer.nextButton : caffeineBtn
        }
        Binding {
            target: mprisPlayer.nextButton.KeyNavigation
            property: "left"
            value: mprisPlayer.playButton
        }
        Binding {
            target: mprisPlayer.nextButton.KeyNavigation
            property: "right"
            value: caffeineBtn
        }
    }

    // Extended mode: Bluetooth Manager panel
    ExtendedPanel {
        id: bluetoothPanel
        active: root.extended && root.extendedPanel === "bluetooth"
        progress: root.extendedProgress

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    if (bluetoothManager && bluetoothManager.firstButton) bluetoothManager.firstButton.forceActiveFocus();
                });
            }
        }

        BluetoothManager {
            id: bluetoothManager
            anchors.fill: parent
            anchors.margins: Config.padding
            menuButton: bluetoothBtn
        }

        Binding {
            target: bluetoothManager.firstButton.KeyNavigation
            property: "right"
            value: bluetoothBtn
        }
    }

    // Extended mode: WiFi Manager panel
    ExtendedPanel {
        id: wifiPanel
        active: root.extended && root.extendedPanel === "wifi"
        progress: root.extendedProgress

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    if (wifiManager && wifiManager.firstButton) wifiManager.firstButton.forceActiveFocus();
                });
            }
        }

        WifiManager {
            id: wifiManager
            anchors.fill: parent
            anchors.margins: Config.padding
            menuButton: wifiBtn
        }

        Binding {
            target: wifiManager.firstButton.KeyNavigation
            property: "right"
            value: wifiBtn
        }
    }

    // Extended mode: Battery Manager panel
    ExtendedPanel {
        id: batteryPanel
        active: root.extended && root.extendedPanel === "battery"
        progress: root.extendedProgress

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    if (batteryManager && batteryManager.firstButton) batteryManager.firstButton.forceActiveFocus();
                });
            }
        }

        BatteryManager {
            id: batteryManager
            anchors.fill: parent
            anchors.margins: Config.padding
        }

        Binding {
            target: batteryManager.firstButton.KeyNavigation
            property: "right"
            value: batteryBtn
        }
    }
}
