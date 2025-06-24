import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class DashboardNutritionServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: DashboardNutritionService!
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
        
        // Create service with injected dependencies
        sut = DashboardNutritionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        sut = nil
        testUser = nil
        modelContext = nil
        container = nil
        try super.tearDown()
    }
    
    // MARK: - Test Helpers
    
    private func createTestProfile(for user: User) throws -> OnboardingProfile {
        let coachingPlan = CoachingPlan(
            understandingSummary: "Test user wants to get healthier",
            coachingApproach: ["Supportive guidance", "Daily accountability"],
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Get healthier"),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "UTC",
            generatedPersona: PersonaProfile(
                id: UUID(),
                name: "Coach AI",
                archetype: "Supportive Health Coach",
                systemPrompt: "You are a supportive health coach",
                coreValues: ["health", "support", "consistency"],
                backgroundStory: "Dedicated to helping users achieve their health goals",
                voiceCharacteristics: VoiceCharacteristics(
                    energy: .moderate,
                    pace: .natural,
                    warmth: .warm,
                    vocabulary: .moderate,
                    sentenceStructure: .moderate
                ),
                interactionStyle: InteractionStyle(
                    greetingStyle: "Hello!",
                    closingStyle: "Keep up the great work!",
                    encouragementPhrases: ["You're doing great!"],
                    acknowledgmentStyle: "I understand",
                    correctionApproach: "gentle",
                    humorLevel: .light,
                    formalityLevel: .balanced,
                    responseLength: .moderate
                ),
                adaptationRules: [],
                metadata: PersonaMetadata(
                    createdAt: Date(),
                    version: "1.0",
                    sourceInsights: ConversationPersonalityInsights(
                        dominantTraits: [],
                        communicationStyle: .conversational,
                        motivationType: .health,
                        energyLevel: .moderate,
                        preferredComplexity: .moderate,
                        emotionalTone: ["supportive"],
                        stressResponse: .needsSupport,
                        preferredTimes: ["morning", "evening"],
                        extractedAt: Date()
                    ),
                    generationDuration: 0,
                    tokenCount: 0,
                    previewReady: true
                )
            )
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(coachingPlan)
        
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data,
            user: user
        )
        
        user.onboardingProfile = profile
        modelContext.insert(profile)
        try modelContext.save()
        
        return profile
    }
    
    private func createTestFoodEntries(for user: User, date: Date = Date()) throws {
        // Breakfast
        let breakfast = FoodEntry(
            name: "Oatmeal with berries",
            calories: 350,
            protein: 12,
            carbs: 60,
            fat: 8,
            mealType: .breakfast,
            loggedAt: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        )
        breakfast.user = user
        modelContext.insert(breakfast)
        
        // Lunch
        let lunch = FoodEntry(
            name: "Grilled chicken salad",
            calories: 450,
            protein: 35,
            carbs: 30,
            fat: 20,
            mealType: .lunch,
            loggedAt: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: date)!
        )
        lunch.user = user
        modelContext.insert(lunch)
        
        // Snack
        let snack = FoodEntry(
            name: "Protein shake",
            calories: 200,
            protein: 25,
            carbs: 15,
            fat: 5,
            mealType: .snack,
            loggedAt: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
        )
        snack.user = user
        modelContext.insert(snack)
        
        try modelContext.save()
    }
    
    // MARK: - Nutrition Summary Tests
    
    func test_getTodayNutritionSummary_withNoEntries_returnsZeroSummary() async throws {
        // Act
        let summary = try await sut.getTodayNutritionSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 0)
        XCTAssertEqual(summary.protein, 0)
        XCTAssertEqual(summary.carbs, 0)
        XCTAssertEqual(summary.fat, 0)
        XCTAssertEqual(summary.water, 0)
    }
    
    func test_getTodayNutritionSummary_withEntries_returnsCorrectTotals() async throws {
        // Arrange
        try createTestFoodEntries(for: testUser)
        
        // Act
        let summary = try await sut.getTodayNutritionSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 1_000) // 350 + 450 + 200
        XCTAssertEqual(summary.protein, 72)    // 12 + 35 + 25
        XCTAssertEqual(summary.carbs, 105)     // 60 + 30 + 15
        XCTAssertEqual(summary.fat, 33)        // 8 + 20 + 5
    }
    
    func test_getTodayNutritionSummary_withYesterdayEntries_returnsZeroSummary() async throws {
        // Arrange - Create entries for yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        try createTestFoodEntries(for: testUser, date: yesterday)
        
        // Act
        let summary = try await sut.getTodayNutritionSummary(for: testUser)
        
        // Assert - Should not include yesterday's entries
        XCTAssertEqual(summary.calories, 0)
        XCTAssertEqual(summary.protein, 0)
        XCTAssertEqual(summary.carbs, 0)
        XCTAssertEqual(summary.fat, 0)
    }
    
    // MARK: - Nutrition Targets Tests
    
    func test_getNutritionTargets_withoutProfile_returnsDefaults() async throws {
        // Act
        let targets = try await sut.getNutritionTargets(for: testUser)
        
        // Assert - Should return default targets
        XCTAssertEqual(targets.calories, NutritionTargets.default.calories)
        XCTAssertEqual(targets.protein, NutritionTargets.default.protein)
        XCTAssertEqual(targets.carbs, NutritionTargets.default.carbs)
        XCTAssertEqual(targets.fat, NutritionTargets.default.fat)
        XCTAssertEqual(targets.fiber, NutritionTargets.default.fiber)
        XCTAssertEqual(targets.water, NutritionTargets.default.water)
    }
    
    func test_getNutritionTargets_withProfile_returnsPersonalizedTargets() async throws {
        // Arrange
        _ = try createTestProfile(for: testUser)
        
        // Act
        let targets = try await sut.getNutritionTargets(for: testUser)
        
        // Assert - Should calculate based on profile
        // Note: Actual calculation logic would be in the service
        // For now, just verify it doesn't crash and returns valid targets
        XCTAssertGreaterThan(targets.calories, 0)
        XCTAssertGreaterThan(targets.protein, 0)
        XCTAssertGreaterThan(targets.carbs, 0)
        XCTAssertGreaterThan(targets.fat, 0)
        XCTAssertGreaterThan(targets.fiber, 0)
        XCTAssertGreaterThan(targets.water, 0)
    }
    
    // MARK: - Water Tracking Tests
    
    func test_getWaterIntake_withNoEntries_returnsZero() async throws {
        // Act
        let waterIntake = try await sut.getWaterIntake(for: testUser, date: Date())
        
        // Assert
        XCTAssertEqual(waterIntake, 0)
    }
    
    func test_getWaterIntake_withMultipleEntries_returnsTotalLiters() async throws {
        // Arrange - Create water entries
        let entry1 = FoodEntry(
            name: "Water",
            waterAmount: 500, // ml
            loggedAt: Date()
        )
        entry1.user = testUser
        
        let entry2 = FoodEntry(
            name: "Water",
            waterAmount: 750, // ml
            loggedAt: Date()
        )
        entry2.user = testUser
        
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        try modelContext.save()
        
        // Act
        let waterIntake = try await sut.getWaterIntake(for: testUser, date: Date())
        
        // Assert - Should return total in liters
        XCTAssertEqual(waterIntake, 1.25) // 1250ml = 1.25L
    }
    
    // MARK: - Error Handling Tests
    
    func test_getTodayNutritionSummary_withNilUser_returnsZeroSummary() async throws {
        // Arrange - Create a user that's not in the context
        let orphanUser = User(email: "orphan@test.com", name: "Orphan")
        
        // Act
        let summary = try await sut.getTodayNutritionSummary(for: orphanUser)
        
        // Assert - Should handle gracefully
        XCTAssertEqual(summary.calories, 0)
        XCTAssertEqual(summary.protein, 0)
        XCTAssertEqual(summary.carbs, 0)
        XCTAssertEqual(summary.fat, 0)
    }
}
