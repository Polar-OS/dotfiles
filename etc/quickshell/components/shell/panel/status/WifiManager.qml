import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../ui/button"
import Quickshell
import Quickshell.Io
import "../../../ui/panel"
import "../../../config"

Item {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string currentNetwork: ""
    property int signalStrength: 0
    
    // Dependency checking
    property bool nmcliAvailable: false
    property bool dependencyChecked: false

    property alias firstButton: powerToggleBtn

    // External navigation target (set by Status.qml)
    property var menuButton: null

    Layout.fillHeight: true
    Layout.fillWidth: true

    Component.onCompleted: {
        console.log("WiFi Manager: Component completed");
        nmcliCheckProcess.running = true;
    }
    
    // Check if nmcli is available
    Process {
        id: nmcliCheckProcess
        command: ["which", "nmcli"]
        onExited: (code) => {
            root.nmcliAvailable = (code === 0);
            root.dependencyChecked = true;
            if (root.nmcliAvailable) {
                checkStatusProcess.running = true;
            }
        }
    }

    function getWifiIcon() {
        if (!root.connected)
            return "󰤯"; // Not connected - WiFi crossed out
        if (root.signalStrength >= 75)
            return "󰤨"; // Excellent signal
        if (root.signalStrength >= 50)
            return "󰤥"; // Good signal
        if (root.signalStrength >= 25)
            return "󰤢"; // Fair signal
        return "󰤟"; // Weak signal
    }

    function toggleWifi() {
        console.log("WiFi Manager: Toggling WiFi");
        toggleProcess.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        toggleProcess.running = true;
    }

    function refreshNetworks() {
        console.log("WiFi Manager: Refreshing networks");
        if (root.wifiEnabled) {
            scanProcess.running = true;
        }
    }

    function connectToNetwork(ssid) {
        console.log("WiFi Manager: Connecting to", ssid);
        connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid];
        connectProcess.running = true;
    }

    function disconnectNetwork() {
        console.log("WiFi Manager: Disconnecting from", root.currentNetwork);
        disconnectProcess.command = ["nmcli", "connection", "down", root.currentNetwork];
        disconnectProcess.running = true;
    }

    property var networks: []

    // Connection info for active network
    property string connectionIp: ""
    property string connectionGateway: ""
    property string connectionDns: ""
    property string expandedSsid: ""

    function fetchConnectionInfo(connectionName) {
        console.log("WiFi Manager: Fetching connection info for", connectionName);
        connectionInfoProcess.command = ["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "connection", "show", connectionName];
        connectionInfoProcess.running = true;
    }

    // Get connection info
    Process {
        id: connectionInfoProcess
        running: false

        property string accumulatedData: ""

        stdout: SplitParser {
            onRead: data => {
                connectionInfoProcess.accumulatedData += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                let lines = connectionInfoProcess.accumulatedData.trim().split('\n');
                root.connectionIp = "";
                root.connectionGateway = "";
                root.connectionDns = "";

                for (let line of lines) {
                    if (line.startsWith("IP4.ADDRESS")) {
                        let parts = line.split(":");
                        if (parts.length >= 2) {
                            root.connectionIp = parts.slice(1).join(":").trim();
                        }
                    } else if (line.startsWith("IP4.GATEWAY")) {
                        let parts = line.split(":");
                        if (parts.length >= 2) {
                            root.connectionGateway = parts.slice(1).join(":").trim();
                        }
                    } else if (line.startsWith("IP4.DNS")) {
                        let parts = line.split(":");
                        if (parts.length >= 2) {
                            let dns = parts.slice(1).join(":").trim();
                            if (root.connectionDns === "") {
                                root.connectionDns = dns;
                            } else {
                                root.connectionDns += ", " + dns;
                            }
                        }
                    }
                }

                console.log("WiFi Manager: IP:", root.connectionIp, "Gateway:", root.connectionGateway, "DNS:", root.connectionDns);
                connectionInfoProcess.accumulatedData = "";
            }
        }
    }

    // Check WiFi status
    Process {
        id: checkStatusProcess
        command: ["sh", "-c", "nmcli radio wifi"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let output = data.trim();
                console.log("WiFi Manager: Radio status:", output);
                root.wifiEnabled = (output === "enabled");
                if (root.wifiEnabled) {
                    refreshNetworks();
                } else {
                    root.networks = [];
                    root.connected = false;
                    root.currentNetwork = "";
                }
            }
        }
    }

    // Scan networks
    Process {
        id: scanProcess
        command: ["nmcli", "-t", "-f", "BSSID,SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list", "--rescan", "yes"]
        running: false

        property string accumulatedData: ""

        stdout: SplitParser {
            onRead: data => {
                // Accumulate data chunks
                scanProcess.accumulatedData += data + "\n";
            }
        }

        onRunningChanged: {
            if (!running) {
                // Parse all accumulated data when process finishes
                parseNetworks(scanProcess.accumulatedData);
                scanProcess.accumulatedData = "";

                if (root.wifiEnabled) {
                    refreshTimer.restart();
                }
            }
        }
    }

    function parseNetworks(data) {
        let lines = data.trim().split('\n');
        let newNetworks = [];
        let seenSsids = {};

        root.connected = false;
        root.currentNetwork = "";
        console.log("WiFi Manager: Parsing", lines.length, "lines");

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line || line === "") continue;

            // Format: BSSID:SSID:SIGNAL:SECURITY:ACTIVE
            // Example: F4\:F6\:47\:0F\:F8\:18:DIGIFIBRA-9QGD:100:WPA2:no
            // Note: BSSID contains escaped colons (\:)

            // Parse from right to left to find the last 3 unescaped colons
            let fields = [];
            let fieldEnd = line.length;
            let colonCount = 0;

            for (let pos = line.length - 1; pos >= 0 && colonCount < 4; pos--) {
                if (line[pos] === ':' && (pos === 0 || line[pos - 1] !== '\\')) {
                    // Found an unescaped colon
                    let fieldStart = pos + 1;
                    let field = line.substring(fieldStart, fieldEnd);
                    fields.unshift(field);
                    fieldEnd = pos;
                    colonCount++;
                }
            }

            // We need 4 fields: ACTIVE, SECURITY, SIGNAL, SSID
            if (fields.length < 4) {
                console.log("WiFi Manager: Could not parse line:", line);
                continue;
            }

            let ssid = fields[0];
            let signal = parseInt(fields[1]) || 0;
            let security = fields[2];
            let active = (fields[3] === "yes");

            if (ssid === "--" || ssid === "") continue;

            if (active) {
                root.connected = true;
                root.currentNetwork = ssid;
                root.signalStrength = signal;
                console.log("WiFi Manager: Active network:", ssid, "signal:", signal);
            }

            // Skip duplicate SSIDs (keep active one, or one with better signal)
            if (seenSsids[ssid] !== undefined) {
                let existingIndex = seenSsids[ssid];
                let existing = newNetworks[existingIndex];
                // Always prefer the active entry, otherwise prefer better signal
                if (active || (!existing.active && signal > existing.signal)) {
                    newNetworks[existingIndex].signal = signal;
                    newNetworks[existingIndex].security = security;
                    newNetworks[existingIndex].active = active;
                }
                continue;
            }

            seenSsids[ssid] = newNetworks.length;

            newNetworks.push({
                ssid: ssid,
                signal: signal,
                security: security,
                active: active
            });
        }

        // Sort by signal strength (descending)
        newNetworks.sort((a, b) => b.signal - a.signal);

        root.networks = newNetworks;
        console.log("WiFi Manager: Networks parsed:", newNetworks.length);

        if (!root.connected) {
            root.signalStrength = 0;
        }
    }

    // Toggle WiFi
    Process {
        id: toggleProcess
        running: false

        onRunningChanged: {
            if (!running) {
                refreshTimer.interval = 2000;
                refreshTimer.restart();
            }
        }
    }

    // Connect to network
    Process {
        id: connectProcess
        running: false

        onRunningChanged: {
            if (!running) {
                refreshTimer.interval = 2000;
                refreshTimer.restart();
            }
        }
    }

    // Disconnect from network
    Process {
        id: disconnectProcess
        running: false

        onRunningChanged: {
            if (!running) {
                refreshTimer.interval = 2000;
                refreshTimer.restart();
            }
        }
    }

    // Periodic refresh
    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            console.log("WiFi Manager: Periodic refresh");
            checkStatusProcess.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: getWifiIcon()
                font.family: Config.iconFontFamily
                font.pixelSize: 24
                color: root.connected ? Config.accent : Config.foreground
            }

            Text {
                Layout.fillWidth: true
                text: "WiFi"
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.bold: true
                color: Config.foreground
            }

            // Power toggle
            QuickButton {
                id: powerToggleBtn
                size: 32
                icon: root.wifiEnabled ? "󱨥" : "󱨦"

                onClicked: {
                    toggleWifi();
                }

                Keys.onDownPressed: {
                    if (wifiList.count > 0) {
                        let firstItem = wifiList.itemAtIndex(0);
                        if (firstItem) firstItem.forceActiveFocus();
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.foreground
            opacity: 0.2
        }

        // Status when WiFi is off
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.wifiEnabled
            text: "WiFi is disabled\nRight-click button to enable"
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Qt.alpha(Config.foreground, 0.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        // Network list
        ListView {
            id: wifiList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.wifiEnabled
            clip: true
            spacing: 5
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            focus: true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            model: root.networks

            delegate: Rectangle {
                id: networkDelegate
                required property var modelData
                required property int index

                property bool isExpanded: root.expandedSsid === modelData.ssid && modelData.active

                width: wifiList.width
                height: isExpanded ? 130 : 60
                radius: Config.itemRadius
                color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)

                activeFocusOnTab: true
                border.width: activeFocus ? 2 : 0
                border.color: Config.accent

                Behavior on height {
                    NumberAnimation { duration: Config.animationDurationQuick; easing.type: Config.animEasingSoft }
                }

                // MouseArea at the bottom (z: 0) so buttons can receive clicks
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    z: 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (modelData.active) {
                            disconnectNetwork();
                        } else {
                            connectToNetwork(modelData.ssid);
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    z: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Signal icon
                        Text {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            text: {
                                let strength = modelData.signal;
                                if (strength >= 75) return "󰤨";
                                if (strength >= 50) return "󰤥";
                                if (strength >= 25) return "󰤢";
                                return "󰤟";
                            }
                            font.family: Config.iconFontFamily
                            font.pixelSize: 20
                            color: modelData.active ? Config.accent : Qt.alpha(Config.foreground, 0.8)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Network info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                font.bold: modelData.active
                                color: modelData.active ? Config.accent : Config.foreground
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: modelData.signal + "%"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Qt.alpha(Config.foreground, 0.6)
                                }

                                // Security lock icon
                                Text {
                                    visible: modelData.security && modelData.security !== ""
                                    text: "󰌋"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 11
                                    color: Qt.alpha(Config.foreground, 0.6)
                                }

                                // Connected indicator
                                Text {
                                    visible: modelData.active
                                    text: "Connected"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.accent
                                }
                            }
                        }

                        // IP info button (only for active network)
                        QuickButton {
                            id: ipInfoBtn
                            visible: modelData.active
                            size: 28
                            icon: networkDelegate.isExpanded ? "󰁅" : "󰩟"
                            activeFocusOnTab: true

                            onClicked: {
                                if (networkDelegate.isExpanded) {
                                    root.expandedSsid = "";
                                } else {
                                    root.expandedSsid = modelData.ssid;
                                    root.fetchConnectionInfo(modelData.ssid);
                                }
                            }

                            Keys.onLeftPressed: networkDelegate.forceActiveFocus()
                            Keys.onRightPressed: {
                                if (root.menuButton) root.menuButton.forceActiveFocus();
                            }
                        }
                    }

                    // Expanded connection info
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: networkDelegate.isExpanded
                        color: Qt.rgba(0, 0, 0, 0.2)
                        radius: Config.itemRadius / 2

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰩟"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 12
                                    color: Qt.alpha(Config.foreground, 0.7)
                                }
                                Text {
                                    text: "IP: " + (root.connectionIp || "...")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.foreground
                                }
                            }

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰛳"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 12
                                    color: Qt.alpha(Config.foreground, 0.7)
                                }
                                Text {
                                    text: "Gateway: " + (root.connectionGateway || "...")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.foreground
                                }
                            }

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "󰇖"
                                    font.family: Config.iconFontFamily
                                    font.pixelSize: 12
                                    color: Qt.alpha(Config.foreground, 0.7)
                                }
                                Text {
                                    text: "DNS: " + (root.connectionDns || "...")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.foreground
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                Keys.onReturnPressed: {
                    if (modelData.active) {
                        disconnectNetwork();
                    } else {
                        connectToNetwork(modelData.ssid);
                    }
                }

                Keys.onUpPressed: {
                    if (index > 0) {
                        let prevItem = wifiList.itemAtIndex(index - 1);
                        if (prevItem) prevItem.forceActiveFocus();
                    } else {
                        powerToggleBtn.forceActiveFocus();
                    }
                }

                Keys.onDownPressed: {
                    if (index < wifiList.count - 1) {
                        let nextItem = wifiList.itemAtIndex(index + 1);
                        if (nextItem) nextItem.forceActiveFocus();
                    }
                }

                Keys.onRightPressed: {
                    if (root.menuButton) root.menuButton.forceActiveFocus();
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDurationFast
                    }
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: wifiList.count === 0 && root.wifiEnabled
                text: "No networks found\nClick refresh to scan"
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: Qt.alpha(Config.foreground, 0.5)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
