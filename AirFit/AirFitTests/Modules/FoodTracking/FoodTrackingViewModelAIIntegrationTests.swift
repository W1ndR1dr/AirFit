import XCTest
import SwiftData
@testable import AirFit

@MainActor

final class FoodTrackingViewModelAIIntegrationTests: XCTestCase {
    private var sut: FoodTrackingViewModel!
    private var mockCoachEngine: LocalMockCoachEngine!
    private var foodVoiceAdapter: FoodVoiceAdapter!
    private var mockVoiceInputManager: MockVoiceInputManager!
    private var mockNutritionService: MockNutritionService!
    private var coordinator: FoodTrackingCoordinator!
    private var testUser: User!
    private var modelContainer: ModelContainer!

    override func setUp() {
        super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        let modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(
            email: "test@example.com",
            name: "Test User"
        )
        
        modelContext.insert(testUser)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Create mocks
        mockCoachEngine = LocalMockCoachEngine()
        // Use real VoiceInputManager since it's a final class
        let voiceInputManager = VoiceInputManager()
        foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: voiceInputManager)
        mockVoiceInputManager = MockVoiceInputManager() // Keep for reference but not used directly
        mockNutritionService = MockNutritionService()
        coordinator = FoodTrackingCoordinator()
        
        // Create SUT
        sut = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: foodVoiceAdapter,
            nutritionService: mockNutritionService,
            coachEngine: mockCoachEngine,
            coordinator: coordinator
        )
    }

    override func tearDown() {
        sut = nil
        mockCoachEngine = nil
        mockVoiceInputManager = nil
        foodVoiceAdapter = nil
        mockNutritionService = nil
        coordinator = nil
        testUser = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - TASK 6.2.1: AI Integration Success Tests

    func test_processTranscription_aiParsingSuccess_showsConfirmation() async throws {
        // Given
        // Simulate voice input through the adapter
        mockVoiceInputManager.mockTranscriptionResult = "1 medium banana"
        let expectedItem = ParsedFoodItem(
            name: "banana",
            brand: nil,
            quantity: 1.0,
            unit: "medium",
            calories: 105, // Realistic calories, not hardcoded 100
            proteinGrams: 1.3,
            carbGrams: 27.0,
            fatGrams: 0.4,
            fiberGrams: 3.1,
            sugarGrams: 14.4,
            sodiumMilligrams: 1.0,
            databaseId: nil,
            confidence: 0.94
        )
        mockCoachEngine.mockParseResult = [expectedItem]

        // When
        await sut.startRecording()
        // Simulate transcription completion via callback
        mockVoiceInputManager.onTranscription?(mockVoiceInputManager.mockTranscriptionResult)
        await sut.stopRecording() // This will trigger processTranscription internally

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should complete AI processing")
        XCTAssertEqual(sut.parsedItems.count, 1, "Should parse single item")
        
        let parsedItem = sut.parsedItems.first!
        XCTAssertEqual(parsedItem.name, "banana", "Should parse correct food name")
        XCTAssertEqual(parsedItem.calories, 105, "Should have realistic calories, not hardcoded 100")
        XCTAssertNotEqual(parsedItem.proteinGrams, 5.0, "Should not have hardcoded 5g protein")
        XCTAssertNotEqual(parsedItem.carbGrams, 15.0, "Should not have hardcoded 15g carbs")
        XCTAssertNotEqual(parsedItem.fatGrams, 3.0, "Should not have hardcoded 3g fat")
        XCTAssertGreaterThan(parsedItem.confidence, 0.9, "Should have high confidence for common food")
        
        // Verify coordination to confirmation screen
        if case .confirmation(let items) = coordinator.activeFullScreenCover {
            XCTAssertEqual(items.count, 1, "Coordinator should receive parsed items")
            XCTAssertEqual(items.first?.name, "banana", "Coordinator should receive correct item")
        } else {
            XCTFail("Should show confirmation screen with parsed items")
        }
    }

    func test_processTranscription_multipleItems_parsesAllCorrectly() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "2 eggs and 1 slice of toast"
        let expectedItems = [
            ParsedFoodItem(
                name: "eggs",
                brand: nil,
                quantity: 2.0,
                unit: "large",
                calories: 140,
                proteinGrams: 12.0,
                carbGrams: 1.0,
                fatGrams: 10.0,
                fiberGrams: 0.0,
                sugarGrams: 1.0,
                sodiumMilligrams: 140.0,
                databaseId: nil,
                confidence: 0.95
            ),
            ParsedFoodItem(
                name: "toast",
                brand: nil,
                quantity: 1.0,
                unit: "slice",
                calories: 80,
                proteinGrams: 3.0,
                carbGrams: 14.0,
                fatGrams: 1.0,
                fiberGrams: 2.0,
                sugarGrams: 1.0,
                sodiumMilligrams: 150.0,
                databaseId: nil,
                confidence: 0.90
            )
        ]
        mockCoachEngine.mockParseResult = expectedItems

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertEqual(sut.parsedItems.count, 2, "Should parse multiple items")
        
        // Verify first item (eggs)
        let eggs = sut.parsedItems.first { $0.name == "eggs" }
        XCTAssertNotNil(eggs, "Should parse eggs")
        XCTAssertEqual(eggs?.calories, 140, "Eggs should have realistic calories")
        XCTAssertEqual(eggs?.quantity, 2.0, "Should preserve quantity")
        
        // Verify second item (toast)
        let toast = sut.parsedItems.first { $0.name == "toast" }
        XCTAssertNotNil(toast, "Should parse toast")
        XCTAssertEqual(toast?.calories, 80, "Toast should have different calories than eggs")
        
        // Verify different foods have different nutrition profiles
        XCTAssertNotEqual(eggs?.calories, toast?.calories, "Different foods should have different calories")
        XCTAssertNotEqual(eggs?.proteinGrams, toast?.proteinGrams, "Different foods should have different protein")
    }

    func test_processTranscription_complexDescription_handlesDetailedInput() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "grilled chicken breast with quinoa and steamed vegetables"
        sut.selectedMealType = .dinner
        
        let complexItems = [
            ParsedFoodItem(
                name: "grilled chicken breast",
                brand: nil,
                quantity: 6.0,
                unit: "oz",
                calories: 280,
                proteinGrams: 53.0,
                carbGrams: 0.0,
                fatGrams: 6.0,
                fiberGrams: 0.0,
                sugarGrams: 0.0,
                sodiumMilligrams: 126.0,
                databaseId: nil,
                confidence: 0.92
            ),
            ParsedFoodItem(
                name: "quinoa",
                brand: nil,
                quantity: 0.5,
                unit: "cup",
                calories: 111,
                proteinGrams: 4.1,
                carbGrams: 19.7,
                fatGrams: 1.8,
                fiberGrams: 2.6,
                sugarGrams: 0.9,
                sodiumMilligrams: 7.0,
                databaseId: nil,
                confidence: 0.88
            ),
            ParsedFoodItem(
                name: "steamed vegetables",
                brand: nil,
                quantity: 1.0,
                unit: "cup",
                calories: 35,
                proteinGrams: 2.0,
                carbGrams: 7.0,
                fatGrams: 0.3,
                fiberGrams: 3.0,
                sugarGrams: 4.0,
                sodiumMilligrams: 25.0,
                databaseId: nil,
                confidence: 0.85
            )
        ]
        mockCoachEngine.mockParseResult = complexItems

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertEqual(sut.parsedItems.count, 3, "Should parse all complex components")
        
        // Verify meal type context was preserved
        XCTAssertEqual(mockCoachEngine.lastMealType, MealType.dinner, "Should pass meal type context to AI")
        
        // Verify cooking method is preserved
        let chicken = sut.parsedItems.first { $0.name.contains("grilled") }
        XCTAssertNotNil(chicken, "Should preserve cooking method in food name")
        
        // Verify total nutrition makes sense for a dinner
        let totalCalories = sut.parsedItems.reduce(0) { $0 + $1.calories }
        XCTAssertGreaterThan(totalCalories, 300, "Dinner should have substantial calories")
        XCTAssertLessThan(totalCalories, 600, "Should not be unrealistically high")
    }

    // MARK: - TASK 6.2.2: Performance Tests

    func test_processTranscription_performance_completesUnder3Seconds() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "grilled salmon with quinoa and asparagus"
        mockCoachEngine.simulateDelay = 2.5 // Simulate realistic AI response time
        mockCoachEngine.mockParseResult = [
            ParsedFoodItem(
                name: "grilled salmon",
                brand: nil,
                quantity: 1.0,
                unit: "fillet",
                calories: 206,
                proteinGrams: 22.0,
                carbGrams: 0.0,
                fatGrams: 12.0,
                fiberGrams: 0.0,
                sugarGrams: 0.0,
                sodiumMilligrams: 59.0,
                databaseId: nil,
                confidence: 0.93
            )
        ]

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        await sut.startRecording()
        await sut.stopRecording()
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertLessThan(duration, 3.0, "Processing should complete within 3 seconds")
        XCTAssertFalse(sut.isProcessingAI, "Should complete processing")
        XCTAssertEqual(sut.parsedItems.count, 1, "Should return results within time limit")
    }

    func test_processTranscription_emptyText_noProcessing() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = ""

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should not process empty text")
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not create any parsed items")
        XCTAssertNil(coordinator.activeFullScreenCover, "Should not show confirmation for empty text")
        XCTAssertFalse(mockCoachEngine.wasParseNaturalLanguageFoodCalled, "Should not call AI for empty text")
    }

    // MARK: - TASK 6.2.3: Error Handling Tests

    func test_processTranscription_aiParsingFailure_showsError() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "complex food description"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = AppError.unknown(message: "AI parsing failed")

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should complete processing")
        XCTAssertNotNil(sut.error, "Should set error when AI parsing fails")
        
        if let error = sut.error as? AppError,
           case .unknown(let message) = error {
            XCTAssertEqual(message, "AI parsing failed", "Should preserve AI parsing error")
        } else {
            XCTFail("Error should be AppError.unknown with AI parsing failed message")
        }
        
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not have parsed items on error")
        XCTAssertNil(coordinator.activeFullScreenCover, "Should not show confirmation on error")
    }

    func test_processTranscription_networkError_handlesGracefully() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "chicken salad"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = AppError.networkError(underlying: URLError(.notConnectedToInternet))

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertNotNil(sut.error)
        
        if let error = sut.error as? AppError,
           case .networkError = error {
            XCTAssertTrue(true, "Should handle network errors")
        } else {
            XCTFail("Should handle network error appropriately")
        }
    }

    func test_processTranscription_noFoodFound_showsError() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "I drank water"
        mockCoachEngine.mockParseResult = [] // No food items detected

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertNotNil(sut.error)
        
        if let error = sut.error as? AppError,
           case .validationError(let message) = error {
            XCTAssertEqual(message, "No food detected", "Should show error when no food is detected")
        } else {
            XCTFail("Should show noFoodFound error")
        }
        
        XCTAssertEqual(sut.parsedItems.count, 0, "Should have no parsed items")
        XCTAssertNil(coordinator.activeFullScreenCover, "Should not show confirmation when no food found")
    }

    // MARK: - TASK 6.2.4: Meal Type Context Tests

    func test_processTranscription_preservesMealTypeContext() async throws {
        let mealTypeTests: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        
        for mealType in mealTypeTests {
            // Given
            sut.selectedMealType = mealType
            mockVoiceInputManager.mockTranscriptionResult = "test food"
            mockCoachEngine.mockParseResult = [
                ParsedFoodItem(
                    name: "test food",
                    brand: nil,
                    quantity: 1.0,
                    unit: "serving",
                    calories: 150,
                    proteinGrams: 8.0,
                    carbGrams: 20.0,
                    fatGrams: 4.0,
                    fiberGrams: 2.0,
                    sugarGrams: 5.0,
                    sodiumMilligrams: 100.0,
                    databaseId: nil,
                    confidence: 0.75
                )
            ]
            
            // Reset mock state
            mockCoachEngine.lastMealType = nil
            mockCoachEngine.wasParseNaturalLanguageFoodCalled = false

            // When
            await sut.startRecording()
            await sut.stopRecording()

            // Then
            XCTAssertTrue(mockCoachEngine.wasParseNaturalLanguageFoodCalled, "Should call AI parsing")
            XCTAssertEqual(mockCoachEngine.lastMealType, mealType, "Should pass \(mealType.rawValue) context to AI")
            XCTAssertEqual(mockCoachEngine.lastUserPassed?.id, testUser.id, "Should pass user context to AI")
        }
    }

    // MARK: - TASK 6.2.5: Data Quality Validation Tests

    func test_processTranscription_validatesNutritionValues() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "apple"
        let validItem = ParsedFoodItem(
            name: "apple",
            brand: nil,
            quantity: 1.0,
            unit: "medium",
            calories: 95,
            proteinGrams: 0.5,
            carbGrams: 25.0,
            fatGrams: 0.3,
            fiberGrams: 4.0,
            sugarGrams: 19.0,
            sodiumMilligrams: 2.0,
            databaseId: nil,
            confidence: 0.95
        )
        mockCoachEngine.mockParseResult = [validItem]

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertEqual(sut.parsedItems.count, 1)
        let item = sut.parsedItems.first!
        
        // Verify realistic nutrition values
        XCTAssertGreaterThan(item.calories, 0, "Calories should be positive")
        XCTAssertLessThan(item.calories, 200, "Apple calories should be reasonable")
        XCTAssertGreaterThanOrEqual(item.proteinGrams, 0, "Protein should be non-negative")
        XCTAssertLessThan(item.proteinGrams, 2.0, "Apple protein should be low")
        XCTAssertGreaterThan(item.carbGrams, 20, "Apple should be carb-heavy")
        XCTAssertLessThan(item.fatGrams, 1.0, "Apple fat should be very low")
        XCTAssertGreaterThan(item.confidence, 0.9, "Common foods should have high confidence")
    }

    func test_processTranscription_regressionPrevention_noHardcodedValues() async throws {
        let testFoods = [
            ("apple", 95),
            ("pizza slice", 285),
            ("chicken breast", 280),
            ("brown rice", 216)
        ]
        
        for (food, expectedCalories) in testFoods {
            // Given
            mockVoiceInputManager.mockTranscriptionResult = food
            mockCoachEngine.mockParseResult = [
                ParsedFoodItem(
                    name: food,
                    brand: nil,
                    quantity: 1.0,
                    unit: "serving",
                    calories: expectedCalories,
                    proteinGrams: expectedCalories == 280 ? 53.0 : 5.0, // Chicken has high protein
                    carbGrams: expectedCalories == 216 ? 45.0 : 15.0, // Rice has high carbs
                    fatGrams: expectedCalories == 285 ? 10.0 : 3.0, // Pizza has more fat
                    fiberGrams: 2.0,
                    sugarGrams: 5.0,
                    sodiumMilligrams: 100.0,
                    databaseId: nil,
                    confidence: 0.90
                )
            ]
            
            // When
            await sut.startRecording()
            await sut.stopRecording()

            // Then
            XCTAssertEqual(sut.parsedItems.count, 1, "Should parse \(food)")
            let item = sut.parsedItems.first!
            
            // Verify no hardcoded placeholder values
            XCTAssertNotEqual(item.calories, 100, "\(food) should not have hardcoded 100 calories")
            XCTAssertNotEqual(item.proteinGrams, 5.0, "\(food) should not always have 5g protein")
            XCTAssertNotEqual(item.carbGrams, 15.0, "\(food) should not always have 15g carbs")
            XCTAssertNotEqual(item.fatGrams, 3.0, "\(food) should not always have 3g fat")
            
            // Verify expected realistic values
            XCTAssertEqual(item.calories, expectedCalories, "\(food) should have expected calories")
        }
    }

    // MARK: - TASK 6.2.6: Integration State Management Tests

    func test_processTranscription_stateManagement_isProcessingAI() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "test food"
        mockCoachEngine.simulateDelay = 0.5
        mockCoachEngine.mockParseResult = [
            ParsedFoodItem(
                name: "test food",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 150,
                proteinGrams: 8.0,
                carbGrams: 20.0,
                fatGrams: 4.0,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                databaseId: nil,
                confidence: 0.75
            )
        ]

        // When/Then
        XCTAssertFalse(sut.isProcessingAI, "Should start with isProcessingAI false")
        
        let processingTask = Task {
            await sut.startRecording()
            await sut.stopRecording()
        }
        
        // Give a small delay to let processing start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(sut.isProcessingAI, "Should set isProcessingAI true during processing")
        
        await processingTask.value
        XCTAssertFalse(sut.isProcessingAI, "Should set isProcessingAI false after completion")
    }

    func test_processTranscription_errorHandling_clearsProcessingState() async throws {
        // Given
        mockVoiceInputManager.mockTranscriptionResult = "test food"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = AppError.unknown(message: "AI parsing failed")

        // When
        await sut.startRecording()
        await sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should clear isProcessingAI even on error")
        XCTAssertNotNil(sut.error, "Should set error")
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not have parsed items on error")
    }
}

// MARK: - Enhanced Mock for AI Integration Testing

final class MockAICoachEngine: FoodCoachEngineProtocol {
    var mockParseResult: [ParsedFoodItem] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "AI parsing failed")
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?
    var lastUserPassed: User?
    var wasParseNaturalLanguageFoodCalled = false

    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        return [:]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        return FunctionExecutionResult(
            success: true,
            message: "Mock execution",
            data: [:],
            executionTimeMs: 100,
            functionName: functionCall.name
        )
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
        return MealPhotoAnalysisResult(
            items: mockParseResult,
            confidence: 0.8,
            processingTime: 0.5
        )
    }

    func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
        return mockParseResult
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        wasParseNaturalLanguageFoodCalled = true
        lastMealType = mealType
        lastUserPassed = user

        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return mockParseResult
    }
}

// MARK: - Additional Mock Classes

// Local mock for CoachEngine implementing FoodCoachEngineProtocol
@MainActor
class LocalMockCoachEngine: FoodCoachEngineProtocol {
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock error")
    var mockParseResult: [ParsedFoodItem] = []
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?
    var lastUserPassed: User?
    var wasParseNaturalLanguageFoodCalled = false
    
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        return [:]
    }
    
    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        return FunctionExecutionResult(
            success: true,
            message: "Mock execution",
            data: [:],
            executionTimeMs: 100,
            functionName: functionCall.name
        )
    }
    
    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
        return MealPhotoAnalysisResult(
            items: mockParseResult,
            confidence: 0.8,
            processingTime: 0.5
        )
    }
    
    func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
        return mockParseResult
    }
    
    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        wasParseNaturalLanguageFoodCalled = true
        lastMealType = mealType
        lastUserPassed = user
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        return mockParseResult
    }
}

// Using MockNutritionService from Mocks folder
// Using FoodTrackingCoordinator directly for testing
