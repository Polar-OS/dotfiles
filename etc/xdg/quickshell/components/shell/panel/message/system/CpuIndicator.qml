import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../../ui/indicators" // BaseIndicator
import "../../../../config"
import "../../../../ui/panel"

BaseIndicator {
    id: root

    property real cpuUsage: 0
    
    // Core stats
    property var prevCpuData: ""
    property real prevTotal: 0
    property real prevIdle: 0
    property bool cpuInitialized: false
    
    property var coreHistory: ({})
    property alias coreModel: coreModelInternal
    
    ListModel {
        id: coreModelInternal
    }

    function getCpuColor() {
        if (root.cpuUsage >= 80)
            return Config.statusCritical;
        if (root.cpuUsage >= 50)
            return Config.statusWarning;
        if (root.cpuUsage >= 30)
            return Config.statusMedium;
        return Config.statusGood;
    }

    // Configure BaseIndicator properties
    fillPercentage: root.cpuUsage
    fillColor: getCpuColor()
    icon: "󰘚"
    iconPixelSize: 18

    Process {
        id: cpuProcess
        command: ["cat", "/proc/stat"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split('\n');
                let coreIdx = 0;
                
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith('cpu')) {
                        let parts = lines[i].split(/\s+/).filter(x => x);
                        if (parts.length >= 8) {
                            let name = parts[0];
                            let user = parseFloat(parts[1]);
                            let nice = parseFloat(parts[2]);
                            let system = parseFloat(parts[3]);
                            let idle = parseFloat(parts[4]);
                            let iowait = parseFloat(parts[5]);
                            let irq = parseFloat(parts[6]);
                            let softirq = parseFloat(parts[7]);

                            let total = user + nice + system + idle + iowait + irq + softirq;
                            let totalIdle = idle + iowait;
                            let usage = 0;

                            // Total CPU
                            if (name === 'cpu') {
                                if (root.cpuInitialized) {
                                    let totalDiff = total - root.prevTotal;
                                    let idleDiff = totalIdle - root.prevIdle;
                                    if (totalDiff > 0) {
                                        usage = 100 * (1 - idleDiff / totalDiff);
                                        root.cpuUsage = Math.min(100, Math.max(0, usage));
                                    }
                                } else {
                                    root.cpuInitialized = true;
                                }
                                root.prevTotal = total;
                                root.prevIdle = totalIdle;
                            } 
                            // Individual Cores
                            else {
                                if (!root.coreHistory[name]) {
                                    root.coreHistory[name] = { total: total, idle: totalIdle };
                                } else {
                                    let prev = root.coreHistory[name];
                                    let diffTotal = total - prev.total;
                                    let diffIdle = totalIdle - prev.idle;
                                    if (diffTotal > 0) {
                                        let u = 100 * (1 - diffIdle / diffTotal);
                                        usage = Math.min(100, Math.max(0, u));
                                    }
                                    prev.total = total;
                                    prev.idle = totalIdle;
                                }
                                
                                if (coreIdx < coreModelInternal.count) {
                                    coreModelInternal.setProperty(coreIdx, "usage", usage);
                                    coreModelInternal.setProperty(coreIdx, "name", name);
                                } else {
                                    coreModelInternal.append({ "name": name, "usage": usage });
                                }
                                coreIdx++;
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            cpuProcess.running = true;
        }
    }
}
