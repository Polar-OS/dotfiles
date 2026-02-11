import QtQuick
import Quickshell
import "../../config"

Item {
    id: root
    anchors.fill: parent
    
    // Properties to be set by children
    property string text: "TEXT"
    property var colors: [Config.accent, Config.red, Config.green, Config.yellow, Config.cyan, Config.orange]
    property int count: 12
    property real chaosLevel: 1.0

    // Background - Dark
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Grid effect (retro vibe)
    Repeater {
        model: Math.ceil(parent.width / 50)
        Rectangle {
            x: index * 50
            width: 1
            height: parent.height
            color: Config.foreground
            opacity: 0.05
        }
    }
    Repeater {
        model: Math.ceil(parent.height / 50)
        Rectangle {
            y: index * 50
            height: 1
            width: parent.width
            color: Config.foreground
            opacity: 0.05
        }
    }

    // Chaotic Texts
    Repeater {
        model: root.count
        
        Item {
            id: floater
            
            // Random start pos
            x: Math.random() * (root.width - 100)
            y: Math.random() * (root.height - 50)
            
            // Movement logic
            property real dx: (Math.random() - 0.5) * 10 * root.chaosLevel
            property real dy: (Math.random() - 0.5) * 10 * root.chaosLevel
            property color currentColor: root.colors[Math.floor(Math.random() * root.colors.length)]

            Timer {
                interval: 20 // 50fps
                running: true
                repeat: true
                onTriggered: {
                    // Move
                    floater.x += floater.dx
                    floater.y += floater.dy

                    // Bounce off walls
                    if (floater.x <= 0 || floater.x + label.width >= root.width) {
                        floater.dx *= -1
                        floater.x = Math.max(0, Math.min(floater.x, root.width - label.width))
                        // Randomize direction slightly on bounce
                        floater.dy += (Math.random() - 0.5) * 2
                    }
                    if (floater.y <= 0 || floater.y + label.height >= root.height) {
                        floater.dy *= -1
                        floater.y = Math.max(0, Math.min(floater.y, root.height - label.height))
                        floater.dx += (Math.random() - 0.5) * 2
                    }

                    // Chaos jitter
                    if (Math.random() > 0.95) {
                        floater.x += (Math.random() - 0.5) * 50 * root.chaosLevel
                        floater.y += (Math.random() - 0.5) * 50 * root.chaosLevel
                    }

                    // Color glitch
                    if (Math.random() > 0.98) {
                        floater.currentColor = root.colors[Math.floor(Math.random() * root.colors.length)]
                    }
                }
            }

            Text {
                id: label
                text: root.text
                font.family: Config.fontFamily
                font.pixelSize: 32 + (Math.random() * 32) // Varied sizes
                font.bold: true
                color: floater.currentColor
                style: Text.Outline
                styleColor: "black"
                
                // Jittering letters effect (individual letter movement is hard in QML Text, so we jitter the whole block mostly)
                // But we can shake the text block
                transform: [
                    Rotation { 
                        angle: (Math.random() - 0.5) * 20 * root.chaosLevel 
                    },
                    Scale {
                        xScale: 1.0 + (Math.random() - 0.5) * 0.2
                        yScale: 1.0 + (Math.random() - 0.5) * 0.2
                    }
                ]
            }
        }
    }

    // Occasional giant glitch overlay
    Text {
        anchors.centerIn: parent
        text: root.text
        font.family: Config.fontFamily
        font.pixelSize: 200
        font.bold: true
        color: Config.foreground
        opacity: 0
        visible: opacity > 0

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                if (Math.random() > 0.8) {
                    parent.opacity = 0.2
                    parent.text = root.text.split('').sort(function(){return 0.5-Math.random()}).join('') // Scramble
                    glitchOff.restart()
                }
            }
        }
        Timer {
            id: glitchOff
            interval: 100
            onTriggered: parent.opacity = 0
        }
    }
}
