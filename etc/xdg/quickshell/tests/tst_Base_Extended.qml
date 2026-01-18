import QtQuick 2.15
import "framework"
import "wrappers/base"

SimpleTest {
    name: "BaseComponentsExtended"
    
    // StatusButton Test
    StatusButton {
        id: statusBtn
        fillPercentage: 50
        fillColor: "#00ff00"
        icon: "X"
    }
    
    // CarouselView Test
    // Needs a model and delegate
    CarouselView {
        id: carousel
        width: 400
        height: 200
        model: ["A", "B", "C"]
        cardWidth: 100
        cardHeight: 50
        
        delegate: Rectangle {
            required property var modelData
            width: 100
            height: 50
            color: modelData == "B" ? "red" : "blue"
        }
    }
    
    // SelectionCarousel is harder to test in this headless/mock environment 
    // because it uses Quickshell.Wayland (PanelWindow, etc) which are hard to mock correctly
    // unless we mock Scope, Variants, PanelWindow entirely.
    // Given scope of "unit tests", testing CarouselView logic covers most of it.
    
    function test_statusbutton() {
        verify(statusBtn.width > 0, "StatusButton loaded")
        compare(statusBtn.fillPercentage, 50, "Fill percentage")
        compare(statusBtn.icon, "X", "Icon set")
    }
    
    function test_carousel_logic() {
        verify(carousel.count === 3, "Carousel count")
        
        // Test navigation logic
        var startIdx = carousel.currentIndex
        carousel.incrementCurrentIndex()
        verify(carousel.currentIndex !== startIdx, "Index changed after increment")
    }
}
