import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent
    
    Rectangle {
        anchors.fill: parent
        color: "#1a0005" // Very dark red
    }

    // --- THE SPIRAL OF STABILITY (RESTORED) ---
    Item {
        anchors.centerIn: parent
        width: root.width
        height: root.height

        Repeater {
            model: 40
            Rectangle {
                id: segment
                width: 30; height: 30
                color: "transparent"
                border.color: "#d70a53" // Debian Red
                border.width: 3
                
                // Polar coordinates logic
                property real angle: (index * 0.5) + t
                property real radius: (index * 15)
                property real t: 0

                x: (parent.width/2) + Math.cos(angle) * radius
                y: (parent.height/2) + Math.sin(angle) * radius
                
                Timer {
                    interval: 16
                    running: true
                    repeat: true
                    onTriggered: {
                        segment.t += 0.05
                        // Chaos: radius glitch
                        if (Math.random() > 0.98) {
                            segment.radius += (Math.random()-0.5) * 100
                        } else {
                            // Return to spiral
                            var targetR = index * 15
                            segment.radius = segment.radius * 0.9 + targetR * 0.1
                        }
                    }
                }
            }
        }
    }

    // --- "STABLE" TEXT DEGRADING (Safe Version) ---
    Text {
        id: stableTxt
        anchors.centerIn: parent
        text: "STABLE"
        font.family: Config.fontFamily
        font.pixelSize: 100
        font.bold: true
        color: "white"
        style: Text.Outline
        styleColor: "#d70a53"
        
        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                var states = ["STABLE", "TESTING", "STABLE", "SID", "STABLE"];
                // Randomly pick state
                var idx = Math.floor(Math.random() * states.length);
                stableTxt.text = states[idx];
                
                if (stableTxt.text === "SID") {
                    stableTxt.color = "red";
                    stableTxt.font.pixelSize = 110;
                } else if (stableTxt.text === "TESTING") {
                    stableTxt.color = "yellow";
                    stableTxt.font.pixelSize = 105;
                } else {
                    stableTxt.color = "white";
                    stableTxt.font.pixelSize = 100;
                }
            }
        }
    }

    // --- APT GET OUTPUT SCROLLING ---
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 5
        
        Repeater {
            model: 10
            Text {
                text: "Get: " + (index+1) + " http://deb.debian.org/debian stable/main amd64 Packages"
                color: "#d70a53"
                font.family: Config.fontFamily
                opacity: 0.6
                
                Timer {
                    interval: 100 + (index * 50)
                    running: true
                    repeat: true
                    onTriggered: {
                        if (Math.random() > 0.8) parent.visible = !parent.visible
                    }
                }
            }
        }
    }
}
