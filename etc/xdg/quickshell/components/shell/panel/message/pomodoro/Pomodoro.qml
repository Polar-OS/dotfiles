import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../config"

// Component that manages Pomodoro timer state and control
Item {
    id: root

    // Internal State
    property string internalStage: "idle" // idle, work, break, long-break
    property bool isPaused: false
    property int timeLeft: 0
    property int totalDuration: 1
    property int cycleCount: 0
    
    // Dependency Check
    property bool soundAvailable: false
    property bool dependencyChecked: false
    
    Process {
        id: soundCheck
        command: ["which", "pw-play"]
        onExited: (code) => {
            root.soundAvailable = (code === 0);
            root.dependencyChecked = true;
        }
    }
    
    Component.onCompleted: soundCheck.running = true

    // Public Properties (Compatibility & UI)
    readonly property string stage: isPaused ? "paused" : internalStage
    
    // Shared state for focus management
    property bool overlayVisible: false
    
    readonly property string statusText: {
        if (internalStage === "idle") return "00:00"
        let m = Math.floor(timeLeft / 60)
        let s = timeLeft % 60
        // Zero pad
        let mStr = m.toString().padStart(2, '0')
        let sStr = s.toString().padStart(2, '0')
        return `${mStr}:${sStr}`
    }

    readonly property real percentage: internalStage === "idle" ? 0 : 
        Math.min(100, Math.max(0, (timeLeft / totalDuration) * 100))

    Process {
        id: soundProcess
        command: ["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    Timer {
        id: tickTimer
        interval: 1000
        running: root.internalStage !== "idle" && !root.isPaused
        repeat: true
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft -= 1
            } else {
                if (root.internalStage.includes("break") && root.soundAvailable) {
                    soundProcess.running = true
                }
                root.nextStage()
            }
        }
    }

    function startWork() {
        // Reset cycle count if coming from long-break
        if (internalStage === "long-break") {
            cycleCount = 0
        } else if (internalStage === "break") {
            // Only increment when starting a new cycle from a short break
            cycleCount++
        }

        internalStage = "work"
        isPaused = false
        totalDuration = Config.pomodoroDuration * 60
        timeLeft = totalDuration
    }

    function startBreak() {
        isPaused = false
        
        // Check for long break
        // We look at (cycleCount + 1) because cycleCount is 0-based index of current cycle.
        // If cycleCount is 3, we just finished the 4th pomodoro.
        let completedPomodoros = cycleCount + 1
        
        if (completedPomodoros > 0 && completedPomodoros % Config.pomodoroCycleCount === 0) {
             internalStage = "long-break"
             totalDuration = Config.pomodoroLongBreakDuration * 60
        } else {
             internalStage = "break"
             totalDuration = Config.pomodoroBreakDuration * 60
        }
        timeLeft = totalDuration
    }
    
    function startSpecificBreak() {
        // Force a short break regardless of cycles (for manual trigger)
        internalStage = "break"
        isPaused = false
        totalDuration = Config.pomodoroBreakDuration * 60
        timeLeft = totalDuration
    }

    function pause() {
        if (internalStage !== "idle") {
            isPaused = !isPaused
        }
    }
    
    function stop() {
        internalStage = "idle"
        isPaused = false
        timeLeft = 0
        cycleCount = 0
    }

    function nextStage() {
        if (internalStage === "work") {
            startBreak()
        } else if (internalStage === "long-break") {
            // Reset cycle count after long break ends
            cycleCount = 0
            startWork()
        } else if (internalStage === "break") {
            startWork()
        }
    }

    function toggleType() {
        if (internalStage === "idle") {
            // Start break immediately if toggled from idle? Or start work?
            // User likely wants to switch MODE to start.
            // But currently start() always starts work.
            // Let's say if idle, we start break.
            startSpecificBreak()
            return
        }
        
        if (internalStage.includes("work")) {
            startBreak()
        } else {
            startWork()
        }
    }

    // IPC Handler
    // Usage: qs ipc call ui.timer.pomodoro [command]
    IpcHandler {
        target: "ui.timer.pomodoro"
        
        function startWork() { root.startWork() }
        function startBreak() { root.startBreak() }
        function pause() { root.pause() }
        function stop() { root.stop() }
        function toggle() { root.pause() }

        // Aliases for compatibility/convenience if desired, or strict adherence to new names?
        // User asked for "more sense". Let's stick to the new names.
        // If start() is ambiguous (start what?), startWork() is better.
        // But start() is commonly understood as start the timer.
        // However, I will map start() to startWork() just in case, but rely on startWork() as the primary.
        // Wait, "cambiame los metodos... a algo que tenga mas sensito".
        // Maybe he wants JUST startWork and startBreak.
        // I will provide explicit names.
        
        function start() { root.startWork() } // Keep as alias
    }
}
