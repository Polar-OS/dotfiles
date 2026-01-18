import QtQuick 2.15
import "framework"
import "wrappers/base"

SimpleTest {
    name: "BaseComponents"
    
    // Force Config loading
    Component.onCompleted: {
        var _ = Config.buttonSize
    }

    QuickButton {
        id: btn
        size: 60
        icon: "T"
    }
    
    Panel {
        id: panel
        // Mock required properties if any
        anchors.left: parent.left
        anchors.top: parent.top
    }

    function test_quickbutton_defaults() {
        compare(btn.width, 60, "Width check")
        compare(btn.height, 60, "Height check")
        compare(btn.icon, "T", "Icon check")
    }
    
    function test_quickbutton_click() {
        var clicked = false
        function onClicked() { clicked = true }
        btn.clicked.connect(onClicked)
        
        mouseClick(btn)
        
        verify(clicked, "Button should emit clicked")
        btn.clicked.disconnect(onClicked)
    }

    function test_panel_load() {
        verify(panel.width > 0, "Panel loaded with width")
    }
}
