import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Io

Scope {
    id: root

    // Signals
    signal unlocked
    signal failed

    // Lockscreen active state - controls whether surfaces are shown
    property bool active: false

    // Shared state across all lock surfaces
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Internal state
    property bool _submittingPassword: false

    // Force fingerprint attempt (for debugging/testing)
    property bool tryFingerprint: true

    // Fingerprint state
    property bool fingerprintScanning: false
    property bool fingerprintSuccess: false
    
    // Dependency check
    property bool pamConfigAvailable: false
    property bool dependencyChecked: false
    property string configError: ""
    
    Process {
        id: checkPamConfig
        // Check if password.conf exists in expected location
        // Quickshell looks in <config>/pam/
        command: ["sh", "-c", "test -f ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/pam/password.conf"]
        onExited: (code) => {
            root.pamConfigAvailable = (code === 0);
            root.dependencyChecked = true;
            if (!root.pamConfigAvailable) {
                root.configError = "Missing PAM config: ~/.config/quickshell/pam/password.conf";
                console.error(root.configError);
                // If active, show failure immediately
                if (root.active) {
                    root.showFailure = true;
                }
            }
        }
    }
    
    Component.onCompleted: {
        checkPamConfig.running = true;
    }

    onActiveChanged: {
        console.log("Context: active changed to", active);
        if (active) {
            currentText = "";
            unlockInProgress = false;
            showFailure = !pamConfigAvailable && dependencyChecked; // Show failure if config missing
            fingerprintSuccess = false;
            _submittingPassword = false;

            // Start fingerprint scan if enabled
            if (root.tryFingerprint) {
                console.log("Context: Starting fingerprint scan...");
                fingerprintPam.active = true;
            }
        } else {
            passwordPam.active = false;
            fingerprintPam.active = false;
            restartTimer.stop();
        }
    }

    onCurrentTextChanged: {
        if (showFailure) {
            console.log("Context: User typing, clearing failure state");
            showFailure = false;
        }
    }

    function tryUnlock() {
        if (!active)
            return;

        if (currentText.length > 0) {
            console.log("Context: tryUnlock() called with password. Submitting...");
            _submittingPassword = true;
            unlockInProgress = true;
            passwordPam.active = true;
        } else {
            console.log("Context: tryUnlock() called with empty text. Ensuring fingerprint is active.");
            if (!fingerprintPam.active && root.tryFingerprint) {
                fingerprintPam.active = true;
            }
        }
    }

    IpcHandler {
        target: "ui.overlay.lockscreen"
        function lock(): void {
            root.active = true;
        }
        function open(): void {
            root.active = true;
        }
        function unlock(): void {
            console.log("Context: unlock() via IPC disabled for security");
        }
        function close(): void {
            console.log("Context: close() via IPC disabled for security");
        }
        function toggle(): void {
            root.active = !root.active;
        }
    }

    // --- PASSWORD AUTHENTICATION ---
    PamContext {
        id: passwordPam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            console.log("Password PAM Msg:", this.message, "| Req:", this.responseRequired);
            if (this.responseRequired) {
                if (root._submittingPassword) {
                    console.log("Password PAM: Responding with currentText");
                    this.respond(root.currentText);
                    root._submittingPassword = false;
                } else {
                    console.log("Password PAM: Response required but not submitting. Waiting.");
                }
            }
        }

        onCompleted: result => {
            console.log("Password PAM Completed. Result:", result);
            if (result == PamResult.Success) {
                console.log("Password Unlock SUCCESS!");
                root.active = false;
                root.unlocked();
                fingerprintPam.active = false;
            } else {
                console.log("Password auth failed.");
                root.currentText = "";
                root.showFailure = true;
                root.unlockInProgress = false;
                root._submittingPassword = false;
                passwordPam.active = false;
            }
        }
    }

    // --- FINGERPRINT AUTHENTICATION ---
    PamContext {
        id: fingerprintPam
        configDirectory: "pam"
        config: "fingerprint.conf"

        onPamMessage: {
            console.log("Fingerprint PAM Msg:", this.message, "| Req:", this.responseRequired);
            root.fingerprintScanning = true;

            if (this.responseRequired) {
                // Respond with empty string to keep the scan going
                // This is required by some versions of pam_fprintd
                console.log("Fingerprint PAM: Sending empty response");
                this.respond("");
            }
        }

        onCompleted: result => {
            console.log("Fingerprint PAM Completed. Result:", result);
            if (result == PamResult.Success) {
                console.log("Fingerprint Unlock SUCCESS!");
                root.fingerprintSuccess = true;
                root.fingerprintScanning = false;
                root.active = false;
                root.unlocked();
                passwordPam.active = false;
            } else {
                console.log("Fingerprint failed/timeout/mismatch.");
                root.fingerprintScanning = false;
                if (root.active && root.tryFingerprint) {
                    // Only restart if no password is being submitted
                    if (!root.unlockInProgress) {
                        restartTimer.start();
                    }
                }
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 1000 // Slower restart to avoid tight loop
        onTriggered: {
            if (root.active && !root.unlockInProgress && root.tryFingerprint) {
                console.log("Context: Restarting fingerprint scan...");
                fingerprintPam.active = true;
            }
        }
    }
}
