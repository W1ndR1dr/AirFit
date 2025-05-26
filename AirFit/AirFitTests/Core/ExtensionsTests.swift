@testable import AirFit
import SwiftUI
import Testing

struct ExtensionsTests {
    @Test
    func test_kilogramsToPounds() {
        let pounds = 10.0.kilogramsToPounds
        #expect((pounds - 22.0462).magnitude < 0.001)
    }

    @Test
    func test_colorHex() {
        let color = Color(hex: "FF0000")
        #expect(color != Color.clear)
    }
}
