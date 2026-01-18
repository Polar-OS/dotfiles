#!/bin/bash
rm -rf tests/wrappers
mkdir -p tests/wrappers/base tests/wrappers/lock tests/wrappers/logout tests/wrappers/workspaces tests/wrappers/status tests/wrappers/notifications tests/wrappers/launcher tests/wrappers/system tests/wrappers/pomodoro tests/wrappers/voice tests/wrappers/media

cp components/ui/panel/*.qml tests/wrappers/base/
cp components/ui/button/*.qml tests/wrappers/base/
cp components/ui/carousel/*.qml tests/wrappers/base/
cp components/ui/layout/*.qml tests/wrappers/base/
ls tests/wrappers/base/*.qml 2>/dev/null | sed 's|.*/||;s|\.qml||' | while read f; do echo "$f 1.0 $f.qml"; done > tests/wrappers/base/qmldir

cp components/shell/panel/message/system/*.qml tests/wrappers/system/
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/system/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/system/*.qml
ls tests/wrappers/system/*.qml 2>/dev/null | sed 's|.*/||;s|\.qml||' | while read f; do echo "$f 1.0 $f.qml"; done > tests/wrappers/system/qmldir

cp components/shell/panel/message/pomodoro/*.qml tests/wrappers/pomodoro/
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/pomodoro/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/pomodoro/*.qml
echo -e "Pomodoro 1.0 Pomodoro.qml\nPomodoroOverlay 1.0 PomodoroOverlay.qml" > tests/wrappers/pomodoro/qmldir

cp components/shell/panel/message/voice/*.qml tests/wrappers/voice/ 2>/dev/null || mkdir -p tests/wrappers/voice
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/voice/*.qml 2>/dev/null
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/voice/*.qml 2>/dev/null
ls tests/wrappers/voice/*.qml 2>/dev/null | sed 's|.*/||;s|\.qml||' | while read f; do echo "$f 1.0 $f.qml"; done > tests/wrappers/voice/qmldir 2>/dev/null

cp components/shell/panel/status/media/*.qml tests/wrappers/media/
sed -i 's/import Quickshell.Services.Mpris$/import Quickshell.Services.Mpris 1.0/' tests/wrappers/media/*.qml
sed -i 's/import Quickshell.Services.Pipewire$/import Quickshell.Services.Pipewire 1.0/' tests/wrappers/media/*.qml
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/media/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/media/*.qml
[ -f tests/wrappers/media/MprisController.qml ] && sed -i '1i import Quickshell 1.0' tests/wrappers/media/MprisController.qml
ls tests/wrappers/media/*.qml 2>/dev/null | sed 's|.*/||;s|\.qml||' | while read f; do echo "$f 1.0 $f.qml"; done > tests/wrappers/media/qmldir

cp components/shell/panel/status/*.qml tests/wrappers/status/
sed -i 's/import Quickshell.Services.Pipewire$/import Quickshell.Services.Pipewire 1.0/' tests/wrappers/status/*.qml
sed -i 's/import Quickshell.Services.UPower$/import Quickshell.Services.UPower 1.0/' tests/wrappers/status/*.qml
sed -i 's/import Quickshell.Services.Mpris$/import Quickshell.Services.Mpris 1.0/' tests/wrappers/status/*.qml
[ -f tests/wrappers/status/MprisController.qml ] && sed -i "1i import Quickshell 1.0" tests/wrappers/status/MprisController.qml
sed -i 's/import Quickshell.Bluetooth$/import Quickshell.Bluetooth 1.0/' tests/wrappers/status/*.qml
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/status/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/status/*.qml

cp components/shell/panel/message/*.qml tests/wrappers/notifications/
sed -i 's/import Quickshell.Services.Notifications$/import Quickshell.Services.Notifications 1.0/' tests/wrappers/notifications/*.qml
sed -i 's/import Quickshell.Services.SystemTray$/import Quickshell.Services.SystemTray 1.0/' tests/wrappers/notifications/*.qml
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/notifications/*.qml
sed -i 's/import Quickshell.Services.UPower$/import Quickshell.Services.UPower 1.0/' tests/wrappers/notifications/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/notifications/*.qml
sed -i 's/NotificationUrgency.Critical/2/g' tests/wrappers/notifications/*.qml
sed -i 's/NotificationUrgency.Normal/1/g' tests/wrappers/notifications/*.qml
sed -i 's/NotificationUrgency.Low/0/g' tests/wrappers/notifications/*.qml

cp components/shell/panel/launcher/*.qml tests/wrappers/launcher/
sed -i 's/import Quickshell.Io$/import Quickshell.Io 1.0/' tests/wrappers/launcher/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/launcher/*.qml

cp tests/Config.qml tests/wrappers/
echo "singleton Config 1.0 Config.qml" > tests/wrappers/qmldir

cp components/shell/overlay/lock/*.qml tests/wrappers/lock/
sed -i 's/import Quickshell.Services.Pam$/import Quickshell.Services.Pam 1.0/' tests/wrappers/lock/*.qml
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/lock/*.qml

cp components/shell/overlay/logout/*.qml tests/wrappers/logout/
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/logout/*.qml

cp components/shell/panel/workspace/*.qml tests/wrappers/workspaces/
sed -i 's/import Quickshell$/import Quickshell 1.0/' tests/wrappers/workspaces/*.qml
sed -i 's/import Quickshell.Wayland$/import Quickshell.Wayland 1.0/' tests/wrappers/logout/*.qml
sed -i 's/import Quickshell.Wayland$/import Quickshell.Wayland 1.0/' tests/wrappers/lock/*.qml
sed -i 's/WlrLayershell\./\/\/ WlrLayershell\./g' tests/wrappers/logout/Logout.qml
sed -i 's/exclusionMode:/\/\/ exclusionMode:/g' tests/wrappers/logout/Logout.qml
sed -i 's/WlrLayer.Overlay/WlrLayer.overlay/g' tests/wrappers/logout/Logout.qml
sed -i 's/WlrKeyboardFocus.Exclusive/WlrKeyboardFocus.exclusive/g' tests/wrappers/logout/Logout.qml
sed -i 's/top: true/\/\/ top: true/g' tests/wrappers/logout/Logout.qml
sed -i 's/bottom: true/\/\/ bottom: true/g' tests/wrappers/logout/Logout.qml
sed -i 's/left: true/\/\/ left: true/g' tests/wrappers/logout/Logout.qml
sed -i 's/right: true/\/\/ right: true/g' tests/wrappers/logout/Logout.qml
sed -i '1i import Quickshell.Wayland 1.0' tests/wrappers/lock/Lock.qml
sed -i '/anchors {/,/}/d' tests/wrappers/logout/Logout.qml
sed -i 's/config: "password.conf"/\/\/ config: "password.conf"/g' tests/wrappers/lock/LockContext.qml
sed -i 's/WlrLayershell\./\/\/ WlrLayershell\./g' tests/wrappers/lock/*.qml
sed -i 's/exclusionMode:/\/\/ exclusionMode:/g' tests/wrappers/lock/*.qml
sed -i '/anchors {/,/}/d' tests/wrappers/lock/*.qml
sed -i 's/model.isActive/modelData.isActive/g' tests/wrappers/workspaces/Workspaces.qml
sed -i 's/model.id/modelData.id/g' tests/wrappers/workspaces/Workspaces.qml

find tests/wrappers -name "*.qml" | while read f; do
    sed -i 's|import "../../../ui/panel"|import "../base"|g' "$f"
    sed -i 's|import "../../../../ui/panel"|import "../base"|g' "$f"
    sed -i 's|import "../../../config"|import ".."|g' "$f"
    sed -i 's|import "../../../../config"|import ".."|g' "$f"
    sed -i 's|import "../../config"|import ".."|g' "$f"
    sed -i 's|import "../system"|import "../system"|g' "$f"
    sed -i 's|import "../pomodoro"|import "../pomodoro"|g' "$f"
    sed -i 's|import "../voice"|import "../voice"|g' "$f"
    sed -i 's|import "../media"|import "../media"|g' "$f"
done

sed -i 's|import "../components"|import "../../components"|g' tests/wrappers/Config.qml
sed -i 's|import "../components/theme"|import "../../components/theme"|g' tests/wrappers/Config.qml
