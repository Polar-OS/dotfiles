import QtQuick
import QtQuick.Effects
import "../../config" // Import components module (Config)
import ".."
import "."      // Import local types (InvertedCorner)

// Presentation Component: Handles visual styling, shadows, and content containment
Item {
    id: root

    // --- Configuration API ---
    property string position: "bottom"
    property bool floating: false
    property real radius: Config.radius
    property color backgroundColor: Config.background
    property color shadowColor: Config.shadow
    property real shadowBlur: 1.0
    property real contentWidth
    property real contentHeight
    property real contentPadding: 10
    property real animationOffset: 0
    
    // Base/Normal dimensions for corner animation calculation
    property real normalWidth: 0
    property real normalHeight: 0

    property int cornerSize: Config.panelCornerRadius  // Corner radius
    property int borderOffset: {
        // Fix: Adjust offset for right/bottom edges where screen border might render 1px smaller
        if (position === "right" || position === "bottom") {
            return Math.max(0, Config.screenBorderSize - 1);
        }
        return Config.screenBorderSize;
    }

    onBorderOffsetChanged: console.log("PanelStyle: borderOffset changed to", borderOffset)

    // Focus Management
    property bool wantsFocus: false
    property bool isHovered: false
    property bool revealed: false
    property bool extended: false

    signal focusLost
    signal contentFocusChanged(bool active)

    default property alias content: contentContainer.data

    // --- Visual Layout ---

    // Apply Slide Animation Transform here
    transform: Translate {
        y: (position === "bottom" || position === "top") ? animationOffset : 0
        x: (position === "left" || position === "right") ? animationOffset : 0
    }

    // Shadow Effect Layer
    // Moved to background Rectangle to prevent InvertedCorner from casting shadows

    // Animated Panel Border Radius synchronized with Panel Offset
    // Calculates progress from 0.0 (hidden) to 1.0 (fully revealed) based on animation offset
    // Multiplied by 4 so radius reaches full value at quarter of the animation time
    readonly property real _panelRevealProgress: {
        var size = (position === "left" || position === "right") ? width : height;
        if (size <= 0)
            return 0;
        var progress = 1.0 - (Math.abs(animationOffset) / size);
        return Math.max(0, Math.min(1.0, progress * 4));
    }

    property real currentPanelRadius: radius * _panelRevealProgress

    // Animated shadow color to hide it when panel is concealed
    property color _currentShadowColor: root.revealed ? root.shadowColor : "transparent"
    Behavior on _currentShadowColor {
        ColorAnimation {
            duration: Config.animDurationFast
        }
    }

    // Shadow Source Rectangle (Pull back from edges to avoid bleed on screen border)
    Rectangle {
        id: shadowSource
        z: -1
        color: root.backgroundColor

        anchors.fill: parent
        // Pull back the shadow caster from the screen edge
        anchors.bottomMargin: (!root.floating && root.position === "bottom") ? root.borderOffset : 0
        anchors.topMargin: (!root.floating && root.position === "top") ? root.borderOffset : 0
        anchors.leftMargin: (!root.floating && root.position === "left") ? root.borderOffset : 0
        anchors.rightMargin: (!root.floating && root.position === "right") ? root.borderOffset : 0

        // Match Background Radii
        topLeftRadius: background.topLeftRadius
        topRightRadius: background.topRightRadius
        bottomLeftRadius: background.bottomLeftRadius
        bottomRightRadius: background.bottomRightRadius

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root._currentShadowColor
            shadowBlur: root.shadowBlur
            shadowVerticalOffset: root.floating ? 0 : (root.position === "bottom" ? -6 : (root.position === "top" ? 6 : 0))
            shadowHorizontalOffset: root.floating ? 0 : (root.position === "right" ? -6 : (root.position === "left" ? 6 : 0))
            shadowScale: 1.0
        }
    }

    // Background Rectangle
    Rectangle {
        id: background
        anchors.fill: parent
        color: root.backgroundColor

        // Dynamic Corner Radii Logic
        property bool isBottom: position === "bottom"
        property bool isTop: position === "top"
        property bool isLeft: position === "left"
        property bool isRight: position === "right"

        topLeftRadius: (root.floating || isBottom || isRight) ? root.currentPanelRadius : 0
        topRightRadius: (root.floating || isBottom || isLeft) ? root.currentPanelRadius : 0
        bottomLeftRadius: (root.floating || isTop || isRight) ? root.currentPanelRadius : 0
        bottomRightRadius: (root.floating || isTop || isLeft) ? root.currentPanelRadius : 0

        // Filler Rectangle to cover bounce gaps
        Rectangle {
            visible: !root.floating
            color: root.backgroundColor

            // Extend outwards based on position
            anchors.top: parent.isBottom ? parent.bottom : undefined
            anchors.bottom: parent.isTop ? parent.top : undefined
            anchors.left: parent.isRight ? parent.right : (parent.isTop || parent.isBottom ? parent.left : undefined)
            anchors.right: parent.isLeft ? parent.left : (parent.isTop || parent.isBottom ? parent.right : undefined)

            // Height/Width sufficient to cover the bounce
            height: (parent.isTop || parent.isBottom) ? 200 : parent.height
            width: (parent.isLeft || parent.isRight) ? 200 : parent.width
        }
    }

    // Animated Corner Radius synchronized with Panel Offset
    // Uses normalWidth/normalHeight to ensure corners align with the main panel body.
    // Progress is squared (ease-in) to prevent corners appearing "too fast" or "instantly".
    readonly property real _revealProgress: {
        var size = (position === "left" || position === "right") 
            ? (normalWidth > 0 ? normalWidth : width)
            : (normalHeight > 0 ? normalHeight : height);
            
        if (size <= 0) return 0;
        var linear = Math.max(0, Math.min(1.0, 1.0 - (Math.abs(animationOffset) / size)));
        return linear * linear; // Squared for smoother start
    }
    
    property real currentCornerRadius: Config.panelCornerRadius * _revealProgress
    
    // Visibility threshold: hide when radius is negligible to prevent visual artifacts
    property bool cornersVisible: currentCornerRadius > 0.5

    // Helper for inverse transform to keep corners static during bounce
    readonly property var inverseTransform: Translate {
        y: (position === "bottom" || position === "top") ? -animationOffset : 0
        x: (position === "left" || position === "right") ? -animationOffset : 0
    }

    // Inverted corners at the edges where panel touches the screen border
    // Removed overlaps to preserve perfect curve tangency.
    
    // Bottom panel
    InvertedCorner {
        visible: !root.floating && position === "bottom" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 180
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.borderOffset
        anchors.right: parent.left
        transform: root.inverseTransform
    }
    InvertedCorner {
        visible: !root.floating && position === "bottom" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 270
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.borderOffset
        anchors.left: parent.right
        transform: root.inverseTransform
    }

    // Top panel
    InvertedCorner {
        visible: !root.floating && position === "top" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 90
        anchors.top: parent.top
        anchors.topMargin: root.borderOffset
        anchors.right: parent.left
        transform: root.inverseTransform
    }
    InvertedCorner {
        visible: !root.floating && position === "top" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 0
        anchors.top: parent.top
        anchors.topMargin: root.borderOffset
        anchors.left: parent.right
        transform: root.inverseTransform
    }

    // Left panel
    InvertedCorner {
        visible: !root.floating && position === "left" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 270
        anchors.left: parent.left
        anchors.leftMargin: root.borderOffset
        anchors.bottom: parent.top
        transform: root.inverseTransform
    }
    InvertedCorner {
        visible: !root.floating && position === "left" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 0
        anchors.left: parent.left
        anchors.leftMargin: root.borderOffset
        anchors.top: parent.bottom
        transform: root.inverseTransform
    }

    // Right panel
    InvertedCorner {
        visible: !root.floating && position === "right" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 180
        anchors.right: parent.right
        anchors.rightMargin: root.borderOffset
        anchors.bottom: parent.top
        transform: root.inverseTransform
    }
    InvertedCorner {
        visible: !root.floating && position === "right" && root.cornersVisible
        size: root.cornerSize
        curveRadius: root.currentCornerRadius
        cornerColor: root.backgroundColor
        cornerRotation: 90
        anchors.right: parent.right
        anchors.rightMargin: root.borderOffset
        anchors.top: parent.bottom
        transform: root.inverseTransform
    }

    // Content Container (Focus Scope)
    FocusScope {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.floating ? 0 : root.contentPadding

        onActiveFocusChanged: {
            root.contentFocusChanged(activeFocus);

            // Logic: Signal Focus Loss if it demanded focus
            // Never signal focus loss in extended mode - only Escape closes it
            if (!activeFocus) {
                if (root.wantsFocus && !root.isHovered && !root.extended) {
                    root.focusLost();
                }
            }
        }

        // Expose method to force focus
        function forceFocus() {
            forceActiveFocus();
        }
    }

    function forceContentFocus() {
        contentContainer.forceFocus();
    }
}
