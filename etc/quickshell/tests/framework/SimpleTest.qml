import QtQuick 2.0

Item {
    id: root
    property int passed: 0
    property int failed: 0
    property string name: "Test"
    
    Component.onCompleted: {
        // Run delayed to ensure children are ready and layouts settle
        timer.start()
    }

    Timer {
        id: timer
        interval: 100 // Increased delay
        onTriggered: root.run()
    }
    
    function run() {
        console.error("STARTING: " + name)
        
        for (var p in root) {
             if (p.startsWith("test_") && typeof root[p] === "function") {
                try {
                    root[p]()
                    console.error("PASS: " + p)
                    passed++
                } catch(e) {
                    console.error("FAIL: " + p + " - " + e)
                    failed++
                }
            }
        }
        
        console.error("FINISHED: " + name + " Passed: " + passed + " Failed: " + failed)
        if (failed > 0) console.error("TEST_SUITE_FAILED")
        else console.error("TEST_SUITE_PASSED")
        Qt.quit()
    }
    
    function compare(actual, expected, msg) {
        if (actual != expected) throw (msg || "") + " Expected " + expected + ", got " + actual
    }
    
    function verify(cond, msg) {
        if (!cond) throw (msg || "") + " Verification failed"
    }
    
    function mouseClick(item) {
        if (item && item.clicked) {
            // Provide a dummy mouse event object
            // This satisfies MouseArea (expects 1 arg)
            // and works for signals with 0 args (ignores extra arg)
            var mouseEvent = { 
                x: 0, y: 0, 
                button: Qt.LeftButton, 
                buttons: Qt.LeftButton, 
                modifiers: Qt.NoModifier,
                wasHeld: false,
                isClick: true,
                accepted: true
            }
            try {
                item.clicked(mouseEvent)
            } catch(e) {
                // Fallback for strict signals or different signatures
                try { item.clicked() } catch(e2) {}
            }
        }
    }
}
