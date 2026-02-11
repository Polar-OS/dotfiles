import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent
    
    Rectangle { anchors.fill: parent; color: "#000804" }

    // --- 1. CPU Cores Load (Visualized as Bars) ---
    Row {
        anchors.centerIn: parent
        spacing: 10
        
        Repeater {
            model: 16 // 16 Cores
            Rectangle {
                width: 20
                height: 200
                color: "#111111"
                border.color: "#00E676"
                border.width: 1
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.random() * parent.height
                    color: "#00E676"
                    opacity: 0.8
                    
                    Timer {
                        interval: 50
                        running: true; repeat: true
                        onTriggered: parent.height = Math.random() * 200
                    }
                }
            }
        }
    }
    
    // --- 2. High Speed Compilation Log ---
    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 100
        text: "Compiling linux-cachyos..."
        font.family: Config.fontFamily
        color: "white"
        font.bold: true
    }
    
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        spacing: 2
        
        Repeater {
            model: 5
            Text {
                text: "CC drivers/gpu/drm/amd/amdgpu/amdgpu_drv.o"
                color: "#00E676"
                font.family: Config.fontFamily
                font.pixelSize: 10
                
                Timer {
                    interval: 20 // Super fast
                    running: true; repeat: true
                    onTriggered: {
                        var files = ["mm/page_alloc.o", "fs/btrfs/inode.o", "kernel/sched/core.o", "net/ipv4/tcp.o", "drivers/net/wireless/ath11k/core.o"];
                        parent.text = "CC " + files[Math.floor(Math.random()*files.length)];
                    }
                }
            }
        }
    }
    
    // --- 3. FPS Counter (Thematic) ---
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        text: "FPS: 9999"
        color: "#00ff00"
        font.family: Config.fontFamily
        font.pixelSize: 24
        font.bold: true
        
        Timer {
            interval: 100
            running: true; repeat: true
            onTriggered: parent.text = "FPS: " + (9000 + Math.floor(Math.random()*999))
        }
    }
}
