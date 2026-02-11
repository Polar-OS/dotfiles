import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    // We expose left/right for masonry layout
    property var categoriesLeft: []
    property var categoriesRight: []
    property string collectedConfig: ""
    
    function load() {
        collectedConfig = "";
        reader.running = false;
        
        checkConfig.running = true;
    }
    
    Process {
        id: checkConfig
        command: ["sh", "-c", "ls ${XDG_CONFIG_HOME:-$HOME/.config}/niri/*.kdl >/dev/null 2>&1"]
        
        onExited: (code) => {
            if (code === 0) {
                reader.running = true;
            } else {
                // No config found
                var errorCat = {
                    name: "Missing Configuration",
                    binds: [{
                        keys: "Error",
                        action: "No Niri config found in ~/.config/niri/*.kdl",
                        rawAction: "true"
                    }]
                };
                root.categoriesLeft = [errorCat];
                root.categoriesRight = [];
            }
        }
    }
    
    function parseConfig(fullConfig) {
        var lines = fullConfig.split("\n");
        var insideBinds = false;
        var currentCategory = "General";
        var depth = 0;
        
        var categoryMap = {};
        var categoryOrder = [];
        
        function addBind(cat, keys, action, raw) {
            if (!categoryMap[cat]) {
                categoryMap[cat] = [];
                categoryOrder.push(cat);
            }
            categoryMap[cat].push({
                "keys": keys,
                "action": action,
                "rawAction": raw
            });
        }
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            
            // Check for binds block start
            if (line.startsWith("binds {") || line === "binds {") {
                insideBinds = true;
                depth = 1;
                continue;
            }
            
            if (!insideBinds) continue;
            
            if (line.includes("{")) depth += (line.match(/\{/g) || []).length;
            if (line.includes("}")) depth -= (line.match(/\}/g) || []).length;
            
            if (depth === 0) {
                insideBinds = false;
                continue;
            }
            
            if (line.startsWith("//") && !line.startsWith("///")) {
                var category = line.substring(2).trim();
                if (category.length > 0 && 
                    !category.includes(";") && 
                    !category.includes("{") && 
                    !category.includes("=") &&
                    !category.includes("sway") && 
                    !category.includes("i3")) {
                     currentCategory = category;
                }
                continue;
            }
            
            if (line.startsWith("/") || line === "") continue;
            
            var openBrace = line.indexOf("{");
            var closeBrace = line.lastIndexOf("}");
            
            if (openBrace > -1 && closeBrace > openBrace) {
                var beforeBrace = line.substring(0, openBrace).trim();
                var actionBody = line.substring(openBrace + 1, closeBrace).trim();
                
                var description = "";
                var titleMatch = beforeBrace.match(/hotkey-overlay-title="([^"]*)"/);
                if (titleMatch) {
                    description = titleMatch[1];
                    
                    // Extract category from title if present (e.g. "App: Terminal")
                    if (description.includes(":")) {
                        var parts = description.split(":");
                        var cat = parts[0].trim();
                        if (cat.length > 0 && cat.length < 30) {
                            currentCategory = cat;
                            description = parts.slice(1).join(":").trim();
                        }
                    }
                }
                
                var keysPart = beforeBrace.replace(/hotkey-overlay-title="[^"]*"/, "").trim();
                keysPart = keysPart.replace(/\w+=[^ ]+/, "").trim();
                var keys = keysPart;
                
                if (description === "") {
                    var cleanAction = actionBody;
                    
                    // Auto-categorize based on action if no category/title provided
                    if (cleanAction.includes("focus-") || cleanAction.includes("move-column") || cleanAction.includes("move-window")) {
                        currentCategory = "Navigation";
                    } else if (cleanAction.includes("workspace")) {
                        currentCategory = "Workspaces";
                    } else if (cleanAction.includes("maximize") || cleanAction.includes("fullscreen") || cleanAction.includes("close-window")) {
                        currentCategory = "Window";
                    } else if (cleanAction.includes("column-width") || cleanAction.includes("window-height") || cleanAction.includes("consume") || cleanAction.includes("expel")) {
                        currentCategory = "Layout";
                    } else if (cleanAction.includes("wpctl") || cleanAction.includes("playerctl") || cleanAction.includes("Audio")) {
                        currentCategory = "Audio";
                    } else if (cleanAction.includes("brightnessctl") || cleanAction.includes("MonBrightness")) {
                        currentCategory = "Brightness";
                    } else if (cleanAction.includes("screenshot")) {
                        currentCategory = "Screenshot";
                    }
                    
                    cleanAction = cleanAction.replace(/^spawn-sh\s+"?/, "").replace(/"?;?$/, "");
                    cleanAction = cleanAction.replace(/^uwsm\s+app\s+--\s+/, "");
                    
                    cleanAction = cleanAction.split('-').map(word => {
                        return word.charAt(0).toUpperCase() + word.slice(1);
                    }).join(' ');
                    
                    description = cleanAction;
                }
                
                var commandToRun = "";
                if (actionBody.includes("spawn-sh")) {
                     var cmdMatch = actionBody.match(/spawn-sh\s+"(.*)"/);
                     if (cmdMatch) {
                         commandToRun = cmdMatch[1];
                     }
                } else {
                    var internalAction = actionBody.replace(/;$/, "").trim();
                    commandToRun = "niri msg action " + internalAction;
                }

                addBind(currentCategory, keys.replace(/Mod/g, "Super"), description, commandToRun);
            }
        }
        
        var left = [];
        var right = [];
        var leftCount = 0;
        var rightCount = 0;
        
        // Balanced split: add next category to the shorter column
        for (var k = 0; k < categoryOrder.length; k++) {
            var catName = categoryOrder[k];
            var binds = categoryMap[catName];
            var obj = {
                name: catName,
                binds: binds
            };
            
            // Weight is title (1) + number of binds
            var weight = 1 + binds.length;
            
            if (leftCount <= rightCount) {
                left.push(obj);
                leftCount += weight;
            } else {
                right.push(obj);
                rightCount += weight;
            }
        }
        
        console.log("ConfigParser: Split " + categoryOrder.length + " categories into " + left.length + " left / " + right.length + " right.");
        
        root.categoriesLeft = left;
        root.categoriesRight = right;
    }
    
    Process {
        id: reader
        command: ["sh", "-c", "cat ${XDG_CONFIG_HOME:-$HOME/.config}/niri/*.kdl"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.collectedConfig += data;
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.parseConfig(root.collectedConfig);
            }
        }
    }
}
