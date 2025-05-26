@testable import AirFit
import Testing

struct AppConstantsTests {
    @Test func test_layout_constants() {
        #expect(AppConstants.Layout.defaultPadding == 16)
        #expect(AppConstants.Layout.largeCornerRadius == 20)
    }

    @Test func test_validation_limits() {
        #expect(AppConstants.Validation.minPasswordLength == 8)
        #expect(AppConstants.Validation.maxWeight == 300)
    }
}
