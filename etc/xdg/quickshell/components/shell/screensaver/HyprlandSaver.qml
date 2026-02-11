import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent

    // --- Background: Minimal Grid ---
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e" // Catppuccin Base
        
        Repeater {
            model: 20
            Rectangle {
                x: 0; y: index * (root.height/20)
                width: root.width; height: 1
                color: "#313244"
                opacity: 0.5
            }
        }
        Repeater {
            model: 20
            Rectangle {
                x: index * (root.width/20); y: 0
                width: 1; height: root.height
                color: "#313244"
                opacity: 0.5
            }
        }
    }

    // --- WORKSPACE CONTAINER ---
        // We simulate sliding workspaces by moving a large row of items left/right
    Item {
        id: workspaceStrip
        width: root.width * 3 // 3 Workspaces wide
        height: root.height
        x: 0 // Will animate
        
        Behavior on x { NumberAnimation { duration: Config.animDurationBackground; easing.type: Config.animEasingPanel } }

        // --- WORKSPACE 1: GRID LAYOUT ---
        Item {
            width: root.width; height: root.height
            x: 0
            
            Grid {
                anchors.centerIn: parent
                columns: 2; spacing: 20
                Repeater {
                    model: 4
                    Rectangle {
                        width: 300; height: 200
                        color: "#181825"
                        border.color: index === 0 ? "#89b4fa" : "#45475a"
                        border.width: 3
                        radius: 5
                        Text { anchors.centerIn: parent; text: "term_" + index; color: "white"; font.family: Config.fontFamily }
                    }
                }
            }
            Text { anchors.top: parent.top; anchors.margins: 50; anchors.horizontalCenter: parent.horizontalCenter; text: "WS 1: GRID"; color: "white"; font.bold: true; font.family: Config.fontFamily }
        }

        // --- WORKSPACE 2: MASTER LAYOUT ---
        Item {
            width: root.width; height: root.height
            x: root.width
            
            Row {
                anchors.centerIn: parent
                spacing: 20
                // Master
                Rectangle {
                    width: 500; height: 400
                    color: "#181825"
                    border.color: "#a6e3a1"
                    border.width: 3
                    radius: 5
                    Text { anchors.centerIn: parent; text: "firefox"; color: "white"; font.family: Config.fontFamily }
                }
                // Stack
                Column {
                    spacing: 20
                    Repeater {
                        model: 2
                        Rectangle {
                            width: 200; height: 190
                            color: "#181825"
                            border.color: "#45475a"
                            border.width: 3
                            radius: 5
                            Text { anchors.centerIn: parent; text: "chat"; color: "white"; font.family: Config.fontFamily }
                        }
                    }
                }
            }
            Text { anchors.top: parent.top; anchors.margins: 50; anchors.horizontalCenter: parent.horizontalCenter; text: "WS 2: MASTER"; color: "white"; font.bold: true; font.family: Config.fontFamily }
        }

        // --- WORKSPACE 3: FULLSCREEN ---
        Item {
            width: root.width; height: root.height
            x: root.width * 2
            
            Rectangle {
                anchors.centerIn: parent
                width: 800; height: 500
                color: "#181825"
                border.color: "#f38ba8"
                border.width: 3
                radius: 5
                
                Text {
                    anchors.centerIn: parent
                    text: "mpv --fs anime.mkv"
                    color: "white"
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                }
                
                // Fake video progress bar
                Rectangle {
                    width: parent.width; height: 5
                    anchors.bottom: parent.bottom
                    color: "#f38ba8"
                    
                    Rectangle {
                        width: 10; height: 10
                        radius: 5
                        color: "white"
                        x: parent.width * 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Text { anchors.top: parent.top; anchors.margins: 50; anchors.horizontalCenter: parent.horizontalCenter; text: "WS 3: FULL"; color: "white"; font.bold: true; font.family: Config.fontFamily }
        }
    }

    // --- WORKSPACE CONTROLLER ---
    Timer {
        interval: 3000
        running: true
        repeat: true
        property int currentWs: 0
        
        onTriggered: {
            currentWs = (currentWs + 1) % 3;
            workspaceStrip.x = -(currentWs * root.width);
            
            // Update bar
            barIndicator.x = (barIndicator.parent.width / 3) * currentWs
        }
    }
    
    // --- WAYBAR-STYLE STATUS ---
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 10
        width: 300
        height: 30
        color: "#11111b"
        radius: 15
        opacity: 0.9
        
        // Active Indicator
        Rectangle {
            id: barIndicator
            width: parent.width / 3
            height: parent.height
            color: "#313244"
            radius: 15
            Behavior on x { NumberAnimation { duration: Config.animDurationBackground; easing.type: Config.animEasingPanel } }
        }
        
        Row {
            anchors.fill: parent
            Item { width: 100; height: 30; Text { anchors.centerIn: parent; text: "1"; color: "white"; font.bold: true } }
            Item { width: 100; height: 30; Text { anchors.centerIn: parent; text: "2"; color: "white"; font.bold: true } }
            Item { width: 100; height: 30; Text { anchors.centerIn: parent; text: "3"; color: "white"; font.bold: true } }
        }
    }
}
