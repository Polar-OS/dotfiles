import QtQuick 2.15
import "framework"
import "wrappers/status"

// Need to import mock dependencies
import Quickshell.Bluetooth 1.0
import Quickshell.Io 1.0

SimpleTest {
    name: "ConnectivityManager"
    
    // WifiManager
    WifiManager {
        id: wifiMgr
        width: 300
        height: 500
        // Need to provide dummy data or ensure Process is mocked properly
    }

    // BluetoothManager
    BluetoothManager {
        id: btMgr
        width: 300
        height: 500
    }

    function test_wifi_init() {
        verify(wifiMgr.width > 0, "WiFi Manager loaded")
        // WifiManager uses Process, which is mocked.
        // It tries to run `nmcli radio wifi` on init.
        // Mock returns "enabled" by default if implemented in Process.qml
        // We can check if it attempted to run
    }
    
    function test_bluetooth_load() {
        verify(btMgr.width > 0, "Bluetooth Manager loaded")
        // Check default adapter state from mock
        verify(Bluetooth.defaultAdapter.enabled, "Adapter enabled by default mock")
    }
}
