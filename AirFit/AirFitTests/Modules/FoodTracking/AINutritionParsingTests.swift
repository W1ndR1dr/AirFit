import XCTest
import SwiftData
@testable import AirFit

final class AINutritionParsingTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockFoodCoachEngine!
    private var testUser: User!

    override func setUp() {
        super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(
            email: "test@example.com",
            name: "Test User"
        )
        
        // Create onboarding profile with test data
        let profileData = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Maintain weight"),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle()
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileData)
        
        let onboardingProfile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data,
            user: testUser
        )
        testUser.onboardingProfile = onboardingProfile
        
        modelContext.insert(testUser)
        modelContext.insert(onboardingProfile)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Create mock coach engine
        coachEngine = MockFoodCoachEngine()
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        testUser = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing Tests

    func test_parseNaturalLanguageFood_simpleFood_returnsParsedItem() async throws {
        // Given
        let input = "apple"
        let expectedItem = ParsedFoodItem(
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
        coachEngine.mockParseResult = [expectedItem]

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .snack,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "apple")
        XCTAssertEqual(result[0].calories, 95)
        XCTAssertEqual(result[0].confidence, 0.95, accuracy: 0.01)
    }

    func test_parseNaturalLanguageFood_foodWithQuantity_returnsParsedItem() async throws {
        // Given
        let input = "2 cups of rice"
        let expectedItem = ParsedFoodItem(
            name: "rice",
            brand: nil,
            quantity: 2.0,
            unit: "cups",
            calories: 410,
            proteinGrams: 8.0,
            carbGrams: 90.0,
            fatGrams: 1.0,
            fiberGrams: 2.0,
            sugarGrams: 0.5,
            sodiumMilligrams: 5.0,
            databaseId: nil,
            confidence: 0.92
        )
        coachEngine.mockParseResult = [expectedItem]

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .lunch,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "rice")
        XCTAssertEqual(result[0].quantity, 2.0)
        XCTAssertEqual(result[0].unit, "cups")
        XCTAssertEqual(result[0].calories, 410)
    }

    func test_parseNaturalLanguageFood_multipleFoods_returnsMultipleParsedItems() async throws {
        // Given
        let input = "chicken breast with broccoli and rice"
        let expectedItems = [
            ParsedFoodItem(
                name: "chicken breast",
                brand: nil,
                quantity: 1.0,
                unit: "piece",
                calories: 165,
                proteinGrams: 31.0,
                carbGrams: 0.0,
                fatGrams: 3.6,
                fiberGrams: 0.0,
                sugarGrams: 0.0,
                sodiumMilligrams: 74.0,
                databaseId: nil,
                confidence: 0.90
            ),
            ParsedFoodItem(
                name: "broccoli",
                brand: nil,
                quantity: 1.0,
                unit: "cup",
                calories: 25,
                proteinGrams: 3.0,
                carbGrams: 5.0,
                fatGrams: 0.3,
                fiberGrams: 2.3,
                sugarGrams: 1.5,
                sodiumMilligrams: 33.0,
                databaseId: nil,
                confidence: 0.88
            ),
            ParsedFoodItem(
                name: "rice",
                brand: nil,
                quantity: 0.5,
                unit: "cup",
                calories: 103,
                proteinGrams: 2.0,
                carbGrams: 22.0,
                fatGrams: 0.2,
                fiberGrams: 0.6,
                sugarGrams: 0.1,
                sodiumMilligrams: 1.0,
                databaseId: nil,
                confidence: 0.85
            )
        ]
        coachEngine.mockParseResult = expectedItems

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, "chicken breast")
        XCTAssertEqual(result[1].name, "broccoli")
        XCTAssertEqual(result[2].name, "rice")
    }

    // MARK: - Error Handling Tests

    func test_parseNaturalLanguageFood_networkError_throwsError() async {
        // Given
        let input = "pizza"
        coachEngine.shouldThrowError = true
        coachEngine.errorToThrow = FoodTrackingError.networkError

        // When/Then
        do {
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .lunch,
                for: testUser
            )
            XCTFail("Expected error to be thrown")
        } catch let error as FoodTrackingError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_parseNaturalLanguageFood_invalidInput_returnsFallbackItem() async throws {
        // Given
        let input = "xyz123invalid"
        coachEngine.shouldReturnFallback = true

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .snack,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "xyz123invalid")
        XCTAssertEqual(result[0].confidence, 0.3, accuracy: 0.01) // Low confidence for fallback
        XCTAssertEqual(result[0].calories, 150) // Snack default calories
    }

    // MARK: - Meal Type Context Tests

    func test_parseNaturalLanguageFood_breakfastContext_adjustsCalories() async throws {
        // Given
        let input = "oatmeal"
        let expectedItem = ParsedFoodItem(
            name: "oatmeal",
            brand: nil,
            quantity: 1.0,
            unit: "bowl",
            calories: 150,
            proteinGrams: 5.0,
            carbGrams: 27.0,
            fatGrams: 3.0,
            fiberGrams: 4.0,
            sugarGrams: 1.0,
            sodiumMilligrams: 9.0,
            databaseId: nil,
            confidence: 0.90
        )
        coachEngine.mockParseResult = [expectedItem]

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .breakfast,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "oatmeal")
        XCTAssertTrue(coachEngine.lastMealType == .breakfast)
    }

    // MARK: - Performance Tests

    func test_parseNaturalLanguageFood_performance_completesWithinTimeout() async throws {
        // Given
        let input = "grilled salmon with quinoa and asparagus"
        let expectedItems = [
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
        coachEngine.mockParseResult = expectedItems
        coachEngine.simulateDelay = 0.5 // 500ms delay

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertLessThan(duration, 2.0, "Parsing should complete within 2 seconds")
    }

    // MARK: - Validation Tests

    func test_parseNaturalLanguageFood_validatesNutritionValues_rejectsInvalidData() async throws {
        // Given
        let input = "magic food"
        let invalidItem = ParsedFoodItem(
            name: "magic food",
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: 10000, // Invalid: too high
            proteinGrams: 500, // Invalid: too high
            carbGrams: 2000, // Invalid: too high
            fatGrams: 1000, // Invalid: too high
            fiberGrams: 0.0,
            sugarGrams: 0.0,
            sodiumMilligrams: 0.0,
            databaseId: nil,
            confidence: 0.95
        )
        coachEngine.mockParseResult = [invalidItem]
        coachEngine.shouldValidate = true

        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .lunch,
            for: testUser
        )

        // Then
        // Should return fallback item instead of invalid data
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "magic")
        XCTAssertLessThan(result[0].calories, 5000)
        XCTAssertEqual(result[0].confidence, 0.3, accuracy: 0.01) // Fallback confidence
    }

    // MARK: - New Tests

    func test_parseNaturalLanguageFood_withLunchMealType_shouldReturnCorrectFallback() async throws {
        // Arrange
        coachEngine.shouldThrowError = true
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "mystery food",
            mealType: MealType.lunch,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.calories, 400)
    }
    
    func test_parseNaturalLanguageFood_withDinnerMealType_shouldReturnCorrectFallback() async throws {
        // Arrange
        coachEngine.shouldThrowError = true
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "unknown dinner",
            mealType: MealType.dinner,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.calories, 500)
    }
    
    func test_parseNaturalLanguageFood_withMultipleFoods_shouldReturnMultipleItems() async throws {
        // Arrange
        coachEngine.mockParseResult = [
            ParsedFoodItem(name: "Apple", brand: nil, quantity: 1, unit: "medium", calories: 95, proteinGrams: 0.5, carbGrams: 25, fatGrams: 0.3, fiberGrams: 4, sugarGrams: 19, sodiumMilligrams: 1, databaseId: nil, confidence: 0.9),
            ParsedFoodItem(name: "Banana", brand: nil, quantity: 1, unit: "medium", calories: 105, proteinGrams: 1.3, carbGrams: 27, fatGrams: 0.4, fiberGrams: 3, sugarGrams: 12, sodiumMilligrams: 1, databaseId: nil, confidence: 0.8)
        ]
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "apple and banana",
            mealType: MealType.lunch,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Apple")
        XCTAssertEqual(result[1].name, "Banana")
    }
    
    func test_parseNaturalLanguageFood_withSnackMealType_shouldReturnCorrectFallback() async throws {
        // Arrange
        coachEngine.shouldThrowError = true
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "unknown snack",
            mealType: MealType.snack,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.calories, 150)
    }
    
    func test_parseNaturalLanguageFood_withBreakfastMealType_shouldReturnCorrectFallback() async throws {
        // Arrange
        coachEngine.shouldThrowError = true
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "unknown breakfast",
            mealType: MealType.breakfast,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(coachEngine.lastMealType == MealType.breakfast)
        XCTAssertEqual(result.first?.calories, 250)
    }
    
    func test_parseNaturalLanguageFood_withPerformanceRequirement_shouldCompleteUnder3Seconds() async throws {
        // Arrange
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "chicken breast with rice",
            mealType: MealType.dinner,
            for: testUser
        )
        
        // Assert
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 3.0, "Parsing should complete under 3 seconds")
        XCTAssertFalse(result.isEmpty)
    }
    
    func test_parseNaturalLanguageFood_withComplexMeal_shouldParseCorrectly() async throws {
        // Arrange
        coachEngine.mockParseResult = [
            ParsedFoodItem(name: "Grilled Chicken", brand: nil, quantity: 6, unit: "oz", calories: 280, proteinGrams: 52, carbGrams: 0, fatGrams: 6, fiberGrams: 0, sugarGrams: 0, sodiumMilligrams: 400, databaseId: nil, confidence: 0.95),
            ParsedFoodItem(name: "Brown Rice", brand: nil, quantity: 1, unit: "cup", calories: 220, proteinGrams: 5, carbGrams: 45, fatGrams: 2, fiberGrams: 4, sugarGrams: 1, sodiumMilligrams: 10, databaseId: nil, confidence: 0.9),
            ParsedFoodItem(name: "Steamed Broccoli", brand: nil, quantity: 1, unit: "cup", calories: 25, proteinGrams: 3, carbGrams: 5, fatGrams: 0, fiberGrams: 2, sugarGrams: 2, sodiumMilligrams: 30, databaseId: nil, confidence: 0.85)
        ]
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "6 oz grilled chicken with 1 cup brown rice and steamed broccoli",
            mealType: MealType.lunch,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 3)
        let totalCalories = result.reduce(0) { $0 + $1.calories }
        XCTAssertEqual(totalCalories, 525)
    }

    // Test snack parsing with fallback
    func test_parseNaturalLanguageFood_snackParsing_returnsFallbackItem() async throws {
        // Arrange
        coachEngine.shouldThrowError = true
        
        // Act
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "apple",
            mealType: MealType.snack,
            for: testUser
        )
        
        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.calories, 150)
    }
}

// MARK: - Mock Coach Engine

final class MockFoodCoachEngine: CoachEngineProtocol, FoodCoachEngineProtocol {
    var mockParseResult: [ParsedFoodItem] = []
    var shouldThrowError = false
    var errorToThrow: Error = FoodTrackingError.aiParsingFailed
    var shouldReturnFallback = false
    var shouldValidate = false
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?
    var lastText: String?
    var lastUser: User?

    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        return [:]
    }
    
    // CoachEngineProtocol required methods
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        return "Mock workout analysis"
    }
    
    func processUserMessage(_ text: String, for user: User) async {
        lastText = text
        lastUser = user
        isProcessing = true
        currentResponse = "Mock response for: \(text)"
        isProcessing = false
    }
    
    // CoachEngineProtocol methods
    private(set) var isProcessing = false
    private(set) var currentResponse = ""
    private(set) var error: Error?
    private(set) var activeConversationId: UUID?
    private(set) var streamingTokens: [String] = []
    
    func processMessage(_ message: String, context: Any? = nil) async throws -> String {
        return "Mock response"
    }
    
    func regenerateLastMessage() async throws -> String {
        return "Regenerated response"
    }
    
    func handleFunctionResult(functionName: String, result: Any) async throws {
        // Mock implementation
    }
    
    func generateSuggestions(for context: Any? = nil) async -> [String] {
        return ["Mock suggestion"]
    }
    
    func cancelStreaming() {
        isProcessing = false
    }
    
    func reset() {
        isProcessing = false
        currentResponse = ""
        error = nil
        streamingTokens = []
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
        lastText = text
        lastMealType = mealType
        lastUser = user

        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }

        if shouldThrowError {
            // Return fallback calories based on meal type
            let fallbackCalories: Int
            switch mealType {
            case .breakfast:
                fallbackCalories = 250
            case .lunch:
                fallbackCalories = 400
            case .dinner:
                fallbackCalories = 500
            case .snack:
                fallbackCalories = 150
            case .preWorkout:
                fallbackCalories = 200
            case .postWorkout:
                fallbackCalories = 300
            }
            
            return [ParsedFoodItem(
                name: "Unknown Food",
                brand: nil,
                quantity: 1,
                unit: "serving",
                calories: fallbackCalories,
                proteinGrams: 10,
                carbGrams: 30,
                fatGrams: 5,
                fiberGrams: 2,
                sugarGrams: 5,
                sodiumMilligrams: 200,
                databaseId: nil,
                confidence: 0.1
            )]
        }

        if shouldReturnFallback {
            return [createFallbackFoodItem(from: text, mealType: mealType)]
        }

        if shouldValidate {
            let validatedItems = validateNutritionValues(mockParseResult)
            if validatedItems.isEmpty {
                return [createFallbackFoodItem(from: text, mealType: mealType)]
            }
            return validatedItems
        }

        return mockParseResult
    }

    private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
        let foodName = text.components(separatedBy: .whitespacesAndNewlines)
            .first(where: { $0.count > 2 }) ?? "Unknown Food"

        let defaultCalories: Int = {
            switch mealType {
            case .breakfast: return 250
            case .lunch: return 400
            case .dinner: return 500
            case .snack: return 150
            case .preWorkout: return 200
            case .postWorkout: return 300
            }
        }()

        return ParsedFoodItem(
            name: foodName,
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: defaultCalories,
            proteinGrams: Double(defaultCalories) * 0.15 / 4,
            carbGrams: Double(defaultCalories) * 0.50 / 4,
            fatGrams: Double(defaultCalories) * 0.35 / 9,
            fiberGrams: 3.0,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            databaseId: nil,
            confidence: 0.3
        )
    }

    private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
        return items.compactMap { item in
            guard item.calories > 0 && item.calories < 5000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1000,
                  item.fatGrams >= 0 && item.fatGrams < 500 else {
                return nil
            }
            return item
        }
    }
}