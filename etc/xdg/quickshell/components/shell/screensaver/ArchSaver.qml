import QtQuick
import "../../config"

Item {
    id: root
    anchors.fill: parent
    
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a" // Arch Dark
    }

    // --- THE AUR BUILDER ---
    // A stack of "OK" messages building up to form the logo shape?
    // No, let's do a scrolling list of "Compiling..." that reveals the logo behind it via opacity mask simulation.
    // Actually, simpler: Stacks of "Packages" falling down and piling up.
    
    // Let's do the "Rolling Release" infinite road.
    
    // 3D Perspective Plane effect (Fake)
    Item {
        id: plane
        width: root.width * 2
        height: root.height
        x: -root.width / 2
        transform: [
            Rotation { origin.x: plane.width/2; origin.y: plane.height; axis { x: 1; y: 0; z: 0 } angle: 60 }
        ]
        
        Column {
            anchors.centerIn: parent
            spacing: 50
            
            Repeater {
                model: 20
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "pacman -Syu // upgrading system... " + index
                    color: "#1793d1"
                    font.family: Config.fontFamily
                    font.pixelSize: 32
                    font.bold: true
                    opacity: (index / 20)
                    
                    NumberAnimation on y {
                        from: 0; to: 1000
                        duration: Config.animDurationSaverFast
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }
    
    // --- THE GLITCH LOGO ---
    Item {
        anchors.centerIn: parent
        width: 400; height: 400
        
        // Blue Triangle
        Image {
            id: archLogo
            source: "../../assets/arch.svg" // Assuming asset exists, if not use shape
            // Fallback shape
            sourceSize.width: 400
            sourceSize.height: 400
            visible: false
        }
        
        // Canvas fallback if image missing
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.fillStyle = "#1793d1";
                ctx.beginPath();
                ctx.moveTo(width/2, 0);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fill();
            }
            
            // Glitch Mask
            layer.enabled: true
            
            // "I USE ARCH" Text overlaying
            Text {
                anchors.centerIn: parent
                text: "ARCH"
                color: "black"
                font.bold: true
                font.pixelSize: 40
                rotation: -10
            }
        }
        
        // Random "BTW" Popups
        Repeater {
            model: 10
            Text {
                x: Math.random() * 400
                y: Math.random() * 400
                text: "BTW"
                color: "white"
                font.pixelSize: 12
                visible: Math.random() > 0.8
                
                Timer {
                    interval: 100
                    running: true
                    repeat: true
                    onTriggered: parent.visible = Math.random() > 0.8
                }
            }
        }
    }
    
    // --- LOADING BAR (Never ends) ---
    Rectangle {
        width: 600
        height: 20
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 100
        color: "#333333"
        
        Rectangle {
            height: parent.height
            width: parent.width * 0.99
            color: "#1793d1"
            
            // Progress animation reset
            NumberAnimation on width {
                from: 0; to: parent.width * 0.99
                duration: Config.animDurationSaverVerySlow
                loops: Animation.Infinite
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: "Compiling shaders (99%)..."
            color: "white"
            font.family: Config.fontFamily
        }
    }
}
