import QtQuick
import Quickshell
import "../../config"

Item {
    anchors.fill: parent

    // --- Background: Falling Matrix/Data Stream ---
    Repeater {
        model: 15 // Number of columns
        Item {
            id: column
            width: 30
            height: parent.height
            x: Math.random() * parent.width
            opacity: 0.3 + Math.random() * 0.4
            
            property real speed: 2 + Math.random() * 5
            property string chars: "010101XYZAOB@#&%"
            
            Text {
                id: streamText
                text: "0\n1\n0\n1"
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: Config.dimmed
                lineHeight: 1.2
                y: -height
                
                Timer {
                    running: true
                    interval: 50
                    repeat: true
                    onTriggered: {
                        streamText.y += column.speed;
                        if (streamText.y > parent.height) {
                            streamText.y = -streamText.height;
                            column.x = Math.random() * parent.width;
                        }
                        
                        // Random character flip
                        if (Math.random() < 0.1) {
                            var lines = [];
                            for(var i=0; i<20; i++) {
                                lines.push(column.chars.charAt(Math.floor(Math.random() * column.chars.length)));
                            }
                            streamText.text = lines.join("\n");
                        }
                    }
                }
            }
        }
    }

    // --- Foreground: Glitchy POLAR Logo (Teleporting) ---
    Item {
        id: bouncer
        width: asciiText.paintedWidth
        height: asciiText.paintedHeight
        
        // Initial random position
        Component.onCompleted: {
            teleport();
        }
        
        function teleport() {
            bouncer.x = Math.random() * (parent.width - width);
            bouncer.y = Math.random() * (parent.height - height);
            
            // Trigger glitch visual
            triggerGlitch();
        }
        
        function triggerGlitch() {
            // Flash color
            var colors = [Config.accent, Config.red, Config.green, Config.foreground, Config.yellow];
            asciiText.color = colors[Math.floor(Math.random() * colors.length)];
            
            // Shake
            asciiText.x = (Math.random() - 0.5) * 20;
            asciiText.y = (Math.random() - 0.5) * 20;
            
            // Reset shake
            Qt.callLater(function() {
                asciiText.x = 0;
                asciiText.y = 0;
            });
        }
        
        // Teleport Timer (Random interval between 500ms and 2000ms)
        Timer {
            id: teleportTimer
            running: true
            repeat: true
            interval: 500 + Math.random() * 1500
            onTriggered: bouncer.teleport()
        }
        
        // Main Logo Text
        Text {
            id: asciiText
            text: parent.currentArt
            font.family: Config.fontFamily
            font.pixelSize: 24
            font.bold: true
            color: Config.accent
            lineHeight: 0.85
            style: Text.Outline
            styleColor: Qt.rgba(0,0,0,0.8)
        }
        
        // Glitch Ghost Effect (Red shift)
        Text {
            text: asciiText.text
            font: asciiText.font
            color: Config.red
            opacity: 0.5
            x: 2 + Math.random() * 4
            y: 0
            visible: Math.random() > 0.8
            lineHeight: 0.85
        }
        
        // Glitch Ghost Effect (Cyan shift)
        Text {
            text: asciiText.text
            font: asciiText.font
            color: Config.green
            opacity: 0.5
            x: -2 - Math.random() * 4
            y: 0
            visible: Math.random() > 0.8
            lineHeight: 0.85
        }

        property var frames: [
            // Frame 1: Standard Blocky
            "██████╗  ██████╗ ██╗      ██████╗ ██████╗ \n██╔══██╗██╔═══██╗██║     ██╔═══██╗██╔══██╗\n██████╔╝██║   ██║██║     ███████║██████╔╝\n██╔═══╝ ██║   ██║██║     ██╔═══██║██╔══██╗\n██║     ╚██████╔╝███████╗██║   ██║██║  ██║\n╚═╝      ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝  ╚═╝",
            
            // Frame 2: Distorted/Hollow
            " ____   ___   _      ____  ____ \n|    \\ /   \\ | |    /    ||    \\\n|  o  )     || |   |  o  ||  D  )\n|   _/|  O  || |___|     ||    / \n|  |  |     ||     |  _  ||    \\ \n|__|   \\___/ |_____|__|__||__|\\_\\",
            
            // Frame 3: Thin/Slashed
            " /__  /  /  /   /__  /__ \n/  / /  /  /   /  / /  /\n__/. __/. /__. __/. /__.",
            
            // Frame 4: Corrupted
            "▒█▀▀█ ▒█▀▀▀█ ▒█░░░ ▒█▀▀█ ▒█▀▀█ \n▒█▄▄█ ▒█░░▒█ ▒█░░░ ▒█▄▄█ ▒█▄▄▀ \n▒█░░░ ▒█▄▄▄█ ▒█▄▄█ ▒█░▒█ ▒█░▒█"
        ]
        
        property string currentArt: frames[0]
        
        // Random frame switching (less frequent than teleporting)
        Timer {
            interval: 150
            running: true
            repeat: true
            onTriggered: {
                // 20% chance to switch base font
                if (Math.random() < 0.2) {
                    bouncer.currentArt = bouncer.frames[Math.floor(Math.random() * bouncer.frames.length)];
                }
                
                // 40% chance to corrupt current text
                if (Math.random() < 0.4) {
                    var txt = bouncer.currentArt.split('');
                    var corruption = "#$@%&^*!~";
                    var numCorruptions = 1 + Math.floor(Math.random() * 3);
                    for(var i=0; i<numCorruptions; i++) {
                        var idx = Math.floor(Math.random() * txt.length);
                        if (txt[idx] !== '\n') {
                            txt[idx] = corruption.charAt(Math.floor(Math.random() * corruption.length));
                        }
                    }
                    bouncer.currentArt = txt.join('');
                }
                
                // Occasional random color shift
                if (Math.random() < 0.1) {
                    asciiText.color = Config.red;
                }
            }
        }
    }
}
