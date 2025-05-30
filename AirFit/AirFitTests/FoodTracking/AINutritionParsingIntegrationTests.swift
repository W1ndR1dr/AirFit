import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class AINutritionParsingIntegrationTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: CoachEngine!
    private var testUser: User!

    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
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
        
        // Create CoachEngine with default configuration
        coachEngine = CoachEngine.createDefault(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        testUser = nil
        try await super.tearDown()
    }

    // MARK: - Integration Tests

    func test_parseNaturalLanguageFood_withMockAI_returnsValidResults() async throws {
        // Given
        let input = "grilled chicken breast"
        
        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should return at least one parsed item")
        
        let firstItem = result[0]
        XCTAssertFalse(firstItem.name.isEmpty, "Food name should not be empty")
        XCTAssertGreaterThan(firstItem.calories, 0, "Calories should be positive")
        XCTAssertGreaterThanOrEqual(firstItem.proteinGrams, 0, "Protein should be non-negative")
        XCTAssertGreaterThanOrEqual(firstItem.carbGrams, 0, "Carbs should be non-negative")
        XCTAssertGreaterThanOrEqual(firstItem.fatGrams, 0, "Fat should be non-negative")
        XCTAssertGreaterThan(firstItem.confidence, 0, "Confidence should be positive")
        XCTAssertLessThanOrEqual(firstItem.confidence, 1, "Confidence should not exceed 1.0")
    }

    func test_parseNaturalLanguageFood_fallbackBehavior_handlesInvalidInput() async throws {
        // Given
        let input = "xyz123invalid"
        
        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .snack,
            for: testUser
        )
        
        // Then
        XCTAssertEqual(result.count, 1, "Should return fallback item")
        
        let fallbackItem = result[0]
        XCTAssertEqual(fallbackItem.name, "xyz123invalid", "Should preserve original input as name")
        XCTAssertEqual(fallbackItem.calories, 150, "Should use snack default calories")
        XCTAssertEqual(fallbackItem.confidence, 0.3, accuracy: 0.01, "Should have low confidence for fallback")
    }

    func test_parseNaturalLanguageFood_mealTypeContext_adjustsDefaultCalories() async throws {
        // Given
        let input = "unknown food"
        
        // Test breakfast
        let breakfastResult = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .breakfast,
            for: testUser
        )
        
        // Test dinner
        let dinnerResult = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        
        // Then
        XCTAssertEqual(breakfastResult[0].calories, 250, "Breakfast should have 250 default calories")
        XCTAssertEqual(dinnerResult[0].calories, 500, "Dinner should have 500 default calories")
    }

    func test_parseNaturalLanguageFood_nutritionValidation_rejectsInvalidValues() async throws {
        // This test verifies that the validation logic works correctly
        // Since we're using the default CoachEngine, it will use fallback for any input
        
        // Given
        let input = "test food"
        
        // When
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .lunch,
            for: testUser
        )
        
        // Then
        let item = result[0]
        XCTAssertLessThan(item.calories, 5000, "Calories should be within reasonable range")
        XCTAssertLessThan(item.proteinGrams, 300, "Protein should be within reasonable range")
        XCTAssertLessThan(item.carbGrams, 1000, "Carbs should be within reasonable range")
        XCTAssertLessThan(item.fatGrams, 500, "Fat should be within reasonable range")
    }

    func test_parseNaturalLanguageFood_performance_completesQuickly() async throws {
        // Given
        let input = "salmon with vegetables"
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should return results")
        XCTAssertLessThan(duration, 1.0, "Should complete within 1 second for fallback")
    }
} 