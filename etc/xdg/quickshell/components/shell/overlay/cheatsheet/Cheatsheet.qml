import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../ui/shell" // OverlayWindow
import "../../../config"

OverlayWindow {
    id: root
    active: false
    windowWidth: 1000
    windowHeight: 700

    property string searchQuery: ""

    onActiveChanged: {
        if (active) {
            searchQuery = "";
        }
    }

    view: FocusScope {
        id: contentRoot
        anchors.fill: parent
        focus: true

        Process {
            id: executor
        }

        // Filtered categories based on search query
        property var filteredLeft: parser ? filterCategories(parser.categoriesLeft, root.searchQuery) : []
        property var filteredRight: parser ? filterCategories(parser.categoriesRight, root.searchQuery) : []
        
        ConfigParser {
            id: parser
            Component.onCompleted: load()
        }

        // Hidden input field to capture keyboard events reliably
        TextInput {
            id: hiddenInput
            focus: true
            width: 0
            height: 0
            activeFocusOnTab: false
            
            onTextChanged: {
                root.searchQuery = text;
            }

            // Ensure this gets focus when the overlay becomes active
            Connections {
                target: root
                function onActiveChanged() {
                    if (root.active) {
                        hiddenInput.text = "";
                        // Small delay to ensure the window is mapped before focusing
                        Qt.callLater(() => hiddenInput.forceActiveFocus());
                    }
                }
            }
            
            Component.onCompleted: forceActiveFocus()
        }

        // Clicking anywhere in the content area restores focus to the input
        MouseArea {
            anchors.fill: parent
            onClicked: hiddenInput.forceActiveFocus()
        }

        function filterCategories(categories, queryText) {
            if (!queryText || queryText.length === 0) {
                return categories;
            }
            var query = queryText.toLowerCase();
            var result = [];
            for (var i = 0; i < categories.length; i++) {
                var cat = categories[i];
                var filteredBinds = [];
                for (var j = 0; j < cat.binds.length; j++) {
                    var bind = cat.binds[j];
                    var keysMatch = bind.keys.toLowerCase().indexOf(query) !== -1;
                    var actionMatch = bind.action.toLowerCase().indexOf(query) !== -1;
                    var categoryMatch = cat.name.toLowerCase().indexOf(query) !== -1;
                    if (keysMatch || actionMatch || categoryMatch) {
                        filteredBinds.push(bind);
                    }
                }
                if (filteredBinds.length > 0) {
                    result.push({
                        name: cat.name,
                        binds: filteredBinds
                    });
                }
            }
            return result;
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.searchQuery.length > 0 
                        ? "Searching: \"" + root.searchQuery + "\""
                        : "Key Bindings"
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                    font.bold: true
                    color: Config.accent
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: root.searchQuery.length > 0 ? "" : "Type to search..."
                    color: Config.dimmed
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.italic: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Config.foreground, 0.1)
            }

            // Content Area
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                // Masonry-style Layout (2 Independent Columns)
                RowLayout {
                    width: 940 // Fixed width to ensure correct splitting
                    spacing: 40

                    // Left Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 25

                        Repeater {
                            model: contentRoot.filteredLeft
                            delegate: CategoryComponent {
                                name: modelData.name
                                binds: modelData.binds
                                searchQuery: root.searchQuery
                            }
                        }
                    }

                    // Right Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 25

                        Repeater {
                            model: contentRoot.filteredRight
                            delegate: CategoryComponent {
                                name: modelData.name
                                binds: modelData.binds
                                searchQuery: root.searchQuery
                            }
                        }
                    }
                }
            }
        }

        // Reusable Category Block (moved inside FocusScope for better lexical scope access)
        component CategoryComponent: ColumnLayout {
            property string name
            property var binds
            property string searchQuery: ""

            Layout.fillWidth: true
            spacing: 12

            Text {
                text: name
                color: Config.dimmed
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: 15

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -2
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Config.foreground, 0.1)
                }
            }

            Repeater {
                model: binds
                delegate: BindRow {
                    keys: modelData.keys
                    action: modelData.action
                    searchQuery: root.searchQuery

                    onClicked: {
                        executor.command = ["sh", "-c", modelData.rawAction];
                        executor.running = true;
                        root.active = false;
                    }
                }
            }
        }

        component BindRow: Rectangle {
            property string keys: ""
            property string action: ""
            property string searchQuery: ""
            signal clicked
            
            // Helper function to create highlighted text with rich text format
            function highlightText(text, query) {
                if (!query || query.length === 0) {
                    return text;
                }
                var lowerText = text.toLowerCase();
                var lowerQuery = query.toLowerCase();
                var result = "";
                var lastIndex = 0;
                var index = lowerText.indexOf(lowerQuery);
                while (index !== -1) {
                    // Add text before match
                    result += text.substring(lastIndex, index);
                    // Add highlighted match with accent color
                    result += "<font color=\"" + Config.accent + "\"><b>" + text.substring(index, index + query.length) + "</b></font>";
                    lastIndex = index + query.length;
                    index = lowerText.indexOf(lowerQuery, lastIndex);
                }
                // Add remaining text
                result += text.substring(lastIndex);
                return result;
            }

            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: mouseArea.containsMouse ? Qt.alpha(Config.foreground, 0.05) : "transparent"
            radius: Config.radius

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: Math.max(70, keyText.contentWidth + 16)
                    color: Qt.alpha(Config.accent, 0.15)
                    radius: Config.itemRadius
                    border.color: Qt.alpha(Config.accent, 0.3)
                    border.width: 1

                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: highlightText(keys, searchQuery)
                        textFormat: Text.RichText
                        font.family: Config.fontFamily
                        font.bold: true
                        font.pixelSize: 12
                        color: Config.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: highlightText(action, searchQuery)
                    textFormat: Text.RichText
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Config.foreground
                    elide: Text.ElideRight
                }

                Text {
                    visible: mouseArea.containsMouse
                    text: ""
                    font.family: Config.iconFontFamily
                    font.pixelSize: 10
                    color: Config.accent
                }
            }
        }
    }
}
