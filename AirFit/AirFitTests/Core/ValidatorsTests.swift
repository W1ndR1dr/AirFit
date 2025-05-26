@testable import AirFit
import Testing

struct ValidatorsTests {
    @Test func test_validateEmail() {
        #expect(Validators.validateEmail("test@example.com").isValid)
        #expect(!Validators.validateEmail("bademail").isValid)
    }

    @Test func test_validatePassword() {
        #expect(!Validators.validatePassword("short").isValid)
        #expect(Validators.validatePassword("verysecurepassword").isValid)
    }
}
