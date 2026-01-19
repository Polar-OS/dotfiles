import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../../../ui/indicators" // InteractiveBar
import "../../../../config"

InteractiveBar {
    id: root

    property bool autoConnect: true
    property bool showOnVolumeChange: true
    
    // Layout props (required because InteractiveBar is a Rectangle)
    Layout.fillHeight: orientation === Qt.Vertical
    Layout.fillWidth: orientation === Qt.Horizontal
    Layout.alignment: Qt.AlignHCenter
    
    // InteractiveBar props
    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
    activeColor: Config.foreground
    inactiveColor: (!root.dependencyChecked || root.pipewireAvailable) ? Qt.alpha(Config.foreground, 0.2) : Qt.alpha(Config.red, 0.2)
    stepSize: 0.05
    interactive: root.pipewireAvailable
    
    // Dependency check
    property bool pipewireAvailable: false
    property bool dependencyChecked: false
    
    // Check if pipewire is installed
    Process {
        id: pwCheckProcess
        command: ["which", "pipewire"]
        onExited: (code) => {
            root.pipewireAvailable = (code === 0);
            root.dependencyChecked = true;
        }
    }
    
    Component.onCompleted: {
        pwCheckProcess.running = true;
    }
    
    // Tooltip for missing dependency
    ToolTip {
        visible: tooltipArea.containsMouse && root.dependencyChecked && !root.pipewireAvailable
        text: "Missing Dependency: pipewire"
        delay: 0
    }

    // Handle value changes
    onUserModified: (newValue) => {
        if (Pipewire.defaultAudioSink?.audio) {
            Pipewire.defaultAudioSink.audio.volume = newValue;
        }
    }

    // Auto-connection to Pipewire
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Show OSD when volume/mute changes
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            if (root.showOnVolumeChange) {
                root.showRequested();
            }
        }

        function onMutedChanged() {
            if (root.showOnVolumeChange) {
                root.showRequested();
            }
        }
    }
    
    // MouseArea for ToolTip when disabled
    MouseArea {
        id: tooltipArea
        anchors.fill: parent
        enabled: root.dependencyChecked && !root.pipewireAvailable
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
