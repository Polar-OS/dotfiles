import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../config"

ColumnLayout {
    id: root
    
    property string title: ""
    property string icon: ""
    property color iconColor: Config.foreground
    property string emptyText: ""
    property bool showEmptyState: false
    
    property alias model: listView.model
    property alias delegate: listView.delegate
    property alias headerControls: headerControlsLoader.sourceComponent
    
    // Expose ListView for external focus handling
    property alias view: listView
    
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: root.icon
            font.family: Config.iconFontFamily
            font.pixelSize: 24
            color: root.iconColor
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Config.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Config.foreground
        }

        Loader {
            id: headerControlsLoader
            Layout.fillHeight: true
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Config.foreground
        opacity: 0.2
    }

    // Content Area (Stack of ListView and Empty State)
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        ListView {
            id: listView
            anchors.fill: parent
            visible: !root.showEmptyState
            clip: true
            spacing: 5
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            focus: true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
        
        Text {
            anchors.centerIn: parent
            visible: root.showEmptyState
            text: root.emptyText
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Qt.alpha(Config.foreground, 0.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }
}
