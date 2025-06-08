import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ChatSuggestionsEngineTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContext: ModelContext!
    private var user: User!
    private var engine: ChatSuggestionsEngine!

    // MARK: - Setup
    override func setUp() {
        super.setUp()
        
        // Create test container
        container = DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try! container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        user = User(email: "test@example.com", name: "Test User")
        modelContext.insert(user)
        try! modelContext.save()
        
        // Create engine
        engine = ChatSuggestionsEngine(user: user)
    }
    
    override func tearDown() {
        engine = nil
        user = nil
        modelContext = nil
        container = nil
        super.tearDown()
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
