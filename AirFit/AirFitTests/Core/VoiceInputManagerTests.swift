import XCTest
@testable import AirFit

final class VoiceInputManagerTests: XCTestCase {
    func test_errorDescriptions_shouldMatch() {
        XCTAssertEqual(VoiceInputError.notAuthorized.errorDescription, "Microphone access not authorized")
        XCTAssertEqual(VoiceInputError.whisperInitializationFailed.errorDescription, "Failed to initialize Whisper model")
    }
}
