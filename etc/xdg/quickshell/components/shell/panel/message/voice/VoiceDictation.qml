import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../../../ui/panel"
import "../../../../config"

Item {
    id: root
    
    // --- Configuration ---
    // We are now inside a layout, so explicit size is handled by Layout properties
    implicitHeight: active ? 80 : 0
    implicitWidth: 300 // Will be stretched by parent
    
    Layout.fillWidth: true
    Layout.preferredHeight: active ? 80 : 0
    
    visible: active
    
    // Ensure we animate height when toggling
    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: Config.animationDurationMedium; easing.type: Config.animEasingStandard }
    }
    
    // --- State ---
    property bool active: false
    property string state: "IDLE" // IDLE, RECORDING, PROCESSING
    property string statusText: "Ready"
    property string capturedText: ""
    
    // Dependency tracking
    property bool wtypeAvailable: false
    property bool pwRecordAvailable: false
    property bool modelAvailable: false
    property bool dependenciesChecked: false
    
    // Missing dependencies list for UI
    property var missingDependencies: {
        var missing = [];
        if (dependenciesChecked) {
            if (!modelAvailable) missing.push("Whisper model (~/.local/share/hyprflow/models/whisper-small.llamafile)");
            if (!pwRecordAvailable) missing.push("pw-record (pipewire)");
        }
        return missing;
    }
    property bool canOperate: dependenciesChecked && modelAvailable && pwRecordAvailable
    
    // Paths
    property string modelDir: Quickshell.env("HOME") + "/.local/share/hyprflow/models"
    property string modelPath: modelDir + "/whisper-small.llamafile"
    property string audioPath: "/tmp/voice_dictation.wav"
    
    // Check dependencies at startup
    Component.onCompleted: {
        wtypeCheckProcess.running = true
        pwRecordCheckProcess.running = true
        modelCheckProcess.running = true
    }
    
    // --- IPC Handler ---
    IpcHandler {
        target: "ui.overlay.voice"
        
        function toggle() {
            if (root.active) {
                if (root.state === "RECORDING") {
                    root.stopRecording()
                } else {
                    root.active = false
                }
            } else {
                root.active = true
                root.startRecording()
            }
        }
        
        function open() {
            if (!root.active) {
                root.active = true
                root.startRecording()
            }
        }

        function close() {
            if (root.active) {
                if (root.state === "RECORDING") {
                    root.stopRecording()
                }
                root.active = false
            }
        }
    }
    
    // --- Dependency Check ---
    Process {
        id: modelCheckProcess
        command: ["test", "-f", root.modelPath]
        onExited: (code) => {
            root.modelAvailable = (code === 0)
            root.updateDependencyStatus()
        }
    }
    
    function updateDependencyStatus() {
        // Check if all async checks are done
        if (modelCheckProcess.running === false && pwRecordCheckDone && wtypeCheckDone) {
            root.dependenciesChecked = true
        }
    }
    
    property bool pwRecordCheckDone: false
    property bool wtypeCheckDone: false
    
    // --- Processes ---
    
    // 0. Check if wtype is available
    Process {
        id: wtypeCheckProcess
        command: ["which", "wtype"]
        onExited: (code) => {
            root.wtypeAvailable = (code === 0)
            root.wtypeCheckDone = true
            root.updateDependencyStatus()
        }
    }
    
    // 0b. Check if pw-record is available
    Process {
        id: pwRecordCheckProcess
        command: ["which", "pw-record"]
        onExited: (code) => {
            root.pwRecordAvailable = (code === 0)
            root.pwRecordCheckDone = true
            root.updateDependencyStatus()
        }
    }
    
    // 1. Recording
    Process {
        id: recordProcess
        command: ["pw-record", "--rate", "16000", "--channels", "1", root.audioPath]
        
        onRunningChanged: {
            if (running) {
                root.state = "RECORDING"
                root.statusText = "Listening..."
            }
        }
    }
    
    // 2. Transcribing
    Process {
        id: transcribeProcess
        
        stdout: SplitParser {
            onRead: text => {
                root.capturedText += text
            }
        }
        
        onRunningChanged: {
            if (running) {
                root.state = "PROCESSING"
                root.statusText = "Processing..."
                root.capturedText = ""
            } else if (!running && root.state === "PROCESSING") {
                root.finish()
            }
        }
    }
    
    // 3. Typing Action (optional - requires wtype)
    Process {
        id: typeProcess
        command: ["true"] // Placeholder
        
        onExited: (code) => {
            if (code !== 0) {
                // wtype failed, show notification
                notifyProcess.running = true
            }
        }
    }
    
    // 4. Send notification (fallback when wtype not available)
    Process {
        id: notifyProcess
        command: ["notify-send", "-a", "Voice Dictation", "-i", "edit-paste", "Text copied to clipboard", root.capturedText]
    }
    
    // --- Logic ---
    
    function startRecording() {
        // Don't start if critical dependencies are missing
        if (!root.canOperate) {
            return
        }
        
        recordProcess.running = true
    }
    
    function stopRecording() {
        recordProcess.running = false
        // Trigger transcription
        // Run via sh because llamafiles are actually shell scripts (APE)
        // and direct execution might fail if binfmt_misc isn't set up.
        transcribeProcess.command = ["sh", root.modelPath, "-f", root.audioPath, "--no-timestamps", "--log-disable", "--language", "es"]
        transcribeProcess.running = true
    }
    
    function finish() {
        root.state = "IDLE"
        root.statusText = "Done"
        
        if (root.capturedText.trim() !== "") {
            root.capturedText = root.capturedText.trim()
            root.active = false // Hide
            
            // Always copy to clipboard using native Quickshell API
            Quickshell.clipboardText = root.capturedText
            
            if (root.wtypeAvailable) {
                // Auto-type with wtype if available
                typeProcess.command = ["wtype", "-d", "2", root.capturedText]
                typeProcess.running = true
            } else {
                // No wtype, just notify user that text is in clipboard
                notifyProcess.command = ["notify-send", "-a", "Voice Dictation", "-i", "edit-paste", "Text copied to clipboard", root.capturedText]
                notifyProcess.running = true
            }
        } else {
            root.active = false
        }
    }
    
    property real animPhase: 0.0

    // --- Visualizer Timer ---
    Timer {
        id: vizTimer
        interval: 50
        repeat: true
        running: root.state === "RECORDING" || root.state === "PROCESSING"
        onTriggered: {
            if (root.state === "RECORDING") {
                for (var i = 0; i < vizRepeater.count; i++) {
                    vizRepeater.itemAt(i).targetHeight = Math.random()
                }
            } else if (root.state === "PROCESSING") {
                root.animPhase += 0.4
                for (var i = 0; i < vizRepeater.count; i++) {
                    // Sine Wave Computing Effect
                    var x = i * 0.3 + root.animPhase
                    var val = (Math.sin(x) + 1.0) / 2.0
                    vizRepeater.itemAt(i).targetHeight = val
                }
            }
        }
    }
    
    // --- Visuals ---
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: Config.itemRadius
        
        // Missing dependencies view
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: !root.canOperate && root.dependenciesChecked
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰀦 Missing Dependencies"
                color: Config.red
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            
            Repeater {
                model: root.missingDependencies
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "• " + modelData
                    color: Config.dimmed
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: root.width - 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.wtypeAvailable === false && root.wtypeCheckDone
                text: "(wtype optional - for auto-typing)"
                color: Config.dimmed
                font.family: Config.fontFamily
                font.pixelSize: 10
                font.italic: true
            }
        }
        
        // Normal operation view
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: root.canOperate || !root.dependenciesChecked
            
            // Status Text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.statusText
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            
            // Visualizer Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Repeater {
                        id: vizRepeater
                        model: 30 
                        
                        Rectangle {
                            id: bar
                            property real targetHeight: 0.1
                            
                            Layout.preferredWidth: 4
                            // Use wave height for PROCESSING too
                            Layout.preferredHeight: 30 * (root.state === "IDLE" ? 0.1 : (0.2 + bar.targetHeight * 0.8))
                            Layout.alignment: Qt.AlignVCenter
                            
                            color: root.state === "PROCESSING" ? Config.cyan : (root.state === "RECORDING" ? Config.accent : Config.dimmed)
                            radius: Config.itemRadius
                            
                            Behavior on Layout.preferredHeight {
                                NumberAnimation { duration: Config.animDurationFast }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: Config.animDurationRegular }
                            }
                        }
                    }
                }
            }
            
            // Hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.state === "RECORDING" ? "Click to Stop" : " "
                color: Config.dimmed
                font.family: Config.fontFamily
                font.pixelSize: 10
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.state === "RECORDING") {
                    root.stopRecording()
                }
            }
        }
    }
}
