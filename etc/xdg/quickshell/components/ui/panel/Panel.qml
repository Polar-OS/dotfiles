import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import ".."
import "."

// Functional Component: Handles logic, animations, focus, and structure.
// Delegates visual rendering to PanelStyle.
PanelWindow {
    id: root

    // --- Configuration API ---
    property string position: "bottom" // "top", "bottom", "left", "right"
    property real contentHeight: screen.height / 3
    property real contentWidth: screen.width / 3
    property real extendedContentHeight: contentHeight
    property real extendedContentWidth: contentWidth
    property real floatingContentHeight: screen.height / 3
    property real floatingWidth: screen.width / 3
    property real shadowSpace: 20
    property real contentPadding: Config.padding
    property real radius: Config.radius
    property color backgroundColor: Config.background
    property color shadowColor: Config.shadow
    property real shadowBlur: 1.0
    property bool wantsFocus: false
    property bool hasExtendedMode: false
    property bool preventAutoHide: false
    property bool preventEdgeReveal: false
    property int edgeRevealDelay: Config.panelEdgeRevealDelay

    // Control if content size changes should be animated (smooth) or immediate (sync with content)
    property bool animateContentResizing: true

    // --- Signals ---
    signal focusLost

    // --- State ---
    property bool revealed: false
    property bool extended: false
    property bool floating: false
    property bool isHovered: (triggerArea.triggerHovered && !root.preventEdgeReveal) || (root.revealed && fullHover.hovered)
    property bool _wasExtended: false
    property bool _ipcActivated: false  // Track if revealed via IPC toggle

    // --- Computed Layout Properties ---
    // Use delayed target values to prevent flicker during extended mode transitions
    property real targetContentHeight: _delayedTargetHeight
    property real targetContentWidth: _delayedTargetWidth
    property real targetBottomMargin: floating ? ((screen.height - (targetContentHeight + shadowSpace * 2)) / 2) : 0
    property real targetTopMargin: floating ? ((screen.height - (targetContentHeight + shadowSpace * 2)) / 2) : 0
    property real targetLeftMargin: floating ? ((screen.width - (targetContentWidth + shadowSpace * 2)) / 2) : 0
    property real targetRightMargin: floating ? ((screen.width - (targetContentWidth + shadowSpace * 2)) / 2) : 0

    // --- Animated Layout Properties ---
    property real currentContentHeight: targetContentHeight
    property real currentContentWidth: targetContentWidth
    property real currentBottomMargin: targetBottomMargin
    property real currentTopMargin: targetTopMargin
    property real currentLeftMargin: targetLeftMargin
    property real currentRightMargin: targetRightMargin

    // Track if we're transitioning between modes (for animation control)
    property bool _isTransitioningMode: false
    
    // Progress of extended mode size animation (0.0 to 1.0)
    // Used to synchronize content opacity with panel expansion/contraction
    readonly property real extendedProgress: {
        var targetW = extendedContentWidth;
        var startW = contentWidth;
        var deltaW = targetW - startW;
        if (Math.abs(deltaW) < 1) return extended ? 1 : 0;
        var progress = (currentContentWidth - startW) / deltaW;
        return Math.max(0, Math.min(1, progress));
    }

    // Pre-extend overlay: activates overlay BEFORE the content animation starts
    // This prevents the flicker caused by window resize racing with content animation
    property bool _preExtendOverlay: false

    // Delayed target values - only update after overlay is stable
    property real _delayedTargetWidth: contentWidth
    property real _delayedTargetHeight: contentHeight
    
    onExtendedChanged: {
        _isTransitioningMode = true;
        _modeTransitionTimer.restart();

        if (extended) {
            // First, activate overlay immediately (window goes fullscreen)
            _preExtendOverlay = true;
            // Then, after one frame, start the content animation
            _extendAnimationDelayTimer.start();
            visuals.forceContentFocus();
            // Stop hide timer when extended to prevent accidental closing
            hideTimer.stop();
        } else {
            // When closing extended mode, animate content immediately
            // Overlay stays active via _isTransitioningMode
            _preExtendOverlay = false;
            _delayedTargetWidth = floating ? floatingWidth : contentWidth;
            _delayedTargetHeight = floating ? floatingContentHeight : contentHeight;
            // Restart timer if we're back to normal mode and not hovering
            if (!root.isHovered && revealed) {
                hideTimer.start();
            }
        }
    }

    Timer {
        id: _extendAnimationDelayTimer
        interval: 16 // One frame delay to let overlay stabilize
        onTriggered: {
            // Now update the target dimensions to trigger the animation
            root._delayedTargetWidth = root.extendedContentWidth;
            root._delayedTargetHeight = root.extendedContentHeight;
        }
    }
    
    Timer {
        id: _modeTransitionTimer
        interval: Config.animationDurationLong
        onTriggered: {
            root._isTransitioningMode = false;
            root._preExtendOverlay = false;
        }
    }

    // Keep delayed values in sync when not transitioning to extended mode
    onFloatingChanged: {
        if (!extended) {
            _delayedTargetWidth = floating ? floatingWidth : contentWidth;
            _delayedTargetHeight = floating ? floatingContentHeight : contentHeight;
        }
    }

    onExtendedContentWidthChanged: {
        if (extended) {
            _delayedTargetWidth = extendedContentWidth;
        }
    }

    onExtendedContentHeightChanged: {
        if (extended) {
            _delayedTargetHeight = extendedContentHeight;
        }
    }

    onContentWidthChanged: {
        if (!extended && !floating) {
            _delayedTargetWidth = contentWidth;
        }
    }

    onContentHeightChanged: {
        if (!extended && !floating) {
            _delayedTargetHeight = contentHeight;
        }
    }

    onFloatingWidthChanged: {
        if (!extended && floating) {
            _delayedTargetWidth = floatingWidth;
        }
    }

    onFloatingContentHeightChanged: {
        if (!extended && floating) {
            _delayedTargetHeight = floatingContentHeight;
        }
    }

    // Animation Configurations
    // Always animate height to ensure smooth transitions when content changes dynamically
    Behavior on currentContentHeight {
        enabled: root.animateContentResizing || root._isTransitioningMode
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }
    Behavior on currentContentWidth {
        enabled: root.animateContentResizing || root._isTransitioningMode
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }
    Behavior on currentBottomMargin {
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }
    Behavior on currentTopMargin {
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }
    Behavior on currentLeftMargin {
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }
    Behavior on currentRightMargin {
        NumberAnimation {
            duration: Config.animationDurationLong
            easing.type: Config.animEasingStandard
        }
    }

    // --- Window Configuration ---
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (revealed && (wantsFocus || extended)) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Input mask: only the panel content area is clickable in non-overlay mode
    // In overlay mode (extended/floating/wantsFocus), we need the full window clickable
    // for the light-dismiss MouseArea to work
    // MODIFIED: Only block full screen when extended or transitioning to extended.
    // In normal revealed mode, we want click-through behavior.
    mask: (extended || _preExtendOverlay || _isTransitioningMode) ? null : contentMask

    Region {
        id: contentMask
        item: inputMaskItem
    }

    // Input mask covering both content and trigger area to ensure hover events work
    Item {
        id: inputMaskItem
        
        readonly property real contentX: visuals.x + ((position === "left" || position === "right") ? animator.offset : 0)
        readonly property real contentY: visuals.y + ((position === "bottom" || position === "top") ? animator.offset : 0)
        
        x: Math.min(contentX, triggerArea.x)
        y: Math.min(contentY, triggerArea.y)
        width: Math.max(contentX + visuals.width, triggerArea.x + triggerArea.width) - x
        height: Math.max(contentY + visuals.height, triggerArea.y + triggerArea.height) - y
    }

    // Implicit Dimensions (including shadow space)
    // isAnimating uses a small threshold to detect when animation is complete
    property bool isAnimating: revealed ? (Math.abs(animator.offset) > 1.0) : (Math.abs(animator.offset - hiddenOffset) > 1.0)
    property bool isSizeAnimating: Math.abs(currentContentWidth - targetContentWidth) > 1.0 || Math.abs(currentContentHeight - targetContentHeight) > 1.0
    
    // Delayed overlay release - prevents flicker when animation ends
    property bool _animationOverlayActive: false
    onIsAnimatingChanged: {
        // Handle overlay release with delay
        if (isAnimating) {
            _animationOverlayActive = true;
            _animationOverlayTimer.stop();
        } else {
            // Delay releasing overlay to let the compositor stabilize
            _animationOverlayTimer.restart();
            // Reset extended state when animation finishes while hidden
            if (!revealed) {
                extended = false;
                _wasExtended = false;
            }
        }
    }
    Timer {
        id: _animationOverlayTimer
        interval: 50 // Short delay after animation ends
        onTriggered: root._animationOverlayActive = false
    }
    
    // Track content size changes to use overlay during transitions (only when revealed)
    property bool _contentSizeChanging: false
    onTargetContentHeightChanged: {
        if (revealed) {
            _contentSizeChanging = true;
            _contentSizeTimer.restart();
        }
    }
    onTargetContentWidthChanged: {
        if (revealed) {
            _contentSizeChanging = true;
            _contentSizeTimer.restart();
        }
    }
    Timer {
        id: _contentSizeTimer
        interval: 550 // Slightly longer than animation duration (500ms)
        onTriggered: root._contentSizeChanging = false
    }
    
    // Use overlay mode when:
    // - Panel is in extended mode (full overlay for extended content)
    // - Panel is transitioning to/from extended mode (prevents resize flicker)
    // - Content size is changing while revealed (prevents compositor resize during content changes)
    // - WantsFocus AND (revealed OR animating) - keeps overlay during hide animation to prevent flicker
    // - Panel is revealed (keeps window stable to prevent any resize flicker)
    // - _animationOverlayActive: Active during animation + short delay after to prevent end-of-animation flicker
    property bool useOverlay: (extended || _preExtendOverlay || _isTransitioningMode || _contentSizeChanging || revealed || _animationOverlayActive || (wantsFocus && isAnimating))

    // Logic to prevent window resize bouncing:
    // Always use full screen dimensions for the window on the relevant axis.
    // This eliminates window geometry changes during animations/transitions,
    // relying on PanelStyle to position the content and masks to handle input pass-through.
    property real displayedContentHeight: Math.max(currentContentHeight, targetContentHeight)
    property real displayedContentWidth: Math.max(currentContentWidth, targetContentWidth)

    // Island logic is now purely visual (handled by PanelStyle)
    property bool isIsland: !extended && !_preExtendOverlay && !_isTransitioningMode

    // STABILIZATION CHANGE: 
    // Top/Bottom panels: Always full width.
    // Left/Right panels: Always full height.
    // This ensures the Wayland surface never moves or resizes its anchor points.
    
    implicitHeight: (position === "left" || position === "right")
        ? screen.height
        : (useOverlay ? screen.height : displayedContentHeight + shadowSpace)

    implicitWidth: (position === "top" || position === "bottom") 
        ? screen.width
        : (useOverlay ? screen.width : displayedContentWidth + shadowSpace)

    function toggle() {
        if (!revealed) {
            revealed = true;
            extended = false;
            _wasExtended = false;
        } else {
            if (extended) {
                extended = false;
                _wasExtended = true;
            } else {
                if (hasExtendedMode && !_wasExtended) {
                    extended = true;
                } else {
                    revealed = false;
                    _wasExtended = false;
                }
            }
        }
    }

    // Anchors & Margins
    // Always anchor to all relevant edges.
    // Since we use full screen dimensions for the major axis, we don't need centering margins.
    anchors.bottom: position === "bottom" || position === "left" || position === "right"
    anchors.top: position === "top" || position === "left" || position === "right"
    anchors.left: position === "left" || position === "top" || position === "bottom"
    anchors.right: position === "right" || position === "top" || position === "bottom"
    
    margins.bottom: currentBottomMargin
    margins.top: currentTopMargin
    margins.left: currentLeftMargin
    margins.right: currentRightMargin

    // --- Content Alias ---
    // Expose the visual component's content alias
    default property alias content: visuals.content

    // Expose panel window reference for child components (e.g., SystemTray menus)
    readonly property var panelWindow: root

    // --- Logic: Auto-Hide Timer ---
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: if (!root.isHovered && !root.preventAutoHide && !root.extended && !root._ipcActivated)
            root.revealed = false
    }

    Timer {
        id: revealTimer
        interval: root.edgeRevealDelay
        onTriggered: if (root.isHovered)
            root.revealed = true
    }

    onIsHoveredChanged: {
        if (isHovered) {
            hideTimer.stop();
            if (!root.revealed) {
                revealTimer.start();
            }
        } else {
            revealTimer.stop();
            // Don't start hide timer in extended mode
            if (!root.extended) {
                hideTimer.start();
            }
        }
    }

    // --- Logic: Focus Management ---
    onRevealedChanged: {
        if (revealed && (wantsFocus || extended)) {
            visuals.forceContentFocus();
        } else if (!revealed) {
            // Capture the current offset when we start hiding to prevent mid-animation offset changes
            _capturedHiddenOffset = _rawHiddenOffset;
        }
    }

    // --- Logic: Animation State ---
    // Calculate the raw hidden offset based on current displayed size
    property real _rawHiddenOffset: position === "bottom" ? displayedContentHeight : (position === "top" ? -displayedContentHeight : (position === "right" ? displayedContentWidth : -displayedContentWidth))
    
    // Always use the live raw offset to ensure the panel stays attached to the edge 
    // even if it changes size while animating.
    property real hiddenOffset: _rawHiddenOffset
    property real _capturedHiddenOffset: 0 // Unused but kept to minimize diff churn if needed later

    Item {
        id: animator
        property real offset: root.revealed ? 0 : root.hiddenOffset
        Behavior on offset {
            NumberAnimation {
                duration: Config.animationDurationLong // Reveal duration
                // Use custom curve if available, otherwise use resolved easing type
                easing.type: Config.animCurvePanel ? Easing.Bezier : Config.animEasingPanel
                // Safety net: If type is Bezier but no specific curve set, default to global Polar curve
                easing.bezierCurve: (Config.animCurvePanel && Config.animCurvePanel.length > 0) ? Config.animCurvePanel : (Config.animEasingPanel === Easing.Bezier ? Config.polarCurve : [])
            }
        }
    }

    // --- Interaction Handlers ---

    // Light Dismiss for Overlay Mode (including extended mode)
    // Only captures clicks OUTSIDE the visual panel area
    MouseArea {
        id: dismissArea
        enabled: root.useOverlay && root.revealed
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        
        // Check if click is outside the visual panel
        onClicked: mouse => {
            // Get the panel bounds in window coordinates
            var panelLeft = visuals.x;
            var panelRight = visuals.x + visuals.width;
            var panelTop = visuals.y;
            var panelBottom = visuals.y + visuals.height;
            
            // Only dismiss if click is outside the panel
            if (mouse.x < panelLeft || mouse.x > panelRight ||
                mouse.y < panelTop || mouse.y > panelBottom) {
                root.extended = false;
                if (!root.preventAutoHide) {
                    root.revealed = false;
                }
            } else {
                // Click is inside the panel, let it propagate
                mouse.accepted = false;
            }
        }
    }

    // Edge Trigger
    Item {
        id: triggerArea
        property bool triggerHovered: triggerHover.hovered
        property int triggerSize: 5 + Config.screenBorderSize
        
        // Limit trigger to content dimensions
        width: (position === "bottom" || position === "top") ? visuals.width : triggerSize
        height: (position === "left" || position === "right") ? visuals.height : triggerSize
        
        // Center/Position trigger to match content
        x: (position === "bottom" || position === "top") ? visuals.x : 
           (position === "right" ? parent.width - width : 0)
        y: (position === "left" || position === "right") ? visuals.y : 
           (position === "bottom" ? parent.height - height : 0)

        HoverHandler {
            id: triggerHover
        }
    }

    // Full Content Hover
    HoverHandler {
        id: fullHover
    }

    // --- Visual Presentation Component ---
    PanelStyle {
        id: visuals

        // Layout Bindings
        width: root.currentContentWidth
        height: root.currentContentHeight

        // Positioning Logic - Use x/y positioning for right/left panels to prevent
        // jumps when window resizes during overlay transitions.
        // For right panel: position from right edge of screen (always stable)
        // For left panel: position from left edge (x=0)
        // For top/bottom: use anchors since window width is always screen.width
        x: (position === "right") ? (parent.width - width) : 
           (position === "left") ? 0 : 
           (parent.width - width) / 2  // horizontalCenter for top/bottom
        
        y: (position === "bottom") ? (parent.height - height) :
           (position === "top") ? 0 :
           (parent.height - height) / 2  // verticalCenter for left/right

        // Property Bindings
        position: root.position
        floating: root.floating
        radius: root.radius
        backgroundColor: root.backgroundColor
        shadowColor: root.shadowColor
        shadowBlur: root.shadowBlur
        contentWidth: root.currentContentWidth
        contentHeight: root.currentContentHeight
        contentPadding: root.contentPadding
        animationOffset: animator.offset
        
        // Pass normal dimensions for correct corner animation
        normalWidth: root.contentWidth
        normalHeight: root.contentHeight

        // State & Focus Bindings
        wantsFocus: root.wantsFocus
        isHovered: root.isHovered
        revealed: root.revealed
        extended: root.extended

        // Event Connections
        onFocusLost: {
            // Only close on focus loss if wantsFocus is set (not in extended mode)
            // Extended mode should only close via Escape key
            // Also respect preventAutoHide
            if (root.wantsFocus && !root.extended && !root.preventAutoHide) {
                root.revealed = false;
            }
            root.focusLost();
        }

        Keys.onEscapePressed: {
            // Extended mode closes only via Escape
            // But respect preventAutoHide - only close extended, keep revealed
            if (root.extended) {
                root.extended = false;
                if (!root.preventAutoHide) {
                    root.revealed = false;
                }
            }
        }
    }
}
