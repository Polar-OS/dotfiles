import QtQuick 2.0
Item {
    // Attached properties must be defined in C++ or via `QtObject` attached logic, which is hard to mock in pure QML
    // However, if we define it as a component, we can use it as `WlrLayershell { ... }` but attached properties `WlrLayershell.layer` are tricky.
    // QML Mocking of attached properties is limited.
    // But since it's a mock, we can perhaps ignore it if the parent component (PanelWindow) doesn't use it?
    // Wait, `delegate: PanelWindow` uses it inside.
    
    // We can define attached properties if we assume `WlrLayershell` is the type providing them.
    // In QML, `Type.property` syntax looks for attached object.
    
    // Mocking attached properties in pure QML is not directly supported for custom types easily without C++.
    // BUT `WlrLayershell` is imported from `Quickshell.Wayland`.
    
    // A workaround: Since we are copying files to `wrappers`, we can comment out these lines in `wrappers/logout/Logout.qml`.
    // That's safer than trying to mock complex attached properties.
}
