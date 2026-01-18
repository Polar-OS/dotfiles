import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../ui/layout"
import "../../../../ui/button"
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../../ui/panel"
import "../../../../config"

ColumnLayout {
    Layout.fillWidth: true
    spacing: 15
    
    property bool profilesAvailable: typeof PowerProfiles !== "undefined"
    
    property alias firstButton: performanceBtn
    property alias lastButton: powerSaverBtn

    SectionSeparator {
        title: "Scaling Mode"
        visible: profilesAvailable
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 15
        visible: profilesAvailable

        QuickButton {
            id: performanceBtn
            size: 32
            icon: "󰓅"
            
            enabled: profilesAvailable && PowerProfiles.hasPerformanceProfile
            opacity: enabled ? 1.0 : 0.5
            
            active: profilesAvailable && PowerProfiles.profile === PowerProfile.Performance
            
            onClicked: {
                if (profilesAvailable && PowerProfiles.hasPerformanceProfile) {
                    PowerProfiles.profile = PowerProfile.Performance;
                }
            }
            
            KeyNavigation.right: balancedBtn
        }

        QuickButton {
            id: balancedBtn
            size: 32
            icon: "󰗑" 
            active: profilesAvailable && PowerProfiles.profile === PowerProfile.Balanced
            onClicked: {
                if (profilesAvailable) {
                    PowerProfiles.profile = PowerProfile.Balanced;
                }
            }
            
            KeyNavigation.left: performanceBtn
            KeyNavigation.right: powerSaverBtn
        }

        QuickButton {
            id: powerSaverBtn
            size: 32
            icon: "󰌪"
            active: profilesAvailable && PowerProfiles.profile === PowerProfile.PowerSaver
            onClicked: {
                if (profilesAvailable) {
                    PowerProfiles.profile = PowerProfile.PowerSaver;
                }
            }
            
            KeyNavigation.left: balancedBtn
        }
    }
}
