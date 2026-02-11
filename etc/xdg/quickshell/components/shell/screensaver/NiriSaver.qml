import QtQuick
import Quickshell
import "../../config"

Item {
    anchors.fill: parent

    // --- 1. Background Grid (Niri Infinite Scroll representation) ---
    Item {
        anchors.fill: parent
        
        Repeater {
            model: 20 // Vertical lines
            Rectangle {
                x: (parent.width / 20) * index
                width: 1
                height: parent.height
                color: Config.dimmed
                opacity: 0.1
            }
        }
        
        Repeater {
            model: 20 // Horizontal lines
            Rectangle {
                y: (parent.height / 20) * index
                width: parent.width
                height: 1
                color: Config.dimmed
                opacity: 0.1
                
                // Scrolling effect
                NumberAnimation on y {
                    from: 0; to: parent.height
                    duration: Config.animDurationSaverSlow + (index * 100)
                    loops: Animation.Infinite
                    running: true
                }
            }
        }
    }

    // --- 2. The "Warp" Window Tunnel ---
    Item {
        id: tunnelCenter
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        
        Repeater {
            model: 16 // More windows
            id: tunnelRepeater

            Item {
                id: ring
                property real progress: (index / 16.0)
                
                // Faster animation
                NumberAnimation on progress {
                    from: 0; to: 1
                    duration: Config.animDurationSaverMedium + (index * 100) // Staggered start
                    loops: Animation.Infinite
                    running: true
                }
                
                // More aggressive scale
                scale: Math.pow(progress, 2.5) * 10
                opacity: progress * (1.0 - progress)
                rotation: progress * 360 // Full rotation
                
                z: progress * 100
                
                // Random jitter
                x: (tunnelRepeater.parent.width / 2) + (Math.random() - 0.5) * 50
                y: (tunnelRepeater.parent.height / 2) + (Math.random() - 0.5) * 50
                
                anchors.centerIn: parent
                
                // The "Window" Frame
                Rectangle {
                    width: 300; height: 200
                    anchors.centerIn: parent
                    color: "transparent"
                    border.color: index % 2 == 0 ? Config.accent : Config.foreground
                    border.width: 2
                    radius: Config.radius // Niri rounded corners
                    
                    // ASCII Window Decoration
                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 5
                        text: "╭─ niri-window-" + index + " ─╮"
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        color: parent.border.color
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Wait...\nLoading..."
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: parent.border.color
                        visible: scale > 0.5 // Detail only visible when close
                    }
                    
                    // Corner decorations
                    Text { anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 5; text: "╯"; font.family: Config.fontFamily; font.pixelSize: 14; color: parent.border.color }
                    Text { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 5; text: "╰"; font.family: Config.fontFamily; font.pixelSize: 14; color: parent.border.color }
                }
            }
        }
    }

    // --- 3. Center Piece: ASCII Niri Logo ---
    Item {
        anchors.centerIn: parent
        width: 400
        height: 200
        
        Text {
            id: niriLogo
            anchors.centerIn: parent
            text: "   _  __  _       _\n  / |/ / (_) ___ (_)\n /    / / / / _// /\n/_/|_/ /_/ /_/ /_/"
            font.family: Config.fontFamily
            font.pixelSize: 42
            font.bold: true
            color: Config.foreground
            style: Text.Outline
            styleColor: Config.accent
            horizontalAlignment: Text.AlignHCenter
            
            // Breathing animation (Faster)
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 1.2; duration: Config.animDurationSaverStep; easing.type: Config.animEasingPulse }
                NumberAnimation { to: 0.9; duration: Config.animDurationRegular; easing.type: Config.animEasingPulse } // Snappy
            }
            
            // Glitch effect on text (More frequent)
            Timer {
                interval: 80
                running: true
                repeat: true
                onTriggered: {
                    var glitchChars = "X#@%&";
                    if (Math.random() > 0.8) {
                        niriLogo.text = "   _  __  _       _\n  / |/ / (_) ___ (_)\n /    / / / / _// /\n/_/|_/ /_/ /_/ /_/" // Reset
                    } else if (Math.random() > 0.85) {
                             niriLogo.text = "   _  __  _       _\n  / |/ / [ " + glitchChars.charAt(Math.floor(Math.random() * glitchChars.length)) + " ] (_)\n /    / / / / _// /\n/_/|_/ /_/ /_/ /_/" // Glitch
                    } else {
                        // Random position shake
                        niriLogo.x = (parent.width - niriLogo.width) / 2 + (Math.random() - 0.5) * 10
                        niriLogo.y = (parent.height - niriLogo.height) / 2 + (Math.random() - 0.5) * 10
                    }
                }
            }
        }
        
        // Orbiting "Focus" Bracket (Faster)
        Rectangle {
            width: niriLogo.width + 60
            height: niriLogo.height + 60
            anchors.centerIn: parent
            color: "transparent"
            border.color: Config.accent
            border.width: 2
            radius: Config.radius
            
            opacity: 0.7
            
            RotationAnimator on rotation {
                from: 0; to: 360; duration: Config.animDurationSaverSlow; loops: Animation.Infinite; running: true
            }
        }
    }
    
    // --- 4. Foreground Rain (Subtle) ---
    Repeater {
        model: 20
        Text {
            x: Math.random() * parent.width
            y: Math.random() * parent.height
            text: String.fromCharCode(33 + Math.floor(Math.random() * 90))
            color: Config.dimmed
            font.family: Config.fontFamily
            font.pixelSize: 12
            opacity: 0.5
            
            NumberAnimation on y {
                from: -20; to: parent.height + 20
                duration: Config.animDurationSaverFast + Math.random() * 3000
                loops: Animation.Infinite
                running: true
            }
            
            Timer {
                interval: 200
                running: true
                repeat: true
                onTriggered: parent.text = String.fromCharCode(33 + Math.floor(Math.random() * 90))
            }
        }
    }
}
