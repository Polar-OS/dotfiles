import QtQuick
import QtQuick.Layouts
import "../button"
import "../../config"

FocusScope {
    id: root

    // Public properties
    property alias icon: statusBtn.icon
    property alias iconPixelSize: statusBtn.iconPixelSize
    property alias fillPercentage: statusBtn.fillPercentage
    property alias fillColor: statusBtn.fillColor
    
    // Signals
    signal clicked
    signal rightClicked
    signal extendRequested

    implicitWidth: 40
    implicitHeight: 40

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // Keyboard focus support
    activeFocusOnTab: true

    StatusButton {
        id: statusBtn
        anchors.fill: parent
        focus: true

        // Default values that can be overridden
        iconPixelSize: 18
        
        // Forward focus state to button
        border.width: root.activeFocus ? 2 : 0
        border.color: Config.accent

        onClicked: {
            root.extendRequested();
            root.clicked();
        }
        
        onRightClicked: {
            root.rightClicked();
        }
    }

    // Keyboard handlers
    Keys.onReturnPressed: {
        root.extendRequested();
        root.clicked();
    }
    Keys.onSpacePressed: {
        root.extendRequested();
        root.clicked();
    }
}
