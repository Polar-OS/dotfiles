import QtQuick
import Quickshell
import "../../config"

Item {
    anchors.fill: parent

    // --- Background: Neural Network / Constellation ---
    Repeater {
        model: 50
        Rectangle {
            id: node
            width: 4
            height: 4
            radius: 2
            color: Config.accent // Fedora Blue
            x: Math.random() * parent.width
            y: Math.random() * parent.height
            opacity: 0.2 + Math.random() * 0.8
            
            property real vx: (Math.random() - 0.5) * 4
            property real vy: (Math.random() - 0.5) * 4
            
            Timer {
                interval: 16
                running: true
                repeat: true
                onTriggered: {
                    node.x += node.vx
                    node.y += node.vy
                    
                    // Bounce
                    if (node.x < 0 || node.x > parent.width) node.vx *= -1
                    if (node.y < 0 || node.y > parent.height) node.vy *= -1
                    
                    // Random acceleration
                    if (Math.random() < 0.05) {
                        node.vx += (Math.random() - 0.5)
                        node.vy += (Math.random() - 0.5)
                    }
                }
            }
        }
    }

    // --- Foreground: Floating Fedora Logos ---
    Repeater {
        model: 5
        Item {
            id: floater
            x: Math.random() * parent.width
            y: Math.random() * parent.height
            width: 200
            height: 200
            scale: 0.5 + Math.random() * 1.5
            opacity: 0.8
            
            property real rotSpeed: (Math.random() - 0.5) * 50
            
            Text {
                anchors.centerIn: parent
                // Simplified "f" logo block
                text: "      ▄▄▄▄▄▄\n   ▄▀▀      ▀▀▄\n ▄▀            ▀▄\n▐▌    ▄▄▄▄▄▄    ▐▌\n▐▌    ▀▀▀▀▀▀    ▐▌\n ▀▄            ▄▀\n   ▀▄▄      ▄▄▀\n      ▀▀▀▀▀▀"
                font.family: Config.fontFamily
                font.pixelSize: 20
                color: Math.random() > 0.5 ? Config.accent : Config.foreground
                style: Text.Outline
                styleColor: Config.accent
                lineHeight: 0.8
            }
            
            NumberAnimation on rotation {
                from: 0; to: 360 * (Math.random() > 0.5 ? 1 : -1)
                duration: Config.animDurationSaverVerySlow + Math.random() * 10000
                loops: Animation.Infinite
                running: true
            }
            
            NumberAnimation on x {
                from: x; to: Math.random() * parent.width
                duration: Config.animDurationSaverSlow + Math.random() * 5000
                loops: Animation.Infinite
                easing.type: Config.animEasingSoft
                running: true
            }
            
            NumberAnimation on y {
                from: y; to: Math.random() * parent.height
                duration: Config.animDurationSaverSlow + Math.random() * 5000
                loops: Animation.Infinite
                easing.type: Config.animEasingSoft
                running: true
            }
        }
    }
    
    // --- Center: Giant Glitchy Text ---
    Text {
        anchors.centerIn: parent
        text: "FEDORA"
        font.family: Config.fontFamily
        font.pixelSize: 100
        font.bold: true
        color: "transparent"
        style: Text.Outline
        styleColor: Config.accent
        opacity: 0.3
        
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: 1.5; duration: Config.animDurationSaverFast; easing.type: Config.animEasingPulse }
            NumberAnimation { to: 1.0; duration: Config.animDurationFast } // Snap back
        }
        
        Timer {
            interval: 50
            running: true
            repeat: true
            onTriggered: {
                parent.text = Math.random() > 0.8 ? "F3D0R4" : "FEDORA"
                parent.x = (parent.parent.width - parent.width)/2 + (Math.random() - 0.5) * 20
            }
        }
    }
}
