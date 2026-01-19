import QtQuick
import "../config"
import "."

// Standardized Animation Component
// Usage: PolarAnimation { target: item; property: "opacity"; to: 1.0 }
NumberAnimation {
    id: root
    
    // Default to "Polar" style
    duration: Config.animationDurationMedium
    easing.type: Config.animEasingPolar
    easing.bezierCurve: Config.polarCurve
    
    // Allow overriding with standard easing if needed
    property bool useStandardEasing: false
    
    Component.onCompleted: {
        if (useStandardEasing) {
            easing.type = Config.animEasingStandard
            easing.bezierCurve = []
        }
    }
}
