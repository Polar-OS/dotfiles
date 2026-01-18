import QtQuick 2.15
import "framework"
import "wrappers/launcher"

SimpleTest {
    name: "LauncherExtended"

    // Test Providers
    // Providers are typically Items or QtObjects
    // ChatProvider, MenuProvider, etc.
    // They are instantiated in Launcher.qml or used as Singletons?
    // In components/launcher, they are files like `ChatProvider.qml`.
    
    // We can instantiate them to check if they load and initialize
    
    ChatProvider {
        id: chatProvider
        // Needs mocking process?
    }
    
    MenuProvider {
        id: menuProvider
    }
    
    SessionProvider {
        id: sessionProvider
    }
    
    LauncherSearchBar {
        id: searchBar
        width: 300
        height: 50
    }

    function test_providers_load() {
        verify(chatProvider, "ChatProvider loaded")
        verify(menuProvider, "MenuProvider loaded")
        verify(sessionProvider, "SessionProvider loaded")
    }
    
    function test_searchbar() {
        verify(searchBar.width > 0, "SearchBar loaded")
        searchBar.text = "Test"
        compare(searchBar.text, "Test", "Text input works")
    }
}
