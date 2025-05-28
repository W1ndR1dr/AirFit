import XCTest
@testable import AirFit

@MainActor
final class ChatSuggestionsEngineTests: XCTestCase {
    var user: User!
    var engine: ChatSuggestionsEngine!

    override func setUp() async throws {
        user = User()
        engine = ChatSuggestionsEngine(user: user)
    }

    func test_generateSuggestions_withoutHistory_returnsDefaultPrompts() async {
        let result = await engine.generateSuggestions(messages: [], userContext: user)
        XCTAssertGreaterThanOrEqual(result.quick.count, 4)
    }

    func test_generateSuggestions_workoutMessage_includesWorkoutSuggestion() async {
        let message = ChatMessage(role: "user", content: "I did a hard workout", session: nil)
        let result = await engine.generateSuggestions(messages: [message], userContext: user)
        XCTAssertTrue(result.quick.contains { $0.text.contains("workout") })
    }
}
