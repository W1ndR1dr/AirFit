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
    private var testProfile: OnboardingProfile!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        
        // Create test profile
        let userProfileData = UserProfileJsonBlob(
            lifeContext: LifeContext(
                age: 30,
                height: 175,
                weight: 75,
                exerciseFrequency: 4,
                fitnessLevel: .intermediate,
                isPhysicallyActiveWork: false,
                workLifestyle: .sittingMostly,
                typicalDaySchedule: "Work 9-5, gym in evening",
                sleepHours: 7.5,
                sleepConsistency: .consistent,
                stressLevel: .moderate,
                healthConditions: [],
                injuries: [],
                dietaryRestrictions: [],
                nutritionKnowledge: .basic,
                cookingFrequency: .often,
                mealPrepPreference: true,
                eatingOutFrequency: .rarely,
                favoriteFoods: ["Chicken", "Rice", "Vegetables"],
                dislikedFoods: ["Fish"],
                supplementsTaken: ["Protein powder", "Multivitamin"],
                hydrationHabits: .good,
                alcoholFrequency: .occasionally,
                caffeineIntake: .moderate
            ),
            goal: FitnessGoal(
                type: .buildMuscle,
                specificTarget: "Gain 5 pounds of muscle",
                timeframe: "3 months",
                family: .strengthTone,
                currentChallenge: "Not gaining weight",
                motivations: ["Look better", "Feel stronger"],
                commitmentLevel: .high,
                preferredApproach: .balanced
            ),
            mindset: FitnessMindset(
                motivationStyle: .intrinsic,
                accountabilityPreference: .coach,
                competitiveness: .moderate,
                progressTracking: .detailed,
                plateauResponse: .seekHelp,
                setbackHandling: .learnAndAdjust,
                celebrationStyle: .private,
                learningPreference: .visual,
                decisionMaking: .researched,
                changeAdaptability: .flexible
            ),
            preferences: AppPreferences(
                notificationFrequency: .moderate,
                preferredWorkoutTimes: ["Evening"],
                workoutDuration: 60,
                equipmentAvailable: ["Dumbbells", "Barbell"],
                gymAccess: true,
                homeWorkoutSpace: true,
                musicPreference: .upbeat,
                trainingPartner: false,
                weatherSensitivity: .indifferent,
                travelFrequency: .rarely
            )
        )
        
        let profileData = try JSONEncoder().encode(userProfileData)
        testProfile = OnboardingProfile(
            id: UUID(),
            userId: testUser.id,
            email: testUser.email,
            name: testUser.name,
            age: 30,
            height: 175,
            weight: 75,
            activityLevel: .moderate,
            primaryGoal: .buildMuscle,
            workoutFrequency: 4,
            dietaryRestrictions: [],
            coachPersona: nil,
            rawFullProfileData: profileData,
            createdDate: Date(),
            completedDate: Date()
        )
        
        testUser.onboardingProfile = testProfile
        
        modelContext.insert(testUser)
        modelContext.insert(testProfile)
        try modelContext.save()
        
        // Create service with injected dependencies
        sut = DashboardNutritionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        modelContext = nil
        testUser = nil
        testProfile = nil
        try await super.tearDown()
    }
    
    // MARK: - Get Today's Summary Tests
    
    func test_getTodaysSummary_withNoEntries_returnsZeroValues() async throws {
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 0)
        XCTAssertEqual(summary.protein, 0)
        XCTAssertEqual(summary.carbs, 0)
        XCTAssertEqual(summary.fat, 0)
        XCTAssertEqual(summary.fiber, 0)
        XCTAssertEqual(summary.water, 0)
        XCTAssertEqual(summary.mealCount, 0)
        
        // Targets should still be set
        XCTAssertGreaterThan(summary.caloriesTarget, 0)
        XCTAssertGreaterThan(summary.proteinTarget, 0)
        XCTAssertGreaterThan(summary.carbsTarget, 0)
        XCTAssertGreaterThan(summary.fatTarget, 0)
    }
    
    func test_getTodaysSummary_withSingleEntry_calculatesCorrectly() async throws {
        // Arrange
        let entry = FoodEntry(date: Date(), user: testUser)
        entry.mealType = MealType.breakfast.rawValue
        
        let foodItem = FoodItem(
            name: "Oatmeal",
            calories: 300,
            protein: 10,
            carbs: 50,
            fat: 6,
            fiber: 5,
            entry: entry
        )
        entry.foodItems.append(foodItem)
        
        modelContext.insert(entry)
        modelContext.insert(foodItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 300)
        XCTAssertEqual(summary.protein, 10)
        XCTAssertEqual(summary.carbs, 50)
        XCTAssertEqual(summary.fat, 6)
        XCTAssertEqual(summary.fiber, 5)
        XCTAssertEqual(summary.mealCount, 1)
    }
    
    func test_getTodaysSummary_withMultipleEntries_sumsCorrectly() async throws {
        // Arrange
        let breakfast = FoodEntry(date: Date(), user: testUser)
        breakfast.mealType = MealType.breakfast.rawValue
        let breakfastItem = FoodItem(
            name: "Eggs",
            calories: 200,
            protein: 18,
            carbs: 2,
            fat: 14,
            entry: breakfast
        )
        breakfast.foodItems.append(breakfastItem)
        
        let lunch = FoodEntry(date: Date(), user: testUser)
        lunch.mealType = MealType.lunch.rawValue
        let lunchItem = FoodItem(
            name: "Chicken Salad",
            calories: 400,
            protein: 35,
            carbs: 20,
            fat: 18,
            fiber: 8,
            entry: lunch
        )
        lunch.foodItems.append(lunchItem)
        
        modelContext.insert(breakfast)
        modelContext.insert(breakfastItem)
        modelContext.insert(lunch)
        modelContext.insert(lunchItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 600) // 200 + 400
        XCTAssertEqual(summary.protein, 53) // 18 + 35
        XCTAssertEqual(summary.carbs, 22) // 2 + 20
        XCTAssertEqual(summary.fat, 32) // 14 + 18
        XCTAssertEqual(summary.fiber, 8) // 0 + 8
        XCTAssertEqual(summary.mealCount, 2)
    }
    
    func test_getTodaysSummary_withWaterEntry_tracksWaterIntake() async throws {
        // Arrange
        let entry = FoodEntry(date: Date(), user: testUser)
        let waterItem = FoodItem(
            name: "Water",
            quantity: 3.0, // 3 units
            unit: "cups",
            calories: 0,
            entry: entry
        )
        entry.foodItems.append(waterItem)
        
        modelContext.insert(entry)
        modelContext.insert(waterItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.water, 24) // 3 * 8 oz per unit
    }
    
    func test_getTodaysSummary_excludesYesterdaysEntries() async throws {
        // Arrange
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayEntry = FoodEntry(date: yesterday, user: testUser)
        yesterdayEntry.mealType = MealType.dinner.rawValue
        let yesterdayItem = FoodItem(
            name: "Yesterday's Dinner",
            calories: 500,
            entry: yesterdayEntry
        )
        yesterdayEntry.foodItems.append(yesterdayItem)
        
        let todayEntry = FoodEntry(date: Date(), user: testUser)
        todayEntry.mealType = MealType.breakfast.rawValue
        let todayItem = FoodItem(
            name: "Today's Breakfast",
            calories: 300,
            entry: todayEntry
        )
        todayEntry.foodItems.append(todayItem)
        
        modelContext.insert(yesterdayEntry)
        modelContext.insert(yesterdayItem)
        modelContext.insert(todayEntry)
        modelContext.insert(todayItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 300) // Only today's entry
        XCTAssertEqual(summary.mealCount, 1)
    }
    
    func test_getTodaysSummary_excludesOtherUsersEntries() async throws {
        // Arrange
        let otherUser = User(email: "other@example.com", name: "Other User")
        modelContext.insert(otherUser)
        
        let otherUserEntry = FoodEntry(date: Date(), user: otherUser)
        otherUserEntry.mealType = MealType.lunch.rawValue
        let otherUserItem = FoodItem(
            name: "Other User's Food",
            calories: 1000,
            entry: otherUserEntry
        )
        otherUserEntry.foodItems.append(otherUserItem)
        
        let testUserEntry = FoodEntry(date: Date(), user: testUser)
        testUserEntry.mealType = MealType.lunch.rawValue
        let testUserItem = FoodItem(
            name: "Test User's Food",
            calories: 400,
            entry: testUserEntry
        )
        testUserEntry.foodItems.append(testUserItem)
        
        modelContext.insert(otherUserEntry)
        modelContext.insert(otherUserItem)
        modelContext.insert(testUserEntry)
        modelContext.insert(testUserItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 400) // Only test user's entry
        XCTAssertEqual(summary.mealCount, 1)
    }
    
    // MARK: - Get Targets Tests
    
    func test_getTargets_withBuildMuscleGoal_increasesCalories() async throws {
        // Act
        let targets = try await sut.getTargets(from: testProfile)
        
        // Assert
        // Base calories should be increased for muscle building
        XCTAssertGreaterThan(targets.calories, 2200) // Base * 1.1 for strength/tone
        XCTAssertEqual(targets.protein, targets.calories * 0.30 / 4, accuracy: 0.1)
        XCTAssertEqual(targets.carbs, targets.calories * 0.40 / 4, accuracy: 0.1)
        XCTAssertEqual(targets.fat, targets.calories * 0.30 / 9, accuracy: 0.1)
        XCTAssertEqual(targets.fiber, 25)
        XCTAssertEqual(targets.water, 64)
    }
    
    func test_getTargets_withPhysicallyActiveWork_increasesCalories() async throws {
        // Arrange - Update profile to have physically active work
        let activeProfileData = UserProfileJsonBlob(
            lifeContext: LifeContext(
                age: 30,
                height: 175,
                weight: 75,
                exerciseFrequency: 4,
                fitnessLevel: .intermediate,
                isPhysicallyActiveWork: true, // Active work
                workLifestyle: .veryActive,
                typicalDaySchedule: "Construction work",
                sleepHours: 7.5,
                sleepConsistency: .consistent,
                stressLevel: .moderate,
                healthConditions: [],
                injuries: [],
                dietaryRestrictions: [],
                nutritionKnowledge: .basic,
                cookingFrequency: .often,
                mealPrepPreference: true,
                eatingOutFrequency: .rarely,
                favoriteFoods: [],
                dislikedFoods: [],
                supplementsTaken: [],
                hydrationHabits: .good,
                alcoholFrequency: .occasionally,
                caffeineIntake: .moderate
            ),
            goal: FitnessGoal(
                type: .maintainFitness,
                specificTarget: "Stay healthy",
                timeframe: "ongoing",
                family: .healthWellbeing,
                currentChallenge: "None",
                motivations: ["Health"],
                commitmentLevel: .moderate,
                preferredApproach: .balanced
            ),
            mindset: FitnessMindset(
                motivationStyle: .intrinsic,
                accountabilityPreference: .self,
                competitiveness: .low,
                progressTracking: .basic,
                plateauResponse: .patience,
                setbackHandling: .acceptance,
                celebrationStyle: .private,
                learningPreference: .experiential,
                decisionMaking: .intuitive,
                changeAdaptability: .flexible
            ),
            preferences: AppPreferences(
                notificationFrequency: .minimal,
                preferredWorkoutTimes: ["Morning"],
                workoutDuration: 30,
                equipmentAvailable: [],
                gymAccess: false,
                homeWorkoutSpace: true,
                musicPreference: .none,
                trainingPartner: false,
                weatherSensitivity: .indifferent,
                travelFrequency: .rarely
            )
        )
        
        let activeProfileData = try JSONEncoder().encode(activeProfileData)
        let activeProfile = OnboardingProfile(
            id: UUID(),
            userId: testUser.id,
            email: testUser.email,
            name: testUser.name,
            age: 30,
            height: 175,
            weight: 75,
            activityLevel: .moderate,
            primaryGoal: .maintainFitness,
            workoutFrequency: 4,
            dietaryRestrictions: [],
            coachPersona: nil,
            rawFullProfileData: activeProfileData,
            createdDate: Date(),
            completedDate: Date()
        )
        
        // Act
        let targets = try await sut.getTargets(from: activeProfile)
        
        // Assert
        // Base calories should be increased by 20% for active work
        XCTAssertEqual(targets.calories, 2200 * 1.2, accuracy: 0.1) // 2640
    }
    
    func test_getTargets_withEnduranceGoal_slightlyIncreasesCalories() async throws {
        // Arrange - Create endurance profile
        let enduranceProfileData = UserProfileJsonBlob(
            lifeContext: testProfile.decodedProfile.lifeContext,
            goal: FitnessGoal(
                type: .improveEndurance,
                specificTarget: "Run marathon",
                timeframe: "6 months",
                family: .endurance,
                currentChallenge: "Low stamina",
                motivations: ["Complete marathon"],
                commitmentLevel: .high,
                preferredApproach: .progressive
            ),
            mindset: testProfile.decodedProfile.mindset,
            preferences: testProfile.decodedProfile.preferences
        )
        
        let enduranceData = try JSONEncoder().encode(enduranceProfileData)
        let enduranceProfile = OnboardingProfile(
            id: UUID(),
            userId: testUser.id,
            email: testUser.email,
            name: testUser.name,
            age: 30,
            height: 175,
            weight: 75,
            activityLevel: .moderate,
            primaryGoal: .improveEndurance,
            workoutFrequency: 5,
            dietaryRestrictions: [],
            coachPersona: nil,
            rawFullProfileData: enduranceData,
            createdDate: Date(),
            completedDate: Date()
        )
        
        // Act
        let targets = try await sut.getTargets(from: enduranceProfile)
        
        // Assert
        // Base calories should be increased by 5% for endurance
        XCTAssertEqual(targets.calories, 2200 * 1.05, accuracy: 0.1) // 2310
    }
    
    func test_getTargets_withInvalidProfileData_returnsDefaults() async throws {
        // Arrange - Profile with invalid data
        let invalidProfile = OnboardingProfile(
            id: UUID(),
            userId: testUser.id,
            email: testUser.email,
            name: testUser.name,
            age: 30,
            height: 175,
            weight: 75,
            activityLevel: .moderate,
            primaryGoal: .loseWeight,
            workoutFrequency: 3,
            dietaryRestrictions: [],
            coachPersona: nil,
            rawFullProfileData: Data("invalid json".utf8), // Invalid JSON
            createdDate: Date(),
            completedDate: Date()
        )
        
        // Act
        let targets = try await sut.getTargets(from: invalidProfile)
        
        // Assert - Should return default targets
        XCTAssertEqual(targets.calories, NutritionTargets.default.calories)
        XCTAssertEqual(targets.protein, NutritionTargets.default.protein)
        XCTAssertEqual(targets.carbs, NutritionTargets.default.carbs)
        XCTAssertEqual(targets.fat, NutritionTargets.default.fat)
        XCTAssertEqual(targets.fiber, NutritionTargets.default.fiber)
        XCTAssertEqual(targets.water, NutritionTargets.default.water)
    }
    
    // MARK: - Edge Cases
    
    func test_getTodaysSummary_withEntriesWithoutMealType_countsCorrectly() async throws {
        // Arrange
        let entryWithType = FoodEntry(date: Date(), user: testUser)
        entryWithType.mealType = MealType.lunch.rawValue
        
        let entryWithoutType = FoodEntry(date: Date(), user: testUser)
        entryWithoutType.mealType = nil // No meal type
        
        modelContext.insert(entryWithType)
        modelContext.insert(entryWithoutType)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.mealCount, 1) // Only count entries with meal type
    }
    
    func test_getTodaysSummary_withMultipleWaterItems_sumsCorrectly() async throws {
        // Arrange
        let entry = FoodEntry(date: Date(), user: testUser)
        
        let water1 = FoodItem(
            name: "Water",
            quantity: 2.0,
            calories: 0,
            entry: entry
        )
        let water2 = FoodItem(
            name: "Sparkling Water",
            quantity: 1.5,
            calories: 0,
            entry: entry
        )
        let water3 = FoodItem(
            name: "Lemon Water",
            quantity: 1.0,
            calories: 5,
            entry: entry
        )
        
        entry.foodItems = [water1, water2, water3]
        
        modelContext.insert(entry)
        for item in [water1, water2, water3] {
            modelContext.insert(item)
        }
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.water, 36) // (2 + 1.5 + 1) * 8 = 36
        XCTAssertEqual(summary.calories, 5) // Only lemon water has calories
    }
    
    // MARK: - Performance Tests
    
    func test_getTodaysSummary_withManyEntries_performsWell() async throws {
        // Arrange - Create 20 entries for today
        for i in 0..<20 {
            let entry = FoodEntry(date: Date(), user: testUser)
            entry.mealType = MealType.snack.rawValue
            
            let item = FoodItem(
                name: "Snack \(i)",
                calories: 100,
                protein: 5,
                carbs: 10,
                fat: 3,
                entry: entry
            )
            entry.foodItems.append(item)
            
            modelContext.insert(entry)
            modelContext.insert(item)
        }
        try modelContext.save()
        
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        let summary = try await sut.getTodaysSummary(for: testUser)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertEqual(summary.calories, 2000) // 20 * 100
        XCTAssertEqual(summary.mealCount, 20)
        XCTAssertLessThan(duration, 0.5, "Should calculate summary quickly")
    }
    
    // MARK: - Integration Tests
    
    func test_getTodaysSummary_withCompleteDay_providesAccurateSummary() async throws {
        // Arrange - Create a full day of meals
        let breakfast = FoodEntry(date: Date(), user: testUser)
        breakfast.mealType = MealType.breakfast.rawValue
        let breakfastItems = [
            FoodItem(name: "Oatmeal", calories: 300, protein: 10, carbs: 50, fat: 6, fiber: 5, entry: breakfast),
            FoodItem(name: "Banana", calories: 105, protein: 1, carbs: 27, fat: 0, fiber: 3, entry: breakfast),
            FoodItem(name: "Almond Milk", calories: 40, protein: 1, carbs: 3, fat: 3, entry: breakfast)
        ]
        breakfast.foodItems = breakfastItems
        
        let lunch = FoodEntry(date: Date(), user: testUser)
        lunch.mealType = MealType.lunch.rawValue
        let lunchItems = [
            FoodItem(name: "Grilled Chicken", calories: 250, protein: 40, carbs: 0, fat: 8, entry: lunch),
            FoodItem(name: "Brown Rice", calories: 215, protein: 5, carbs: 45, fat: 2, fiber: 4, entry: lunch),
            FoodItem(name: "Steamed Broccoli", calories: 55, protein: 4, carbs: 11, fat: 0, fiber: 5, entry: lunch)
        ]
        lunch.foodItems = lunchItems
        
        let dinner = FoodEntry(date: Date(), user: testUser)
        dinner.mealType = MealType.dinner.rawValue
        let dinnerItems = [
            FoodItem(name: "Salmon", calories: 350, protein: 35, carbs: 0, fat: 20, entry: dinner),
            FoodItem(name: "Sweet Potato", calories: 180, protein: 4, carbs: 41, fat: 0, fiber: 6, entry: dinner),
            FoodItem(name: "Mixed Salad", calories: 100, protein: 3, carbs: 10, fat: 7, fiber: 4, entry: dinner)
        ]
        dinner.foodItems = dinnerItems
        
        let snack = FoodEntry(date: Date(), user: testUser)
        snack.mealType = MealType.snack.rawValue
        let snackItems = [
            FoodItem(name: "Protein Shake", calories: 200, protein: 30, carbs: 10, fat: 3, entry: snack),
            FoodItem(name: "Apple", calories: 95, protein: 0, carbs: 25, fat: 0, fiber: 4, entry: snack)
        ]
        snack.foodItems = snackItems
        
        // Water entries
        let waterEntry = FoodEntry(date: Date(), user: testUser)
        let waterItem = FoodItem(name: "Water", quantity: 8.0, calories: 0, entry: waterEntry)
        waterEntry.foodItems = [waterItem]
        
        // Insert all entries
        for entry in [breakfast, lunch, dinner, snack, waterEntry] {
            modelContext.insert(entry)
            for item in entry.foodItems {
                modelContext.insert(item)
            }
        }
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert totals
        XCTAssertEqual(summary.calories, 2090) // Sum of all calories
        XCTAssertEqual(summary.protein, 133) // Sum of all protein
        XCTAssertEqual(summary.carbs, 237) // Sum of all carbs
        XCTAssertEqual(summary.fat, 49) // Sum of all fat
        XCTAssertEqual(summary.fiber, 31) // Sum of all fiber
        XCTAssertEqual(summary.water, 64) // 8 * 8 oz
        XCTAssertEqual(summary.mealCount, 4) // Breakfast, lunch, dinner, snack (not water entry)
        
        // Verify targets are reasonable
        XCTAssertGreaterThan(summary.caloriesTarget, 2000)
        XCTAssertGreaterThan(summary.proteinTarget, 100)
        XCTAssertGreaterThan(summary.carbsTarget, 200)
        XCTAssertGreaterThan(summary.fatTarget, 50)
    }
}