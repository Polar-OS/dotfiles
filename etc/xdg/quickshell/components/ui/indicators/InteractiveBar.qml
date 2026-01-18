import QtQuick
import QtQuick.Layouts
import "../../config"

Rectangle {
    id: root

    property real value: 0.0 // 0.0 to 1.0
    property int orientation: Qt.Vertical
    property bool interactive: true
    property bool showFill: true
    property color activeColor: Config.foreground
    property color inactiveColor: Qt.alpha(Config.foreground, 0.2)
    property real stepSize: 0.05
    
    // RENAMED signal to avoid conflict with auto-generated property change signal 'onValueChanged'
    signal userModified(real newValue)
    signal showRequested()

    implicitWidth: orientation === Qt.Vertical ? 12 : 100
    implicitHeight: orientation === Qt.Horizontal ? 12 : 100
    
    radius: Config.itemRadius
    color: inactiveColor

    // Focus support
    activeFocusOnTab: interactive
    border.width: activeFocus ? 2 : 0
    border.color: Config.accent
    
    Behavior on border.width {
        NumberAnimation { duration: Config.animDurationFast }
    }

    // Input handling logic
    function updateFromMouse(mouseX, mouseY) {
        if (!interactive) return;
        
        var newVal;
        if (orientation === Qt.Horizontal) {
            newVal = mouseX / width;
        } else {
            newVal = 1.0 - (mouseY / height);
        }
        root.userModified(Math.max(0.0, Math.min(1.0, newVal)));
    }
    
    function adjustValue(delta) {
        if (!interactive) return;
        root.userModified(Math.max(0.0, Math.min(1.0, root.value + delta)));
        root.showRequested();
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: interactive
        enabled: interactive
        cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: (mouse) => root.updateFromMouse(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            if (pressed) root.updateFromMouse(mouse.x, mouse.y)
        }
        onWheel: (wheel) => {
            if (!interactive) return;
            var step = root.stepSize;
            root.adjustValue(wheel.angleDelta.y > 0 ? step : -step);
        }
    }

    // Keyboard handlers
    Keys.onLeftPressed: if (orientation === Qt.Horizontal) adjustValue(-stepSize)
    Keys.onRightPressed: if (orientation === Qt.Horizontal) adjustValue(stepSize)
    Keys.onUpPressed: if (orientation === Qt.Vertical) adjustValue(stepSize)
    Keys.onDownPressed: if (orientation === Qt.Vertical) adjustValue(-stepSize)

    // Fill indicator
    Rectangle {
        visible: showFill
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        
        // Dynamic sizing based on orientation
        anchors.right: orientation === Qt.Vertical ? parent.right : undefined
        anchors.top: orientation === Qt.Horizontal ? parent.top : undefined
        
        height: orientation === Qt.Vertical ? parent.height * Math.min(root.value, 1.0) : undefined
        width: orientation === Qt.Horizontal ? parent.width * Math.min(root.value, 1.0) : undefined
        
        color: root.activeColor
        radius: parent.radius

        Behavior on height {
            enabled: orientation === Qt.Vertical
            NumberAnimation {
                duration: Config.animationDurationQuick
                easing.type: Config.animEasingStandard
            }
        }
        
        Behavior on width {
            enabled: orientation === Qt.Horizontal
            NumberAnimation {
                duration: Config.animationDurationQuick
                easing.type: Config.animEasingStandard
            }
        }
    }
}
