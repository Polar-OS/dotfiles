import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent
    
    // Background: Deep Cyberpunk Purple
    Rectangle {
        anchors.fill: parent
        color: "#1a0b1a" 
        
        // Hexagon Grid Pattern
        ShaderEffect {
            anchors.fill: parent
            property real time: 0
            NumberAnimation on time { from: 0; to: 100; duration: Config.animDurationSaverVerySlow; loops: Animation.Infinite }
            // Simple grid simulation via repeating gradient/rects for Qt6 safety without raw GLSL here
            // Fallback to QML primitives for visual safety
        }
    }
    
    // --- CYBERPUNK GRID ---
    Repeater {
        model: 20
        Rectangle {
            x: 0
            y: index * (root.height/20)
            width: root.width
            height: 1
            color: "#E95420"
            opacity: 0.2
        }
    }
    Repeater {
        model: 20
        Rectangle {
            x: index * (root.width/20)
            y: 0
            width: 1
            height: root.height
            color: "#77216F"
            opacity: 0.2
        }
    }

    // --- "SNAP" PACKAGES TRANSPORT ---
    // Floating cubes representing secure packages
    Repeater {
        model: 12
        Item {
            id: snapPod
            width: 120; height: 120
            x: Math.random() * root.width
            y: Math.random() * root.height
            
            // Movement
            NumberAnimation on y {
                from: root.height + 100
                to: -100
                duration: Config.animDurationSaverMedium + Math.random() * 4000
                loops: Animation.Infinite
                running: true
            }
            
            // Visuals: Neon Cube
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.91, 0.33, 0.12, 0.1) // Orange tint
                border.color: "#E95420"
                border.width: 2
                radius: 10
                
                // Inner core
                Rectangle {
                    width: 60; height: 60
                    anchors.centerIn: parent
                    color: "#77216F"
                    radius: 30
                    opacity: 0.8
                    
                    // Pulse
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.2; duration: Config.animDurationSaverStep }
                        NumberAnimation { to: 1.0; duration: Config.animDurationSaverStep }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "SNAP"
                    color: "white"
                    font.family: Config.fontFamily
                    font.bold: true
                }
            }
        }
    }

    // --- UBUNTU LOGO - CYBER VERSION ---
    Item {
        anchors.centerIn: parent
        width: 300; height: 300
        
        // Rotating circle of friends (Abstract)
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#E95420"
            border.width: 4
            radius: 150
            
            // Dashed effect simulated by mask or just rotate
            RotationAnimator on rotation {
                from: 0; to: 360
                duration: Config.animDurationSaverVerySlow // 8000 -> Very Slow
                loops: Animation.Infinite
            }
            
            // Three nodes
            Repeater {
                model: 3
                Rectangle {
                    width: 40; height: 40
                    radius: 20
                    color: "white"
                    x: 150 + 130 * Math.cos(index * 2 * Math.PI / 3) - 20
                    y: 150 + 130 * Math.sin(index * 2 * Math.PI / 3) - 20
                    
                    // Glow
                    layer.enabled: true
                }
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: "UBUNTU\n24.04"
            horizontalAlignment: Text.AlignHCenter
            color: "#E95420"
            font.family: Config.fontFamily
            font.pixelSize: 40
            font.bold: true
            style: Text.Outline
            styleColor: "#77216F"
            
            // Glitch text occasionally
            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: {
                    parent.opacity = 0.5
                    glitchTimer.restart()
                }
            }
            Timer { id: glitchTimer; interval: 50; onTriggered: parent.opacity = 1.0 }
        }
    }

    // --- DATA STREAM ---
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        text: "CONNECTING TO SNAP STORE... [SECURE]"
        color: "#77216F"
        font.family: Config.fontFamily
        font.pixelSize: 18
        
        Timer {
            interval: 500
            running: true
            repeat: true
            onTriggered: {
                parent.visible = !parent.visible
            }
        }
    }
}
