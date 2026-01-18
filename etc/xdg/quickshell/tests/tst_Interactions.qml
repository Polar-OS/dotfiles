import QtQuick 2.15
import "framework"
import "wrappers/status"
import Quickshell.Io 1.0

SimpleTest {
    name: "InteractionTests"

    WifiManager {
        id: wifiMgr
        width: 300
        height: 500
    }

    function findProcesses(parentItem) {
        var procs = [];
        if (parentItem.children) {
            for (var i = 0; i < parentItem.children.length; i++) {
                var child = parentItem.children[i];
                if (child.hasOwnProperty("command") && child.hasOwnProperty("runCount")) procs.push(child);
            }
        }
        return procs;
    }

    function test_wifi_toggle() {
        wifiMgr.wifiEnabled = true;
        var btn = wifiMgr.firstButton;
        verify(btn, "Toggle button found");
        
        var procs = findProcesses(wifiMgr);
        var initialCounts = procs.map(p => p.runCount);
        
        mouseClick(btn);
        
        // Find which process ran
        var ranProc = null;
        for (var i = 0; i < procs.length; i++) {
            if (procs[i].runCount > initialCounts[i]) {
                ranProc = procs[i];
                break;
            }
        }
        
        verify(ranProc, "A process ran after click");
        verify(ranProc.lastRunCommand[3] === "off", "Command was to turn off");
    }
}
