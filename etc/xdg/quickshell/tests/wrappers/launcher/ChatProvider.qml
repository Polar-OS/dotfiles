import QtQuick
import Quickshell 1.0
import Quickshell.Io 1.0
import ".." // Import components folder to access Config singleton

Item {
    id: root

    // Server configuration
    property string baseUrl: "http://127.0.0.1:4098"
    property bool connected: false
    property bool loading: false
    property string error: ""
    
    // Dependency checking
    property bool binaryAvailable: false
    property bool dependencyChecked: false

    // Current session
    property string sessionId: ""
    property string sessionTitle: ""

    // Model/Agent selection
    property string selectedProvider: ""
    property string selectedModel: ""
    property string selectedAgent: ""
    property var availableProviders: []
    property var availableModels: []
    property var availableAgents: []

    // Messages
    property var messages: []
    signal responseReceived(var response)
    signal connectionStatusChanged(bool connected)
    signal messageStreamUpdated()

    ListModel {
        id: messagesModel
    }
    property alias model: messagesModel

    // Check server health
    function checkHealth() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        root.connected = response.healthy === true;
                        root.error = "";
                        console.log("OpenCode server connected, version:", response.version);
                        root.connectionStatusChanged(root.connected);
                    } catch (e) {
                        root.connected = false;
                        root.error = "Invalid server response";
                    }
                } else {
                    root.connected = false;
                    root.error = "Server not available";
                }
            }
        };
        xhr.open("GET", baseUrl + "/global/health");
        xhr.send();
    }

    // Load available providers and models
    function loadProviders() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        root.availableProviders = response.providers || [];
                        
                        // Flatten models for easier selection
                        var flatModels = [];
                        for (var i = 0; i < root.availableProviders.length; i++) {
                            var p = root.availableProviders[i];
                            if (p.models) {
                                for (var k in p.models) {
                                    var m = p.models[k];
                                    flatModels.push({
                                        id: m.id,
                                        name: m.name || m.id,
                                        providerID: p.id,
                                        family: m.family || ""
                                    });
                                }
                            }
                        }
                        root.availableModels = flatModels;
                        console.log("Loaded providers:", root.availableProviders.length, "Models:", root.availableModels.length);
                    } catch (e) {
                        console.error("Failed to parse providers:", e);
                    }
                }
            }
        };
        xhr.open("GET", baseUrl + "/config/providers");
        xhr.send();
    }

    // Load available agents
    function loadAgents() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var text = xhr.responseText.trim();
                    if (text.length === 0 || text.startsWith("<")) {
                        console.warn("Agents endpoint returned invalid content (likely HTML/404), ignoring.");
                        return;
                    }
                    try {
                        var response = JSON.parse(text);
                        root.availableAgents = response || [];
                        // Select first agent if none selected
                        if (!root.selectedAgent && root.availableAgents.length > 0) {
                            root.selectedAgent = root.availableAgents[0].name || root.availableAgents[0].id || "";
                        }
                        
                        // Populate provider/model from agent if selected AND no model is currently selected (respect persistence)
                        if (root.selectedAgent && !root.selectedModel) {
                           for (var i = 0; i < root.availableAgents.length; i++) {
                               var agent = root.availableAgents[i];
                               var agentId = agent.name || agent.id;
                               if (agentId === root.selectedAgent) {
                                   if (agent.model) {
                                       root.selectedProvider = agent.model.providerID;
                                       root.selectedModel = agent.model.modelID;
                                   }
                                   break;
                               }
                           }
                        }
                        
                        console.log("Loaded agents:", root.availableAgents.length);
                    } catch (e) {
                        console.error("Failed to parse agents:", e);
                    }
                }
            }
        };
        xhr.open("GET", baseUrl + "/agent");
        xhr.send();
    }

    // Create a new session
    function createSession(title) {
        root.loading = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false;
                if (xhr.status === 200 || xhr.status === 201) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        root.sessionId = response.id || "";
                        root.sessionTitle = response.title || title || "New Chat";
                        messagesModel.clear();
                        root.messages = [];
                        console.log("Created session:", root.sessionId);
                    } catch (e) {
                        console.error("Failed to parse session:", e);
                        root.error = "Failed to create session";
                    }
                } else {
                    root.error = "Failed to create session: " + xhr.status;
                }
            }
        };
        xhr.open("POST", baseUrl + "/session");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({
            title: title || "Quickshell Chat"
        }));
    }

    // Load session messages
    function loadMessages() {
        if (!root.sessionId)
            return;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var text = xhr.responseText.trim();
                    if (text.length === 0 || text.startsWith("<")) {
                        console.warn("Messages endpoint returned invalid content");
                        return;
                    }
                    try {
                        var response = JSON.parse(text);
                        messagesModel.clear();
                        root.messages = [];

                        for (var i = 0; i < response.length; i++) {
                            var msg = response[i];
                            var info = msg.info || {};
                            var parts = msg.parts || [];

                            var textContent = "";
                            for (var j = 0; j < parts.length; j++) {
                                if (parts[j].type === "text") {
                                    textContent += parts[j].text || "";
                                }
                            }

                            var timestamp = Date.now();
                            if (info.time && info.time.created) {
                                timestamp = info.time.created;
                            } else if (typeof info.time === "number") {
                                timestamp = info.time;
                            }

                            var messageData = {
                                id: info.id || "",
                                role: info.role || "user",
                                content: textContent,
                                timestamp: timestamp
                            };
                            root.messages.push(messageData);
                            messagesModel.append(messageData);
                        }
                        root.messages = root.messages.slice(); // Trigger change
                    } catch (e) {
                        console.error("Failed to parse messages:", e);
                    }
                }
            }
        };
        xhr.open("GET", baseUrl + "/session/" + root.sessionId + "/message");
        xhr.send();
    }

    // Stream handling
    property var eventStream: null
    property int lastReadPos: 0
    property string eventBuffer: ""
    property var pendingMsgIds: ({}) // Track our own messages to avoid duplicates

    function connectEventStream() {
        if (eventStream) return;

        console.log("Connecting to event stream...");
        eventStream = new XMLHttpRequest();
        eventStream.onreadystatechange = function() {
            if (eventStream.readyState === 3 || eventStream.readyState === 4) {
                if (eventStream.status === 200) {
                    var newText = eventStream.responseText.substring(lastReadPos);
                    lastReadPos = eventStream.responseText.length;
                    processStreamData(newText);
                }
            }
            
            if (eventStream.readyState === 4) {
                console.log("Event stream disconnected");
                eventStream = null;
                lastReadPos = 0;
                eventBuffer = "";
                reconnectTimer.start();
            }
        };
        eventStream.open("GET", baseUrl + "/global/event");
        eventStream.send();
    }
    
    function processStreamData(text) {
        eventBuffer += text;
        var messages = eventBuffer.split("\n\n");
        eventBuffer = messages.pop();
        
        for (var i = 0; i < messages.length; i++) {
            parseSSE(messages[i]);
        }
    }
    
    function parseSSE(msg) {
        var lines = msg.split("\n");
        var data = "";
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.startsWith("data:")) {
                data = line.substring(5).trim();
            }
        }
        
        if (data) {
            try {
                var json = JSON.parse(data);
                handleGlobalEvent(json);
            } catch (e) {
                console.error("Failed to parse SSE data:", e);
            }
        }
    }
    
    function handleGlobalEvent(evt) {
        if (!evt.payload) return;
        
        var payload = evt.payload;
        var type = payload.type;
        var props = payload.properties;
        
        if (type === "message.part.updated") {
            handleMessagePart(props);
        } else if (type === "message.updated") {
            handleMessageUpdate(props);
        }
    }
    
    function handleMessagePart(props) {
        var part = props.part;
        var delta = props.delta;
        
        if (!part || part.sessionID !== root.sessionId) return;
        if (part.type !== "text") return;
        
        var msgId = part.messageID;
        var updated = false;
        
        for (var i = 0; i < messagesModel.count; i++) {
            var item = messagesModel.get(i);
            if (item.id === msgId) {
                if (delta) {
                    var newContent = item.content + delta;
                    messagesModel.setProperty(i, "content", newContent);
                    if (root.messages[i]) root.messages[i].content = newContent;
                    root.messageStreamUpdated();
                }
                updated = true;
                break;
            }
        }
        
        if (!updated && delta) {
             var newMsg = {
                 id: msgId,
                 role: "assistant",
                 content: delta,
                 timestamp: Date.now()
             };
             messagesModel.append(newMsg);
             root.messages.push(newMsg);
             root.messages = root.messages.slice();
        }
    }
    
    function handleMessageUpdate(props) {
        var info = props.info;
        if (!info || info.sessionID !== root.sessionId) return;
        
        // Ignore our own pending messages if they come back
        if (pendingMsgIds[info.id]) return;
        
        if (info.role === "assistant") {
            var found = false;
            for (var i = 0; i < messagesModel.count; i++) {
                 if (messagesModel.get(i).id === info.id) {
                     found = true;
                     break;
                 }
            }
            
            if (!found) {
                var newMsg = {
                    id: info.id,
                    role: "assistant",
                    content: "",
                    timestamp: info.time ? (info.time.created || Date.now()) : Date.now()
                };
                messagesModel.append(newMsg);
                root.messages.push(newMsg);
                root.messages = root.messages.slice();
            }
            
            if (info.finish) {
                root.loading = false;
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        onTriggered: connectEventStream()
    }

    // Send a prompt message
    function sendMessage(text) {
        if (!root.sessionId || !text.trim())
            return;

        root.loading = true;
        root.error = "";

        var tempId = "pending_user_" + Date.now();
        var userMsg = {
            id: tempId,
            role: "user",
            content: text,
            timestamp: Date.now()
        };
        
        pendingMsgIds[tempId] = true;
        root.messages.push(userMsg);
        messagesModel.append(userMsg);
        root.messages = root.messages.slice();

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 204) {
                    // Success, wait for events
                } else {
                    root.loading = false;
                    root.error = "Failed to send message: " + xhr.status;
                    console.error("Send message failed:", xhr.status, xhr.responseText);
                }
            }
        };

        xhr.open("POST", baseUrl + "/session/" + root.sessionId + "/prompt_async");
        xhr.setRequestHeader("Content-Type", "application/json");

        var body = {
            parts: [
                {
                    type: "text",
                    text: text
                }
            ]
        };

        if (root.selectedAgent) {
            var agentExists = false;
            for (var i = 0; i < root.availableAgents.length; i++) {
                var a = root.availableAgents[i];
                if ((a.name || a.id) === root.selectedAgent) {
                    agentExists = true;
                    break;
                }
            }
            if (agentExists) {
                body.agent = root.selectedAgent;
            }
        }
        
        if (root.selectedProvider && root.selectedModel) {
            body.model = {
                providerID: root.selectedProvider,
                modelID: root.selectedModel
            };
        }

        xhr.send(JSON.stringify(body));
    }


    // Abort current request
    function abort() {
        if (!root.sessionId)
            return;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", baseUrl + "/session/" + root.sessionId + "/abort");
        xhr.send();
        root.loading = false;
    }

    // Clear and reset
    function reset() {
        messagesModel.clear();
        root.messages = [];
        root.sessionId = "";
        root.sessionTitle = "";
        root.error = "";
        root.loading = false;
    }

    // Initialize
    function init() {
        binaryCheckProcess.running = true
        checkHealth();
        loadProviders();
        loadAgents();
        connectEventStream();
    }

    Component.onDestruction: {
        if (eventStream) {
            eventStream.abort();
        }
    }
    
    Component.onCompleted: {
        // Load persistent settings if available
        if (Config.lastChatAgent) root.selectedAgent = Config.lastChatAgent;
        if (Config.lastChatProvider) root.selectedProvider = Config.lastChatProvider;
        if (Config.lastChatModel) root.selectedModel = Config.lastChatModel;
        
        // Delay init to avoid startup race
        Qt.callLater(init);
    }
    
    // Persist changes
    onSelectedAgentChanged: Config.lastChatAgent = selectedAgent
    onSelectedProviderChanged: Config.lastChatProvider = selectedProvider
    onSelectedModelChanged: Config.lastChatModel = selectedModel
    
    // Check if opencode binary exists
    Process {
        id: binaryCheckProcess
        command: ["which", "opencode"]
        onExited: (code) => {
            root.binaryAvailable = (code === 0)
            root.dependencyChecked = true
        }
    }
}
