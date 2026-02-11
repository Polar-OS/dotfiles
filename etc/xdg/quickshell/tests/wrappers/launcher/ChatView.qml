import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import ".."

Item {
    id: root

    property ChatProvider provider
    property bool isActive: false

    signal closeRequested()

    // Components defined at root for scope visibility
    Component {
        id: userTextComp
        Text {
            // Use parent.msgData because Loader has property msgData
            text: (parent.msgData ? parent.msgData.content : "") || ""
            width: parent.width
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.foreground
            wrapMode: Text.WordWrap
            textFormat: Text.MarkdownText
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }

    Component {
        id: assistantContentComp
        ColumnLayout {
            spacing: 8
            width: parent ? parent.width : 0
            
            // Access the model property explicitly set on the Loader
            // Use 'parent.msgData' because we renamed the property in the Loader
            property var messageItem: parent.msgData 
            property string fullText: messageItem ? (messageItem.content || "") : ""
            
            property var blocks: {
                var result = [];
                var text = fullText;
                var parts = text.split("```");
                
                for (var i = 0; i < parts.length; i++) {
                    var part = parts[i];
                    if (i % 2 === 0) {
                        if (part.trim().length > 0) {
                            result.push({ type: "text", content: part });
                        }
                    } else {
                        var newlineIndex = part.indexOf('\n');
                        var language = "";
                        var code = part;
                        if (newlineIndex > -1) {
                            language = part.substring(0, newlineIndex).trim();
                            code = part.substring(newlineIndex + 1);
                        }
                        result.push({ type: "code", language: language, content: code });
                    }
                }
                return result;
            }

            Repeater {
                model: parent.blocks
                delegate: Loader {
                    Layout.fillWidth: true
                    sourceComponent: modelData.type === "code" ? codeBlockComp : textBlockComp
                    property var blockData: modelData
                    // Pass timestamp from the parent ColumnLayout's captured model
                    property var timestamp: parent.messageItem ? parent.messageItem.timestamp : 0
                }
            }
        }
    }

    function scrollToBottom() {
        if (messagesList.contentHeight > messagesList.height) {
            messagesList.positionViewAtEnd();
        }
    }

    Component {
        id: textBlockComp
        Item {
            // Access blockData from the parent Loader
            property var blockData: parent.blockData
            property string fullText: blockData ? blockData.content : ""
            property string displayedText: ""
            
            width: parent.width
            implicitHeight: textItem.implicitHeight

            // Smooth typing effect
            Timer {
                id: typeTimer
                interval: 16 // ~60 FPS
                repeat: true
                // Removed running binding loop. Handled in onFullTextChanged and onTriggered
                onTriggered: {
                    var current = parent.displayedText;
                    var target = parent.fullText;
                    
                    if (current.length < target.length) {
                        var diff = target.length - current.length;
                        // Smoother adaptive step
                        var step = 1;
                        if (diff > 100) step = 5;
                        else if (diff > 50) step = 3;
                        else if (diff > 20) step = 2;
                        
                        parent.displayedText = target.substring(0, current.length + step);
                    } else {
                        parent.displayedText = target;
                        running = false;
                    }
                }
            }

            // Instant update for large changes (initial load or context switch)
            onFullTextChanged: {
                if (fullText.length - displayedText.length > 500 || displayedText.length > fullText.length) {
                    displayedText = fullText;
                    typeTimer.running = false;
                } else if (fullText !== displayedText) {
                    typeTimer.running = true;
                }
            }
            
            Text {
                id: textItem
                text: parent.displayedText
                width: parent.width
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Config.foreground
                wrapMode: Text.WordWrap
                textFormat: Text.MarkdownText
                onLinkActivated: Qt.openUrlExternally(link)
                onHeightChanged: root.scrollToBottom()
            }
        }
    }

    Component {
        id: codeBlockComp
        Rectangle {
            width: parent.width
            implicitHeight: codeCol.implicitHeight + 20
            color: Qt.darker(Config.background, 1.2)
            radius: 6
            border.color: Qt.alpha(Config.foreground, 0.1)
            border.width: 1

            // Capture blockData from parent Loader so inner children can access it
            property var blockData: parent.blockData

            ColumnLayout {
                id: codeCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: (blockData && blockData.language) ? blockData.language : "Code"
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: Qt.alpha(Config.foreground, 0.6)
                    }
                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(Config.foreground, 0.1)
                }

                TextEdit {
                    Layout.fillWidth: true
                    
                    property string fullText: blockData ? blockData.content : ""
                    property string displayedText: ""

                    Timer {
                        id: codeTypeTimer
                        interval: 16 // ~60 FPS
                        repeat: true
                        // Removed running binding loop. Handled in onFullTextChanged and onTriggered
                        onTriggered: {
                            var current = parent.displayedText;
                            var target = parent.fullText;
                            if (current.length < target.length) {
                                var diff = target.length - current.length;
                                // Smoother adaptive step
                                var step = 1;
                                if (diff > 100) step = 5;
                                else if (diff > 50) step = 3;
                                else if (diff > 20) step = 2;

                                parent.displayedText = target.substring(0, current.length + step);
                            } else {
                                parent.displayedText = target;
                                running = false;
                            }
                        }
                    }

                    onFullTextChanged: {
                        if (fullText.length - displayedText.length > 500 || displayedText.length > fullText.length) {
                            displayedText = fullText;
                            codeTypeTimer.running = false;
                        } else if (fullText !== displayedText) {
                            codeTypeTimer.running = true;
                        }
                    }

                    text: displayedText
                    font.family: "Cascadia Code"
                    font.pixelSize: 12
                    color: Config.foreground
                    readOnly: true
                    selectByMouse: true
                    wrapMode: Text.WrapAnywhere
                    onHeightChanged: root.scrollToBottom()
                }
            }
        }
    }

    // Header with model/agent selectors
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Top bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 10

            // Back button
            Rectangle {
                width: 32
                height: 32
                radius: Config.itemRadius
                color: backMouse.containsMouse ? Qt.alpha(Config.foreground, 0.15) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    font.family: Config.iconFontFamily
                    font.pixelSize: 16
                    color: Config.foreground
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }

            // Title
            Text {
                text: "AI Chat"
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: Config.foreground
            }

            Item { Layout.fillWidth: true }

            // Agent selector
            Rectangle {
                id: agentSelectorRect
                Layout.preferredWidth: 100
                Layout.preferredHeight: 28
                radius: Config.itemRadius
                color: Qt.alpha(Config.foreground, 0.1)

                function getAgentName() {
                    if (!provider) return "Loading...";
                    if (!provider.selectedAgent) return "No Agent";
                    
                    for (var i = 0; i < provider.availableAgents.length; i++) {
                        var a = provider.availableAgents[i];
                        if ((a.name || a.id) === provider.selectedAgent) {
                            return a.name || a.id;
                        }
                    }
                    return provider.selectedAgent;
                }

                RowLayout {
                    id: agentRow
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        text: "󰘦"
                        font.family: Config.iconFontFamily
                        font.pixelSize: 12
                        color: Config.accent
                    }

                    Text {
                        text: agentSelectorRect.getAgentName()
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.foreground
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        agentMenu.open();
                        agentMenu.loadItems();
                    }
                }

                Menu {
                    id: agentMenu
                    y: parent.height + 4
                    width: 250
                    padding: 6
                    
                    function loadItems() { } 

                    background: Rectangle {
                        color: Config.background
                        radius: Config.itemRadius
                        border.color: Qt.alpha(Config.foreground, 0.15)
                        border.width: 1
                    }
                    
                    MenuItem {
                        text: "No Agent"
                        width: parent ? parent.width : 200
                        height: 40
                        
                        onTriggered: {
                            if (provider) {
                                provider.selectedAgent = "";
                                if (!provider.selectedModel && provider.availableModels.length > 0) {
                                    provider.selectedProvider = provider.availableModels[0].providerID;
                                    provider.selectedModel = provider.availableModels[0].id;
                                }
                            }
                            agentMenu.close();
                        }
                        background: Rectangle {
                            color: parent.highlighted ? Qt.alpha(Config.accent, 0.15) : "transparent"
                            radius: Config.itemRadius
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "󰘦"
                                font.family: Config.iconFontFamily
                                font.pixelSize: 14
                                color: parent.parent.highlighted ? Config.accent : Qt.alpha(Config.foreground, 0.5)
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "No Agent"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Config.foreground
                                }
                                Text {
                                    text: "Raw Model Mode"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Qt.alpha(Config.foreground, 0.6)
                                }
                            }
                        }
                    }
                    
                    // Separator
                    MenuSeparator {
                        padding: 0
                        topPadding: 4
                        bottomPadding: 4
                        contentItem: Rectangle {
                            implicitWidth: 200
                            implicitHeight: 1
                            color: Qt.alpha(Config.foreground, 0.1)
                        }
                    }
                    
                    Instantiator {
                        model: provider ? provider.availableAgents : []
                        delegate: MenuItem {
                            text: modelData.name || modelData.id
                            width: parent ? parent.width : 200
                            height: 40
                            
                            onTriggered: {
                                if (provider) {
                                    provider.selectedAgent = modelData.name || modelData.id;
                                    if (modelData.model) {
                                        provider.selectedProvider = modelData.model.providerID;
                                        provider.selectedModel = modelData.model.modelID;
                                    }
                                }
                                agentMenu.close();
                            }
                            background: Rectangle {
                                color: parent.highlighted ? Qt.alpha(Config.accent, 0.15) : "transparent"
                                radius: Config.itemRadius
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰄛"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 14
                                    color: parent.parent.highlighted ? Config.accent : Qt.alpha(Config.foreground, 0.5)
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: modelData.name || modelData.id
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Config.foreground
                                    }
                                    Text {
                                        text: modelData.description || "AI Agent"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        color: Qt.alpha(Config.foreground, 0.6)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                        onObjectAdded: (index, object) => agentMenu.insertItem(index + 2, object)
                        onObjectRemoved: (index, object) => agentMenu.removeItem(object)
                    }
                }
            }
            
            // Model selector
            Rectangle {
                id: modelSelectorRect
                Layout.preferredWidth: 160
                Layout.preferredHeight: 28
                radius: Config.itemRadius
                color: Qt.alpha(Config.foreground, 0.1)
                visible: true 

                function getModelName() {
                    if (!provider) return "Loading...";
                    if (provider.selectedModel) {
                        for (var i = 0; i < provider.availableModels.length; i++) {
                            if (provider.availableModels[i].id === provider.selectedModel) {
                                return provider.availableModels[i].name;
                            }
                        }
                        return provider.selectedModel;
                    }
                    return "Select Model";
                }

                RowLayout {
                    id: modelRow
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 20)
                    spacing: 6
                    
                    Text {
                        text: "󰆦" 
                        font.family: Config.iconFontFamily
                        font.pixelSize: 12
                        color: Config.accent
                    }

                    Text {
                        text: modelSelectorRect.getModelName()
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.foreground
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelMenu.open()
                }

                Menu {
                    id: modelMenu
                    y: parent.height + 4
                    width: 250
                    height: 320
                    padding: 6
                    
                    background: Rectangle {
                        color: Config.background
                        radius: Config.itemRadius
                        border.color: Qt.alpha(Config.foreground, 0.15)
                        border.width: 1
                    }
                    
                    contentItem: ListView {
                        implicitHeight: contentHeight
                        model: provider ? provider.availableModels : []
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            width: 4
                            policy: ScrollBar.AsNeeded
                            active: true
                            contentItem: Rectangle {
                                color: Qt.alpha(Config.foreground, 0.3)
                                radius: 2
                            }
                        }

                        delegate: MenuItem {
                            text: modelData.name || modelData.id
                            width: parent ? parent.width : 200
                            height: 40
                            
                            onTriggered: {
                                if (provider) {
                                    provider.selectedProvider = modelData.providerID;
                                    provider.selectedModel = modelData.id;
                                }
                                modelMenu.close();
                            }
                            background: Rectangle {
                                color: parent.highlighted ? Qt.alpha(Config.accent, 0.15) : "transparent"
                                radius: Config.itemRadius
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰆦"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 14
                                    color: parent.parent.highlighted ? Config.accent : Qt.alpha(Config.foreground, 0.5)
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: modelData.name || modelData.id
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        color: Config.foreground
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.providerID
                                        font.family: Config.fontFamily
                                        font.pixelSize: 10
                                        color: Qt.alpha(Config.foreground, 0.6)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Connection status
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: provider && provider.connected ? Config.green : Config.red

                ToolTip {
                    visible: statusMouse.containsMouse
                    text: provider && provider.connected ? "Connected" : "Disconnected"
                    delay: 500
                }

                MouseArea {
                    id: statusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (provider) provider.checkHealth();
                    }
                }
            }
        }

        // Messages area (TUI Style)
        ListView {
            id: messagesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 16
            model: provider ? provider.model : null

            onCountChanged: {
                Qt.callLater(function() {
                    messagesList.positionViewAtEnd();
                });
            }
            
            Connections {
                target: provider
                function onMessageStreamUpdated() {
                    // Only scroll if we are already near the bottom or it's a new message
                    if (messagesList.atYEnd || messagesList.contentY >= messagesList.contentHeight - messagesList.height - 100) {
                        messagesList.positionViewAtEnd();
                    }
                }
            }

            delegate: ColumnLayout {
                id: msgDelegate
                width: messagesList.width - 20
                x: 10 // Center manually to avoid parent access issues
                spacing: 4
                
                property var messageData: model
                
                // Header (Role)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: model.role === "user" ? "❯ USER" : "❯ MODEL"
                        font.family: "Cascadia Code"
                        font.pixelSize: 11
                        font.bold: true
                        color: model.role === "user" ? Config.accent : Config.green
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(Config.foreground, 0.1)
                    }
                }

                // Content (No Bubble)
                Loader {
                    id: contentLoader
                    Layout.fillWidth: true
                    Layout.leftMargin: 12 // Indent content slightly
                    
                    sourceComponent: model.role === "user" ? userTextComp : assistantContentComp
                    
                    // Rename property to avoid context conflicts with 'model'
                    property var msgData: parent.messageData
                    property var timestamp: msgData.timestamp
                }
            }
        }

        // Animated Thinking Bubble (Terminal Cursor Style)
            Rectangle {
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 20
                width: 200
                height: 20
                color: "transparent"
                visible: {
                    if (!provider || !provider.loading) return false;
                    if (!messagesList.model || messagesList.count === 0) return true;
                    var last = messagesList.model.get(messagesList.count - 1);
                    return last.role !== "assistant" || !last.content;
                }

                Row {
                    spacing: 2
                    
                    Text {
                        text: "thinking"
                        font.family: "Cascadia Code"
                        font.pixelSize: 12
                        color: Qt.alpha(Config.foreground, 0.5)
                    }

                    Rectangle {
                        width: 8
                        height: 14
                        color: Config.accent
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: parent.visible
                            NumberAnimation { from: 1; to: 0; duration: Config.animDurationFast }
                            PauseAnimation { duration: Config.animDurationPause }
                            NumberAnimation { from: 0; to: 1; duration: Config.animDurationFast }
                            PauseAnimation { duration: Config.animDurationPause }
                        }
                    }
                }
            }

        // Error message
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            visible: provider && provider.error !== ""
            implicitWidth: errorText.implicitWidth + 20
            implicitHeight: errorText.implicitHeight + 12
            color: Qt.alpha(Config.red, 0.2)
            radius: Config.itemRadius
            border.color: Config.red
            border.width: 1

            Text {
                id: errorText
                anchors.centerIn: parent
                text: provider ? provider.error : ""
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Config.red
            }
        }

        // Missing dependency state (binary not installed)
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            visible: provider && provider.dependencyChecked && !provider.binaryAvailable
            implicitWidth: missingDepCol.implicitWidth + 40
            implicitHeight: missingDepCol.implicitHeight + 40
            color: "transparent"

            ColumnLayout {
                id: missingDepCol
                anchors.centerIn: parent
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰀦"
                    font.family: Config.iconFontFamily
                    font.pixelSize: 48
                    color: Qt.alpha(Config.red, 0.5)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Missing Dependency"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: Config.red
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "• opencode binary not found"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Qt.alpha(Config.foreground, 0.5)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Install from: github.com/opencode-ai/opencode"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Qt.alpha(Config.foreground, 0.3)
                }
            }
        }

        // Disconnected state (binary exists but server not running)
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            visible: provider && provider.binaryAvailable && !provider.connected && !provider.loading
            implicitWidth: disconnectedCol.implicitWidth + 40
            implicitHeight: disconnectedCol.implicitHeight + 40
            color: "transparent"

            ColumnLayout {
                id: disconnectedCol
                anchors.centerIn: parent
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰅛"
                    font.family: Config.iconFontFamily
                    font.pixelSize: 48
                    color: Qt.alpha(Config.red, 0.5)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "OpenCode server not running"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Qt.alpha(Config.foreground, 0.5)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Run 'opencode' in a terminal first"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Qt.alpha(Config.foreground, 0.3)
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: retryText.width + 24
                    height: 28
                    radius: Config.itemRadius
                    color: retryMouse.containsMouse ? Qt.alpha(Config.accent, 0.3) : Qt.alpha(Config.accent, 0.2)

                    Text {
                        id: retryText
                        anchors.centerIn: parent
                        text: "Retry Connection"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.accent
                    }

                    MouseArea {
                        id: retryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (provider) provider.checkHealth();
                        }
                    }
                }
            }
        }

        // Input area
        Rectangle {
            Layout.fillWidth: true
            // Auto-grow height with a max limit
            Layout.preferredHeight: Math.min(Math.max(chatInput.contentHeight + 20, 50), 200)
            color: Qt.alpha(Config.foreground, 0.1)
            radius: Config.itemRadius
            border.color: chatInput.activeFocus ? Config.accent : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                ScrollView {
                    id: inputScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    TextEdit {
                        id: chatInput
                        width: inputScrollView.availableWidth
                        // Ensure input fills the scroll view for vertical centering when text is short
                        height: Math.max(inputScrollView.availableHeight, contentHeight)
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        verticalAlignment: TextEdit.AlignVCenter
                        horizontalAlignment: TextEdit.AlignLeft
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        enabled: provider && provider.connected && !provider.loading

                        property string placeholderText: "Type a message..."

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 4 // Match TextEdit padding if any
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: chatInput.placeholderText
                            font: chatInput.font
                            color: Qt.alpha(Config.foreground, 0.4)
                            visible: !chatInput.text && !chatInput.activeFocus
                        }

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false; // Allow new line
                            } else {
                                event.accepted = true; // Block default enter
                                if (text.trim() && provider && provider.connected) {
                                    if (!provider.sessionId) {
                                        provider.createSession("Quickshell Chat");
                                        var sendText = text;
                                        text = "";
                                        Qt.callLater(function() {
                                            waitForSession(sendText);
                                        });
                                    } else {
                                        provider.sendMessage(text);
                                        text = "";
                                    }
                                }
                            }
                        }

                        function waitForSession(msg) {
                            if (provider.sessionId) {
                                provider.sendMessage(msg);
                            } else if (!provider.loading) {
                                console.error("Failed to create session");
                            } else {
                                Qt.callLater(function() { waitForSession(msg); });
                            }
                        }

                        Keys.onEscapePressed: {
                            if (provider && provider.loading) {
                                provider.abort();
                            } else {
                                root.closeRequested();
                            }
                        }
                    }
                }

                // Send button
                Rectangle {
                    Layout.alignment: Qt.AlignBottom
                    width: 32
                    height: 32
                    radius: Config.itemRadius
                    color: sendMouse.containsMouse && chatInput.text.trim() 
                        ? Qt.alpha(Config.accent, 0.3) 
                        : Qt.alpha(Config.accent, 0.15)
                    opacity: chatInput.text.trim() && provider && provider.connected && !provider.loading ? 1 : 0.4

                    Text {
                        anchors.centerIn: parent
                        text: provider && provider.loading ? "󰓛" : "󰒊"
                        font.family: Config.iconFontFamily
                        font.pixelSize: 16
                        color: Config.accent
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: chatInput.text.trim() ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (provider && provider.loading) {
                                provider.abort();
                            } else if (chatInput.text.trim() && provider && provider.connected) {
                                // Trigger manual send logic matching Keys.onReturnPressed
                                var text = chatInput.text;
                                if (!provider.sessionId) {
                                    provider.createSession("Quickshell Chat");
                                    var sendText = text;
                                    chatInput.text = "";
                                    Qt.callLater(function() {
                                        chatInput.waitForSession(sendText);
                                    });
                                } else {
                                    provider.sendMessage(text);
                                    chatInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Focus input when becoming active
    onIsActiveChanged: {
        if (isActive) {
            Qt.callLater(function() {
                chatInput.forceActiveFocus();
            });
        }
    }

    // Initialize provider when set
    onProviderChanged: {
        if (provider) {
            provider.init();
        }
    }
}