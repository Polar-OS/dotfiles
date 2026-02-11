import QtQuick 2.0
Item {
    property var command: []
    property bool running: false
    property var stdout: null 
    
    // Test introspection
    property int runCount: 0
    property var lastRunCommand: []
    
    signal exited(int code)
    
    onRunningChanged: {
        if (running) {
            runCount++;
            lastRunCommand = command;
            console.log("Mock Process running: " + (command ? command.join(" ") : ""))
            
            if (stdout) {
                stdout.read("{}")
            }
            
            // Async behavior simulation for tests
            running = false
            exited(0)
        }
    }
}
