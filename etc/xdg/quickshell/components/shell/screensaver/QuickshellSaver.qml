import QtQuick
import Quickshell
import "../../config"

Item {
    anchors.fill: parent

    // --- Background: Code Rain ---
    Repeater {
        model: 15 // More columns
        Text {
            id: rainDrop
            x: (parent.width / 15) * index
            y: -height
            width: parent.width / 15
            
            property real speed: 2 + Math.random() * 6 // Faster
            property real driftX: 0
            
            text: generateCode()
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Qt.rgba(0, 1, 0, 0.3)
            
            function generateCode() {
                var snippets = [
                    "Item { anchors.fill: parent }",
                    "Rectangle { color: 'red' }",
                    "MouseArea { onClicked: quit() }",
                    "import QtQuick",
                    "property int x: 10",
                    "console.log('Hello')"
                ];
                return snippets[Math.floor(Math.random() * snippets.length)];
            }

            NumberAnimation on y {
                from: -100; to: parent.height + 100
                duration: Config.animDurationSaverFast + Math.random() * 3000 // Faster
                loops: Animation.Infinite
                running: true
            }
            
            // Horizontal drift
            NumberAnimation on x {
                to: x + (Math.random() - 0.5) * 50
                duration: Config.animDurationSaverStep
                loops: Animation.Infinite
                running: true
            }
            
             // Random code regeneration
            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: parent.text = parent.generateCode()
            }
        }
    }

    // --- Center: Quickshell Logo / QML Logo ---
    Item {
        anchors.centerIn: parent
        width: 400
        height: 200

        Text {
            id: qsText
            anchors.centerIn: parent
            text: " ___  __  __  _\n/ _ \\|  \\/  || |\n| (_) | |\\/| || |__\n\\__\\_\\_|  |_||____|" // "QML" ascii art
            font.family: Config.fontFamily
            font.pixelSize: 40
            font.bold: true
            color: Config.green // Qt Green
            style: Text.Outline
            styleColor: "white"
            
            SequentialAnimation on color {
                loops: Animation.Infinite
                ColorAnimation { to: Config.green; duration: Config.animDurationSaverStep } // Green
                ColorAnimation { to: Config.foreground; duration: Config.animDurationSaverStep } // White
            }
        }
        
        Text {
            anchors.top: qsText.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: "<Quickshell />"
            font.family: Config.fontFamily
            font.pixelSize: 20
            color: Config.dimmed
            opacity: 0.8
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: Config.animationDurationSlow }
                NumberAnimation { to: 0.8; duration: Config.animationDurationSlow }
            }
        }
    }
}
