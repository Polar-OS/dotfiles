import QtQuick 2.15
import "framework"
import "wrappers/status"
import "wrappers/media"
import Quickshell.Services.UPower 1.0
import Quickshell.Services.Pipewire 1.0

SimpleTest {
    name: "StatusComponents"

    BatteryIndicator {
        id: battery
    }
    
    VolumeBar {
        id: volume
    }

    function test_battery() {
        verify(battery.width > 0, "Battery has width")
    }

    function test_volume() {
        console.error("Test Pipewire Volume: " + Pipewire.defaultAudioSink.audio.volume)
        console.error("VolumeBar Value: " + volume.value)
        compare(volume.value, 0.4, "VolumeBar value matches sink volume")
    }
}
