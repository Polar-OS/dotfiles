import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent
    Rectangle { anchors.fill: parent; color: "#111111" }

    // --- 1. Respawning Windows ---
    Repeater {
        model: 8
        Rectangle {
            id: win
            width: 200; height: 140
            color: "#000000"
            border.color: "#cccccc"
            border.width: 2
            
            // Random start pos
            property real startX: Math.random() * (root.width - 200)
            property real startY: Math.random() * (root.height - 140)
            x: startX; y: startY
            
            opacity: 0
            scale: 0.8
            
            // Lifecycle Animation: Pop In -> Drift -> Pop Out -> Respawn
            SequentialAnimation {
                running: true
                loops: Animation.Infinite
                
                // Spawn delay (randomized start)
                PauseAnimation { duration: Math.random() * 2000 }
                
                // Pop In
                ParallelAnimation {
                    NumberAnimation { target: win; property: "opacity"; to: 1; duration: Config.animationDurationMedium }
                    NumberAnimation { target: win; property: "scale"; to: 1; duration: Config.animationDurationMedium; easing.type: Config.animEasingBounce }
                }
                
                // Drift (Alive time)
                ParallelAnimation {
                    NumberAnimation { target: win; property: "x"; to: win.startX + (Math.random()-0.5)*100; duration: Config.animDurationSaverFast }
                    NumberAnimation { target: win; property: "y"; to: win.startY + (Math.random()-0.5)*100; duration: Config.animDurationSaverFast }
                }
                
                // Pop Out
                ParallelAnimation {
                    NumberAnimation { target: win; property: "opacity"; to: 0; duration: Config.animationDurationMedium }
                    NumberAnimation { target: win; property: "scale"; to: 0.5; duration: Config.animationDurationMedium; easing.type: Config.animEasingBounce }
                }
                
                // Reset Logic (ScriptAction to move to new spot)
                ScriptAction {
                    script: {
                        win.startX = Math.random() * (root.width - 200);
                        win.startY = Math.random() * (root.height - 140);
                        win.x = win.startX;
                        win.y = win.startY;
                    }
                }
            }
            
            // Content
            Text {
                anchors.centerIn: parent
                text: "wl_surface@" + index
                color: "#cccccc"
                font.family: Config.fontFamily
            }
            
            // Window decorations
            Rectangle { width: 10; height: 10; color: "white"; x: 5; y: 5 }
            Rectangle { width: 10; height: 10; color: "#666666"; x: 20; y: 5 }
        }
    }
    
    // --- 2. Protocol Stream ---
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        spacing: 2
        
        Repeater {
            model: 8
            Text {
                text: "-> wl_surface.attach()"
                color: "#666666"
                font.family: Config.fontFamily
                font.pixelSize: 12
                Timer {
                    interval: 50 + index * 10
                    running: true; repeat: true
                    onTriggered: {
                        if (Math.random() > 0.1) return;
                        var msgs = ["-> wl_surface.commit()", "<- wl_buffer.release()", "-> wl_shell_surface.pong()"];
                        parent.text = msgs[Math.floor(Math.random()*msgs.length)];
                    }
                }
            }
        }
    }
}
