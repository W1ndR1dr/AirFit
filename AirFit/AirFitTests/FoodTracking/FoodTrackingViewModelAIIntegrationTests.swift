import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class FoodTrackingViewModelAIIntegrationTests: XCTestCase {
    private var sut: FoodTrackingViewModel!
    private var mockCoachEngine: MockAICoachEngine!
    private var mockVoiceAdapter: MockFoodVoiceAdapter!
    private var mockNutritionService: MockNutritionService!
    private var mockCoordinator: MockFoodTrackingCoordinator!
    private var testUser: User!
    private var modelContainer: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        let modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(
            name: "Test User",
            email: "test@example.com",
            dateOfBirth: Date(),
            heightCm: 175,
            weightKg: 70,
            activityLevel: .moderate,
            primaryGoal: .maintainWeight
        )
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create mocks
        mockCoachEngine = MockAICoachEngine()
        mockVoiceAdapter = MockFoodVoiceAdapter()
        mockNutritionService = MockNutritionService()
        mockCoordinator = MockFoodTrackingCoordinator()
        
        // Create SUT
        sut = FoodTrackingViewModel(
            user: testUser,
            nutritionService: mockNutritionService,
            coachEngine: mockCoachEngine,
            voiceAdapter: mockVoiceAdapter,
            coordinator: mockCoordinator
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockCoachEngine = nil
        mockVoiceAdapter = nil
        mockNutritionService = nil
        mockCoordinator = nil
        testUser = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - TASK 6.2.1: AI Integration Success Tests

    func test_processTranscription_aiParsingSuccess_showsConfirmation() async throws {
        // Given
        sut.transcribedText = "1 medium banana"
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
        await sut.processTranscription()

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
        if case .confirmation(let items) = mockCoordinator.didShowFullScreenCover {
            XCTAssertEqual(items.count, 1, "Coordinator should receive parsed items")
            XCTAssertEqual(items.first?.name, "banana", "Coordinator should receive correct item")
        } else {
            XCTFail("Should show confirmation screen with parsed items")
        }
    }

    func test_processTranscription_multipleItems_parsesAllCorrectly() async throws {
        // Given
        sut.transcribedText = "2 eggs and 1 slice of toast"
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
        await sut.processTranscription()

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
        sut.transcribedText = "grilled chicken breast with quinoa and steamed vegetables"
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
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertEqual(sut.parsedItems.count, 3, "Should parse all complex components")
        
        // Verify meal type context was preserved
        XCTAssertEqual(mockCoachEngine.lastMealType, .dinner, "Should pass meal type context to AI")
        
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
        sut.transcribedText = "grilled salmon with quinoa and asparagus"
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
        await sut.processTranscription()
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertLessThan(duration, 3.0, "Processing should complete within 3 seconds")
        XCTAssertFalse(sut.isProcessingAI, "Should complete processing")
        XCTAssertEqual(sut.parsedItems.count, 1, "Should return results within time limit")
    }

    func test_processTranscription_emptyText_noProcessing() async throws {
        // Given
        sut.transcribedText = ""

        // When
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should not process empty text")
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not create any parsed items")
        XCTAssertNil(mockCoordinator.didShowFullScreenCover, "Should not show confirmation for empty text")
        XCTAssertFalse(mockCoachEngine.wasParseNaturalLanguageFoodCalled, "Should not call AI for empty text")
    }

    // MARK: - TASK 6.2.3: Error Handling Tests

    func test_processTranscription_aiParsingFailure_showsError() async throws {
        // Given
        sut.transcribedText = "complex food description"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = FoodTrackingError.aiParsingFailed

        // When
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should complete processing")
        XCTAssertNotNil(sut.currentError, "Should set error when AI parsing fails")
        
        if let error = sut.currentError as? FoodTrackingError {
            XCTAssertEqual(error, .aiParsingFailed, "Should preserve AI parsing error")
        } else {
            XCTFail("Error should be FoodTrackingError.aiParsingFailed")
        }
        
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not have parsed items on error")
        XCTAssertNil(mockCoordinator.didShowFullScreenCover, "Should not show confirmation on error")
    }

    func test_processTranscription_networkError_handlesGracefully() async throws {
        // Given
        sut.transcribedText = "chicken salad"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = FoodTrackingError.networkError

        // When
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertNotNil(sut.currentError)
        
        if let error = sut.currentError as? FoodTrackingError {
            XCTAssertEqual(error, .networkError, "Should handle network errors")
        } else {
            XCTFail("Should handle network error appropriately")
        }
    }

    func test_processTranscription_noFoodFound_showsError() async throws {
        // Given
        sut.transcribedText = "I drank water"
        mockCoachEngine.mockParseResult = [] // No food items detected

        // When
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI)
        XCTAssertNotNil(sut.currentError)
        
        if let error = sut.currentError as? FoodTrackingError {
            XCTAssertEqual(error, .noFoodFound, "Should show error when no food is detected")
        } else {
            XCTFail("Should show noFoodFound error")
        }
        
        XCTAssertEqual(sut.parsedItems.count, 0, "Should have no parsed items")
        XCTAssertNil(mockCoordinator.didShowFullScreenCover, "Should not show confirmation when no food found")
    }

    // MARK: - TASK 6.2.4: Meal Type Context Tests

    func test_processTranscription_preservesMealTypeContext() async throws {
        let mealTypeTests: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        
        for mealType in mealTypeTests {
            // Given
            sut.selectedMealType = mealType
            sut.transcribedText = "test food"
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
            await sut.processTranscription()

            // Then
            XCTAssertTrue(mockCoachEngine.wasParseNaturalLanguageFoodCalled, "Should call AI parsing")
            XCTAssertEqual(mockCoachEngine.lastMealType, mealType, "Should pass \(mealType.rawValue) context to AI")
            XCTAssertEqual(mockCoachEngine.lastUserPassed?.id, testUser.id, "Should pass user context to AI")
        }
    }

    // MARK: - TASK 6.2.5: Data Quality Validation Tests

    func test_processTranscription_validatesNutritionValues() async throws {
        // Given
        sut.transcribedText = "apple"
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
        await sut.processTranscription()

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
            sut.transcribedText = food
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
            await sut.processTranscription()

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
        sut.transcribedText = "test food"
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
            await sut.processTranscription()
        }
        
        // Give a small delay to let processing start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(sut.isProcessingAI, "Should set isProcessingAI true during processing")
        
        await processingTask.value
        XCTAssertFalse(sut.isProcessingAI, "Should set isProcessingAI false after completion")
    }

    func test_processTranscription_errorHandling_clearsProcessingState() async throws {
        // Given
        sut.transcribedText = "test food"
        mockCoachEngine.shouldThrowError = true
        mockCoachEngine.errorToThrow = FoodTrackingError.aiParsingFailed

        // When
        await sut.processTranscription()

        // Then
        XCTAssertFalse(sut.isProcessingAI, "Should clear isProcessingAI even on error")
        XCTAssertNotNil(sut.currentError, "Should set error")
        XCTAssertEqual(sut.parsedItems.count, 0, "Should not have parsed items on error")
    }
}

// MARK: - Enhanced Mock for AI Integration Testing

@MainActor
final class MockAICoachEngine: FoodCoachEngineProtocol {
    var mockParseResult: [ParsedFoodItem] = []
    var shouldThrowError = false
    var errorToThrow: Error = FoodTrackingError.aiParsingFailed
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?
    var lastUserPassed: User?
    var wasParseNaturalLanguageFoodCalled = false

    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        return [:]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        return FunctionExecutionResult(
            functionName: functionCall.name,
            success: true,
            message: "Mock execution",
            data: [:]
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

@MainActor
class MockFoodVoiceAdapter: FoodVoiceServiceProtocol {
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var transcribedText: String = ""
    var voiceWaveform: [Float] = []

    var onFoodTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    var requestPermissionShouldSucceed: Bool = true
    var startRecordingShouldSucceed: Bool = true
    var stopRecordingText: String? = "mock transcription"

    func requestPermission() async throws -> Bool {
        if !requestPermissionShouldSucceed { 
            throw FoodTrackingError.permissionDenied 
        }
        return requestPermissionShouldSucceed
    }

    func startRecording() async throws {
        if !startRecordingShouldSucceed { 
            throw FoodTrackingError.transcriptionFailed 
        }
        isRecording = true
    }

    func stopRecording() async -> String? {
        isRecording = false
        return stopRecordingText
    }
}

class MockNutritionService: NutritionServiceProtocol {
    var shouldThrowError: Bool = false
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        if shouldThrowError {
            throw FoodTrackingError.saveFailed
        }
    }
    
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        if shouldThrowError {
            throw FoodTrackingError.networkError
        }
        return []
    }
    
    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        if shouldThrowError {
            throw FoodTrackingError.saveFailed
        }
    }
}

@MainActor
class MockFoodTrackingCoordinator: FoodTrackingCoordinator {
    var didShowSheet: FoodTrackingSheet?
    var didShowFullScreenCover: FoodTrackingFullScreenCover?
    var didDismiss = false

    override func showSheet(_ sheet: FoodTrackingSheet) {
        didShowSheet = sheet
    }

    override func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
        didShowFullScreenCover = cover
    }

    override func dismiss() {
        didDismiss = true
        activeSheet = nil
        activeFullScreenCover = nil
    }
} 