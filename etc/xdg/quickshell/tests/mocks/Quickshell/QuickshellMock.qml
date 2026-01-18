pragma Singleton
import QtQuick 2.0
Item {
    property string shellDir: "/tmp/test_shell_dir"
    function env(name) {
        if (name === "HOME") return "/tmp/test_home";
        if (name === "XDG_CONFIG_HOME") return "/tmp/test_config";
        return "";
    }
}
