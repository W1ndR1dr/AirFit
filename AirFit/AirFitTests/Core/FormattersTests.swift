@testable import AirFit
import Testing

struct FormattersTests {
    @Test
    func test_formatCalories() {
        let result = Formatters.formatCalories(150.0)
        #expect(result == "150 cal")
    }

    @Test
    func test_formatWeight_metric() {
        let result = Formatters.formatWeight(70)
        #expect(result.contains("kg"))
    }

    @Test
    func test_formatWeight_imperial() {
        let result = Formatters.formatWeight(70, unit: .imperial)
        #expect(result.contains("lbs"))
    }
}
