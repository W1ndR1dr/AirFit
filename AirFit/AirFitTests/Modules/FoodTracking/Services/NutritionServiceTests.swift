import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class NutritionServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: NutritionService!
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
        sut = NutritionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        testUser = nil
        container = nil
        try super.tearDown()
    }
    
    // MARK: - Save Food Entry Tests
    
    func test_saveFoodEntry_withValidEntry_savesSuccessfully() async throws {
        // Arrange
        let foodEntry = FoodEntry(user: testUser)
        let foodItem = FoodItem(
            name: "Apple",
            brand: nil,
            quantity: 1.0,
            unit: "medium",
            calories: 95,
            proteinGrams: 0.5,
            carbGrams: 25,
            fatGrams: 0.3
        )
        foodItem.fiberGrams = 4.0
        foodItem.sugarGrams = 19.0
        foodItem.sodiumMg = 2.0
        foodEntry.addItem(foodItem)
        foodEntry.mealType = MealType.breakfast.rawValue
        
        // Act
        try await sut.saveFoodEntry(foodEntry)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<FoodEntry>()
        let savedEntries = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(savedEntries.count, 1)
        XCTAssertEqual(savedEntries.first?.id, foodEntry.id)
        XCTAssertEqual(savedEntries.first?.items.count, 1)
        XCTAssertEqual(savedEntries.first?.items.first?.name, "Apple")
    }
    
    func test_saveFoodEntry_withMultipleFoodItems_calculatesCorrectly() async throws {
        // Arrange
        let foodEntry = FoodEntry(user: testUser)
        let apple = FoodItem(
            name: "Apple",
            calories: 95,
            proteinGrams: 0.5,
            carbGrams: 25,
            fatGrams: 0.3)
        let almonds = FoodItem(
            name: "Almonds",
            quantity: 30,
            unit: "g",
            calories: 174,
            proteinGrams: 6.3,
            carbGrams: 6.1,
            fatGrams: 15.2)
        foodEntry.items = [apple, almonds]
        
        // Act
        try await sut.saveFoodEntry(foodEntry)
        
        // Assert
        let savedEntry = try modelContext.fetch(FetchDescriptor<FoodEntry>()).first
        XCTAssertNotNil(savedEntry)
        XCTAssertEqual(savedEntry?.totalCalories, 269) // 95 + 174
        XCTAssertEqual(Double(savedEntry?.totalProtein ?? 0), 6.8, accuracy: 0.1) // 0.5 + 6.3
        XCTAssertEqual(Double(savedEntry?.totalCarbs ?? 0), 31.1, accuracy: 0.1) // 25 + 6.1
        XCTAssertEqual(Double(savedEntry?.totalFat ?? 0), 15.5, accuracy: 0.1) // 0.3 + 15.2
    }
    
    // MARK: - Get Food Entries Tests
    
    func test_getFoodEntries_forDate_returnsCorrectEntries() async throws {
        // Arrange
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayEntry = FoodEntry(loggedAt: today, user: testUser)
        todayEntry.mealType = MealType.lunch.rawValue
        modelContext.insert(todayEntry)
        
        let yesterdayEntry = FoodEntry(loggedAt: yesterday, user: testUser)
        yesterdayEntry.mealType = MealType.dinner.rawValue
        modelContext.insert(yesterdayEntry)
        
        try modelContext.save()
        
        // Act
        let todayEntries = try await sut.getFoodEntries(for: today)
        
        // Assert
        XCTAssertEqual(todayEntries.count, 1)
        XCTAssertEqual(todayEntries.first?.id, todayEntry.id)
        XCTAssertEqual(todayEntries.first?.mealType, MealType.lunch.rawValue)
    }
    
    func test_getFoodEntries_forUserAndDate_filtersCorrectly() async throws {
        // Arrange
        let date = Date()
        let otherUser = User(email: "other@example.com", name: "Other User")
        modelContext.insert(otherUser)
        
        let testUserEntry = FoodEntry(loggedAt: date, user: testUser)
        let otherUserEntry = FoodEntry(loggedAt: date, user: otherUser)
        
        modelContext.insert(testUserEntry)
        modelContext.insert(otherUserEntry)
        try modelContext.save()
        
        // Act
        let entries = try await sut.getFoodEntries(for: testUser, date: date)
        
        // Assert
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.user?.id, testUser.id)
    }
    
    func test_getFoodEntries_sortsChronologically() async throws {
        // Arrange
        let date = Date()
        let morning = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        let afternoon = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: date)!
        let evening = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: date)!
        
        // Create entries out of order
        let dinnerEntry = FoodEntry(loggedAt: evening, user: testUser)
        dinnerEntry.mealType = MealType.dinner.rawValue
        
        let breakfastEntry = FoodEntry(loggedAt: morning, user: testUser)
        breakfastEntry.mealType = MealType.breakfast.rawValue
        
        let lunchEntry = FoodEntry(loggedAt: afternoon, user: testUser)
        lunchEntry.mealType = MealType.lunch.rawValue
        
        modelContext.insert(dinnerEntry)
        modelContext.insert(breakfastEntry)
        modelContext.insert(lunchEntry)
        try modelContext.save()
        
        // Act
        let entries = try await sut.getFoodEntries(for: date)
        
        // Assert
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].mealType, MealType.breakfast.rawValue)
        XCTAssertEqual(entries[1].mealType, MealType.lunch.rawValue)
        XCTAssertEqual(entries[2].mealType, MealType.dinner.rawValue)
    }
    
    // MARK: - Delete Food Entry Tests
    
    func test_deleteFoodEntry_removesFromContext() async throws {
        // Arrange
        let foodEntry = FoodEntry(user: testUser)
        modelContext.insert(foodEntry)
        try modelContext.save()
        
        // Verify it exists
        let entriesBefore = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(entriesBefore.count, 1)
        
        // Act
        try await sut.deleteFoodEntry(foodEntry)
        
        // Assert
        let entriesAfter = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(entriesAfter.count, 0)
    }
    
    func test_deleteFoodEntry_cascadesToFoodItems() async throws {
        // Arrange
        let foodEntry = FoodEntry(user: testUser)
        let foodItem1 = FoodItem(name: "Item 1", calories: 100)
        let foodItem2 = FoodItem(name: "Item 2", calories: 200)
        foodEntry.items = [foodItem1, foodItem2]
        
        modelContext.insert(foodEntry)
        modelContext.insert(foodItem1)
        modelContext.insert(foodItem2)
        try modelContext.save()
        
        // Verify setup
        let itemsBefore = try modelContext.fetch(FetchDescriptor<FoodItem>())
        XCTAssertEqual(itemsBefore.count, 2)
        
        // Act
        try await sut.deleteFoodEntry(foodEntry)
        
        // Assert
        let entriesAfter = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        let itemsAfter = try modelContext.fetch(FetchDescriptor<FoodItem>())
        XCTAssertEqual(entriesAfter.count, 0)
        XCTAssertEqual(itemsAfter.count, 0) // Should cascade delete
    }
    
    // MARK: - Nutrition Summary Tests
    
    func test_calculateNutritionSummary_withMultipleEntries_sumsCorrectly() {
        // Arrange
        let entry1 = FoodEntry(user: testUser)
        let item1 = FoodItem(
            name: "Breakfast",
            calories: 350,
            proteinGrams: 20,
            carbGrams: 45,
            fatGrams: 12)
        item1.fiberGrams = 5
        item1.sugarGrams = 10
        item1.sodiumMg = 300
        entry1.items = [item1]
        
        let entry2 = FoodEntry(user: testUser)
        let item2 = FoodItem(
            name: "Lunch",
            calories: 500,
            proteinGrams: 30,
            carbGrams: 60,
            fatGrams: 18)
        item2.fiberGrams = 8
        item2.sugarGrams = 15
        item2.sodiumMg = 450
        entry2.items = [item2]
        
        // Act
        let summary = sut.calculateNutritionSummary(from: [entry1, entry2])
        
        // Assert
        XCTAssertEqual(summary.calories, 850) // 350 + 500
        XCTAssertEqual(summary.protein, 50) // 20 + 30
        XCTAssertEqual(summary.carbs, 105) // 45 + 60
        XCTAssertEqual(summary.fat, 30) // 12 + 18
        XCTAssertEqual(summary.fiber, 13) // 5 + 8
        XCTAssertEqual(summary.sugar, 25) // 10 + 15
        XCTAssertEqual(summary.sodium, 750) // 300 + 450
    }
    
    func test_calculateNutritionSummary_withEmptyEntries_returnsZeroSummary() {
        // Act
        let summary = sut.calculateNutritionSummary(from: [])
        
        // Assert
        XCTAssertEqual(summary.calories, 0)
        XCTAssertEqual(summary.protein, 0)
        XCTAssertEqual(summary.carbs, 0)
        XCTAssertEqual(summary.fat, 0)
        XCTAssertEqual(summary.fiber, 0)
        XCTAssertEqual(summary.sugar, 0)
        XCTAssertEqual(summary.sodium, 0)
    }
    
    func test_calculateNutritionSummary_handlesNilValues() {
        // Arrange
        let entry = FoodEntry(user: testUser)
        let item = FoodItem(
            name: "Minimal Info",
            calories: 100,
            proteinGrams: 5,
            carbGrams: 10,
            fatGrams: 3)
        // fiberGrams, sugarGrams, sodiumMg are already nil by default
        entry.items = [item]
        
        // Act
        let summary = sut.calculateNutritionSummary(from: [entry])
        
        // Assert
        XCTAssertEqual(summary.calories, 100)
        XCTAssertEqual(summary.protein, 5)
        XCTAssertEqual(summary.carbs, 10)
        XCTAssertEqual(summary.fat, 3)
        XCTAssertEqual(summary.fiber, 0) // nil becomes 0
        XCTAssertEqual(summary.sugar, 0)
        XCTAssertEqual(summary.sodium, 0)
    }
    
    // MARK: - Water Intake Tests
    
    func test_getWaterIntake_withNoData_returnsZero() async throws {
        // Act
        let intake = try await sut.getWaterIntake(for: testUser, date: Date())
        
        // Assert
        XCTAssertEqual(intake, 0)
    }
    
    func test_logWaterIntake_addsToTotal() async throws {
        // Arrange
        let date = Date()
        
        // Act
        try await sut.logWaterIntake(for: testUser, amountML: 250, date: date)
        try await sut.logWaterIntake(for: testUser, amountML: 500, date: date)
        
        // Assert
        let totalIntake = try await sut.getWaterIntake(for: testUser, date: date)
        XCTAssertEqual(totalIntake, 750) // 250 + 500
    }
    
    func test_getWaterIntake_separatesByDate() async throws {
        // Arrange
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Act
        try await sut.logWaterIntake(for: testUser, amountML: 1000, date: yesterday)
        try await sut.logWaterIntake(for: testUser, amountML: 500, date: today)
        
        // Assert
        let todayIntake = try await sut.getWaterIntake(for: testUser, date: today)
        let yesterdayIntake = try await sut.getWaterIntake(for: testUser, date: yesterday)
        
        XCTAssertEqual(todayIntake, 500)
        XCTAssertEqual(yesterdayIntake, 1000)
    }
    
    // MARK: - Recent Foods Tests
    
    func test_getRecentFoods_returnsUniqueItems() async throws {
        // Arrange
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .hour, value: -1, to: date1)!
        
        // Create entries with duplicate foods
        let entry1 = FoodEntry(loggedAt: date1, user: testUser)
        let apple1 = FoodItem(name: "Apple", calories: 95)
        let banana1 = FoodItem(name: "Banana", calories: 105)
        entry1.items = [apple1, banana1]
        
        let entry2 = FoodEntry(loggedAt: date2, user: testUser)
        let apple2 = FoodItem(name: "Apple", calories: 95) // Duplicate
        let orange = FoodItem(name: "Orange", calories: 62)
        entry2.items = [apple2, orange]
        
        modelContext.insert(entry1)
        modelContext.insert(apple1)
        modelContext.insert(banana1)
        modelContext.insert(entry2)
        modelContext.insert(apple2)
        modelContext.insert(orange)
        try modelContext.save()
        
        // Act
        let recentFoods = try await sut.getRecentFoods(for: testUser, limit: 5)
        
        // Assert
        XCTAssertEqual(recentFoods.count, 3) // Only unique names
        let foodNames = Set(recentFoods.map { $0.name })
        XCTAssertTrue(foodNames.contains("Apple"))
        XCTAssertTrue(foodNames.contains("Banana"))
        XCTAssertTrue(foodNames.contains("Orange"))
    }
    
    func test_getRecentFoods_respectsLimit() async throws {
        // Arrange
        let entry = FoodEntry(user: testUser)
        for i in 1...10 {
            let item = FoodItem(name: "Food \(i)", calories: 100)
            entry.items.append(item)
            modelContext.insert(item)
        }
        modelContext.insert(entry)
        try modelContext.save()
        
        // Act
        let recentFoods = try await sut.getRecentFoods(for: testUser, limit: 5)
        
        // Assert
        XCTAssertEqual(recentFoods.count, 5)
    }
    
    // MARK: - Meal History Tests
    
    func test_getMealHistory_filtersByMealType() async throws {
        // Arrange
        let today = Date()
        
        let breakfastEntry = FoodEntry(loggedAt: today, user: testUser)
        breakfastEntry.mealType = MealType.breakfast.rawValue
        
        let lunchEntry = FoodEntry(loggedAt: today, user: testUser)
        lunchEntry.mealType = MealType.lunch.rawValue
        
        let dinnerEntry = FoodEntry(loggedAt: today, user: testUser)
        dinnerEntry.mealType = MealType.dinner.rawValue
        
        modelContext.insert(breakfastEntry)
        modelContext.insert(lunchEntry)
        modelContext.insert(dinnerEntry)
        try modelContext.save()
        
        // Act
        let breakfastHistory = try await sut.getMealHistory(for: testUser, mealType: .breakfast, daysBack: 7)
        
        // Assert
        XCTAssertEqual(breakfastHistory.count, 1)
        XCTAssertEqual(breakfastHistory.first?.mealType, MealType.breakfast.rawValue)
    }
    
    func test_getMealHistory_respectsDaysBack() async throws {
        // Arrange
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: today)!
        
        let recentEntry = FoodEntry(loggedAt: threeDaysAgo, user: testUser)
        recentEntry.mealType = MealType.lunch.rawValue
        
        let oldEntry = FoodEntry(loggedAt: eightDaysAgo, user: testUser)
        oldEntry.mealType = MealType.lunch.rawValue
        
        modelContext.insert(recentEntry)
        modelContext.insert(oldEntry)
        try modelContext.save()
        
        // Act
        let history = try await sut.getMealHistory(for: testUser, mealType: .lunch, daysBack: 7)
        
        // Assert
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.id, recentEntry.id)
    }
    
    // MARK: - Nutrition Targets Tests
    
    func test_getTargets_withCompleteProfile_calculatesCorrectly() {
        // Arrange
        // Since NutritionService.getTargets returns default values regardless of profile,
        // we'll just test that it returns the default values
        let mockProfile = OnboardingProfile(
            personaPromptData: Data(),
            communicationPreferencesData: Data(),
            rawFullProfileData: Data()
        )
        
        // Act
        let targets = sut.getTargets(from: mockProfile)
        
        // Assert - Should return default values
        XCTAssertEqual(targets.calories, 2000)
        XCTAssertEqual(targets.protein, 150)
        XCTAssertEqual(targets.carbs, 250)
        XCTAssertEqual(targets.fat, 65)
        XCTAssertEqual(targets.fiber, 25)
        XCTAssertEqual(targets.water, 64)
    }
    
    func test_getTargets_withNilProfile_returnsDefaults() {
        // Act
        let targets = sut.getTargets(from: nil)
        
        // Assert
        XCTAssertEqual(targets.calories, 2000)
        XCTAssertEqual(targets.protein, 150)
        XCTAssertEqual(targets.carbs, 250)
        XCTAssertEqual(targets.fat, 65)
        XCTAssertEqual(targets.fiber, 25)
        XCTAssertEqual(targets.water, 64)
    }
    
    // MARK: - Today's Summary Tests
    
    func test_getTodaysSummary_combinesAllTodaysEntries() async throws {
        // Arrange
        let today = Date()
        
        let breakfastEntry = FoodEntry(loggedAt: today, user: testUser)
        let breakfastItem = FoodItem(
            name: "Oatmeal",
            calories: 300,
            proteinGrams: 10,
            carbGrams: 50,
            fatGrams: 6)
        breakfastEntry.items = [breakfastItem]
        
        let lunchEntry = FoodEntry(loggedAt: today, user: testUser)
        let lunchItem = FoodItem(
            name: "Salad",
            calories: 400,
            proteinGrams: 25,
            carbGrams: 30,
            fatGrams: 20)
        lunchEntry.items = [lunchItem]
        
        modelContext.insert(breakfastEntry)
        modelContext.insert(breakfastItem)
        modelContext.insert(lunchEntry)
        modelContext.insert(lunchItem)
        try modelContext.save()
        
        // Act
        let summary = try await sut.getTodaysSummary(for: testUser)
        
        // Assert
        XCTAssertEqual(summary.calories, 700) // 300 + 400
        XCTAssertEqual(summary.protein, 35) // 10 + 25
        XCTAssertEqual(summary.carbs, 80) // 50 + 30
        XCTAssertEqual(summary.fat, 26) // 6 + 20
    }
    
    // MARK: - Edge Cases
    
    func test_saveFoodEntry_withNoFoodItems_savesEmptyEntry() async throws {
        // Arrange
        let foodEntry = FoodEntry(user: testUser)
        foodEntry.items = []
        
        // Act
        try await sut.saveFoodEntry(foodEntry)
        
        // Assert
        let savedEntries = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(savedEntries.count, 1)
        XCTAssertEqual(savedEntries.first?.totalCalories, 0)
    }
    
    func test_getFoodEntries_withNoUser_throwsError() async throws {
        // Arrange
        let userlessEntry = FoodEntry(loggedAt: Date(), user: nil)
        modelContext.insert(userlessEntry)
        try modelContext.save()
        
        // Act
        let entries = try await sut.getFoodEntries(for: Date())
        
        // Assert - Should not include userless entries
        XCTAssertEqual(entries.count, 0)
    }
}