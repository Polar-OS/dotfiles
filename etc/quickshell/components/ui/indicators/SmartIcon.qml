import QtQuick
import "../../config"

Item {
    id: root

    property string icon: ""
    property int pixelSize: 24
    property color color: Config.foreground
    
    // Derived properties
    readonly property bool isFontIcon: {
        if (root.icon.length === 0) return false;
        var cp = root.icon.codePointAt(0);
        // Nerd Fonts PUA ranges
        return (cp >= 0xE000 && cp <= 0xF8FF) || 
               (cp >= 0xF0000 && cp <= 0xFFFFD) || 
               (cp >= 0x100000 && cp <= 0x10FFFD);
    }

    implicitWidth: pixelSize
    implicitHeight: pixelSize

    // Helper to calculate a unique size offset based on theme string to bust cache
    function getThemeOffset() {
        var str = Config.iconTheme;
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        return (Math.abs(hash) % 3); 
    }

    Image {
        id: iconImage
        anchors.fill: parent
        
        source: {
            if (!root.isFontIcon && root.icon !== "") {
                if (root.icon.startsWith("/")) {
                    return "file://" + root.icon
                } else if (root.icon.startsWith("~")) {
                     return "file://" + Quickshell.env("HOME") + root.icon.substring(1)
                } else {
                    return "image://icon/" + root.icon
                }
            }
            return ""
        }
        visible: source !== ""
        asynchronous: true
        cache: false 
        sourceSize: Qt.size(root.pixelSize, root.pixelSize + getThemeOffset())
        fillMode: Image.PreserveAspectFit
    }

    Text {
        anchors.centerIn: parent
        text: root.isFontIcon ? root.icon : "✨"
        visible: root.icon === "" || root.isFontIcon
        font.pixelSize: root.pixelSize
        color: root.color
        font.family: Config.iconFontFamily
    }
}
