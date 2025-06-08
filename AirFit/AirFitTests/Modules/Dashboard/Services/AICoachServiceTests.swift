import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class AICoachServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: AICoachService!
    private var mockCoachEngine: MockCoachEngine!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Get mock from container
        mockCoachEngine = try await container.resolve(CoachEngineProtocol.self) as? MockCoachEngine
        XCTAssertNotNil(mockCoachEngine, "Expected MockCoachEngine from test container")
        
        // Create service with injected dependencies
        sut = AICoachService(coachEngine: mockCoachEngine)
    }
    
    override func tearDown() async throws {
        mockCoachEngine?.reset()
        sut = nil
        mockCoachEngine = nil
        container = nil
        modelContext = nil
        testUser = nil
        try super.tearDown()
    }
    
    // MARK: - Basic Greeting Tests
    
    func test_generateMorningGreeting_withMinimalContext_returnsGreeting() async throws {
        // Arrange
        let context = GreetingContext(
            userName: testUser.name,
            dayOfWeek: "Monday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertEqual(greeting, "Good morning! Let's make today great.")
        XCTAssertEqual(mockCoachEngine.processMessageCalls.count, 1)
    }
    
    func test_generateMorningGreeting_withFullContext_buildsCompletePrompt() async throws {
        // Arrange
        let context = GreetingContext(
            userName: "Test User",
            sleepHours: 7.5,
            sleepQuality: "Good",
            weather: "Sunny, 22°C",
            temperature: 22.0,
            todaysSchedule: "Chest workout at 6 PM",
            energyYesterday: "High",
            dayOfWeek: "Tuesday",
            recentAchievements: ["5-day workout streak", "New PR on bench press"]
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertEqual(mockCoachEngine.processMessageCalls.count, 1)
        
        // Verify the prompt contains context elements
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Test User"))
        XCTAssertTrue(sentPrompt.contains("7.5 hours"))
        XCTAssertTrue(sentPrompt.contains("Sunny, 22°C"))
        XCTAssertTrue(sentPrompt.contains("Chest workout at 6 PM"))
    }
    
    func test_generateMorningGreeting_withSleepContext_includesSleepInfo() async throws {
        // Arrange
        let context = GreetingContext(
            userName: testUser.name,
            sleepHours: 5.2,
            sleepQuality: "Poor",
            dayOfWeek: "Wednesday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("5.2 hours"))
    }
    
    func test_generateMorningGreeting_withWeatherContext_includesWeather() async throws {
        // Arrange
        let context = GreetingContext(
            userName: testUser.name,
            weather: "Rainy, 15°C",
            temperature: 15.0,
            dayOfWeek: "Thursday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Rainy, 15°C"))
    }
    
    func test_generateMorningGreeting_withScheduleContext_includesSchedule() async throws {
        // Arrange
        let context = GreetingContext(
            userName: testUser.name,
            todaysSchedule: "Morning run, then leg day workout",
            dayOfWeek: "Friday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Morning run, then leg day workout"))
    }
    
    // MARK: - Persona Integration Tests
    
    func test_generateMorningGreeting_withCoachPersona_includesPersonaContext() async throws {
        // Arrange
        let persona = CoachPersona(
            id: UUID(),
            name: "Coach Mike",
            communicationStyle: .supportive,
            motivationApproach: .positive,
            expertiseFocus: .strength,
            personalityTraits: ["Encouraging", "Detail-oriented"],
            backgroundStory: "Former athlete turned coach",
            typicalPhrases: ["Let's crush it!", "You've got this!"],
            responsePatterns: [:],
            preferredGreetings: ["Rise and shine, champion!"],
            createdDate: Date()
        )
        let personaData = try JSONEncoder().encode(persona)
        testUser.coachPersonaData = personaData
        
        let context = GreetingContext(
            userName: testUser.name,
            dayOfWeek: "Saturday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("friendly and encouraging tone"))
    }
    
    func test_generateMorningGreeting_withNilUserName_stillGeneratesGreeting() async throws {
        // Arrange
        testUser.name = nil
        let context = GreetingContext(
            userName: "",
            dayOfWeek: "Sunday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("the user"))
    }
    
    // MARK: - Error Handling Tests
    
    func test_generateMorningGreeting_whenCoachEngineThrows_propagatesError() async throws {
        // Arrange
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = CoachEngineError.aiServiceUnavailable
        
        let context = GreetingContext(
            userName: testUser.name,
            dayOfWeek: "Monday"
        )
        
        // Act & Assert
        do {
            _ = try await sut.generateMorningGreeting(for: testUser, context: context)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? CoachEngineError, .aiServiceUnavailable)
        }
    }
    
    func test_generateMorningGreeting_withInvalidPersonaData_handlesGracefully() async throws {
        // Arrange
        testUser.coachPersonaData = Data("invalid json".utf8)
        let context = GreetingContext(
            userName: testUser.name,
            dayOfWeek: "Monday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        // Should still generate greeting even with invalid persona data
        XCTAssertEqual(greeting, "Good morning! Let's make today great.")
    }
    
    // MARK: - Edge Cases
    
    func test_generateMorningGreeting_withVeryLongContext_truncatesGracefully() async throws {
        // Arrange
        let veryLongSchedule = String(repeating: "Workout, ", count: 100)
        let context = GreetingContext(
            userName: testUser.name,
            todaysSchedule: veryLongSchedule,
            dayOfWeek: "Monday",
            recentAchievements: Array(repeating: "Achievement", count: 50)
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        // Verify it still processes without crashing
        XCTAssertEqual(mockCoachEngine.processMessageCalls.count, 1)
    }
    
    func test_generateMorningGreeting_withSpecialCharactersInName_handlesCorrectly() async throws {
        // Arrange
        testUser.name = "Test@User#123"
        let context = GreetingContext(
            userName: testUser.name,
            dayOfWeek: "Monday"
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Test@User#123"))
    }
    
    func test_generateMorningGreeting_withEmptyContext_stillGeneratesValidPrompt() async throws {
        // Arrange
        let context = GreetingContext()  // All defaults
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertEqual(mockCoachEngine.processMessageCalls.count, 1)
        
        // Verify basic prompt structure
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Generate a brief, personalized morning greeting"))
        XCTAssertTrue(sentPrompt.contains("Keep it under 2 sentences"))
    }
    
    // MARK: - Performance Tests
    
    func test_generateMorningGreeting_performance() async throws {
        // Arrange
        let context = GreetingContext(
            userName: testUser.name,
            sleepHours: 8.0,
            weather: "Sunny",
            todaysSchedule: "Workout day",
            dayOfWeek: "Monday"
        )
        
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sut.generateMorningGreeting(for: testUser, context: context)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 0.1, "Greeting generation should be fast")
    }
    
    func test_generateMorningGreeting_multipleCallsConcurrently_handlesCorrectly() async throws {
        // Arrange
        let contexts = (0..<5).map { i in
            GreetingContext(
                userName: "User \(i)",
                dayOfWeek: "Monday"
            )
        }
        
        // Act
        let greetings = await withTaskGroup(of: String?.self) { group in
            for (index, context) in contexts.enumerated() {
                group.addTask {
                    try? await self.sut.generateMorningGreeting(
                        for: self.testUser,
                        context: context
                    )
                }
            }
            
            var results: [String] = []
            for await greeting in group {
                if let greeting = greeting {
                    results.append(greeting)
                }
            }
            return results
        }
        
        // Assert
        XCTAssertEqual(greetings.count, 5)
        XCTAssertEqual(mockCoachEngine.processMessageCalls.count, 5)
        greetings.forEach { XCTAssertFalse($0.isEmpty) }
    }
    
    // MARK: - Integration Tests
    
    func test_generateMorningGreeting_withRealWorldScenario_monday() async throws {
        // Arrange - Monday morning, poor sleep, rainy day
        let context = GreetingContext(
            userName: "Alex",
            sleepHours: 5.5,
            sleepQuality: "Poor",
            weather: "Rainy, 10°C",
            temperature: 10.0,
            todaysSchedule: "Rest day",
            energyYesterday: "Low",
            dayOfWeek: "Monday",
            recentAchievements: []
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        // Verify all context is included
        XCTAssertTrue(sentPrompt.contains("Alex"))
        XCTAssertTrue(sentPrompt.contains("5.5 hours"))
        XCTAssertTrue(sentPrompt.contains("Rainy, 10°C"))
        XCTAssertTrue(sentPrompt.contains("Rest day"))
    }
    
    func test_generateMorningGreeting_withRealWorldScenario_friday() async throws {
        // Arrange - Friday morning, great sleep, nice weather, workout day
        let context = GreetingContext(
            userName: "Jordan",
            sleepHours: 8.2,
            sleepQuality: "Excellent",
            weather: "Sunny, 25°C",
            temperature: 25.0,
            todaysSchedule: "Back and biceps workout at 5:30 PM",
            energyYesterday: "High",
            dayOfWeek: "Friday",
            recentAchievements: ["10-day streak", "New deadlift PR"]
        )
        
        // Act
        let greeting = try await sut.generateMorningGreeting(for: testUser, context: context)
        
        // Assert
        XCTAssertFalse(greeting.isEmpty)
        let sentPrompt = mockCoachEngine.processMessageCalls.first?.message ?? ""
        XCTAssertTrue(sentPrompt.contains("Jordan"))
        XCTAssertTrue(sentPrompt.contains("8.2 hours"))
        XCTAssertTrue(sentPrompt.contains("Sunny, 25°C"))
        XCTAssertTrue(sentPrompt.contains("Back and biceps workout"))
    }
}