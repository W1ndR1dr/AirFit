import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class FoodTrackingViewModelTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var testUser: User!
    private var mockFoodVoiceAdapter: MockFoodVoiceAdapter!
    private var mockNutritionService: MockNutritionService!
    private var mockCoachEngine: MockCoachEngine!
    private var coordinator: FoodTrackingCoordinator!
    private var sut: FoodTrackingViewModel!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get dependencies from container
        modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user with profile
        testUser = User(email: "test@example.com", name: "Test User")
        let emptyData = Data()
        let onboardingProfile = OnboardingProfile(
            personaPromptData: emptyData,
            communicationPreferencesData: emptyData,
            rawFullProfileData: emptyData,
            user: testUser
        )
        onboardingProfile.isComplete = true
        testUser.onboardingProfile = onboardingProfile
        modelContext.insert(testUser)
        modelContext.insert(onboardingProfile)
        try modelContext.save()
        
        // Get mocks from container
        mockFoodVoiceAdapter = try await container.resolve(FoodVoiceAdapterProtocol.self) as? MockFoodVoiceAdapter
        XCTAssertNotNil(mockFoodVoiceAdapter, "Expected MockFoodVoiceAdapter from test container")
        
        mockNutritionService = try await container.resolve(NutritionServiceProtocol.self) as? MockNutritionService
        XCTAssertNotNil(mockNutritionService, "Expected MockNutritionService from test container")
        
        mockCoachEngine = try await container.resolve(CoachEngineProtocol.self) as? MockCoachEngine
        XCTAssertNotNil(mockCoachEngine, "Expected MockCoachEngine from test container")
        
        coordinator = FoodTrackingCoordinator()
        
        // Create view model with injected dependencies
        sut = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: mockNutritionService,
            coachEngine: mockCoachEngine,
            coordinator: coordinator
        )
    }
    
    override func tearDown() async throws {
        mockFoodVoiceAdapter?.reset()
        mockNutritionService?.reset()
        mockCoachEngine?.reset()
        sut = nil
        coordinator = nil
        mockCoachEngine = nil
        mockNutritionService = nil
        mockFoodVoiceAdapter = nil
        testUser = nil
        modelContext = nil
        modelContainer = nil
        container = nil
        try super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func createSampleParsedItem(name: String = "Apple", calories: Int = 95, confidence: Float = 0.9) -> ParsedFoodItem {
        ParsedFoodItem(
            name: name,
            brand: "TestBrand",
            quantity: 1,
            unit: "medium",
            calories: calories,
            proteinGrams: 0.5,
            carbGrams: 25,
            fatGrams: 0.3,
            fiberGrams: nil,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            databaseId: nil,
            confidence: confidence
        )
    }
    
    private func createSampleFoodDatabaseItem(id: String = "db_apple", name: String = "Apple", calories: Double = 95) -> FoodDatabaseItem {
        FoodDatabaseItem(
            id: id,
            name: name,
            brand: "DBBrand",
            caloriesPerServing: calories,
            proteinPerServing: 0.5,
            carbsPerServing: 25,
            fatPerServing: 0.3,
            servingSize: 1,
            servingUnit: "medium",
            defaultQuantity: 1,
            defaultUnit: "medium"
        )
    }
    
    private func createSampleFoodItem(name: String = "Logged Apple") -> FoodItem {
        FoodItem(name: name, quantity: 1, unit: "item", calories: 100, proteinGrams: 1, carbGrams: 20, fatGrams: 2)
    }
    
    // MARK: - Initialization and Data Loading Tests
    
    func test_init_loadsInitialDataViaSetNutritionService() async throws {
        // Arrange
        mockNutritionService.recentFoodsToReturn = [createSampleFoodItem(name: "Recent Banana")]
        
        // Re-init SUT to test initial loading
        sut = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: mockNutritionService,
            coachEngine: mockCoachEngine,
            coordinator: coordinator
        )
        
        // Act
        await sut.loadTodaysData()
        
        // Assert
        XCTAssertFalse(sut.recentFoods.isEmpty, "Recent foods should be populated")
        XCTAssertEqual(sut.recentFoods.first?.name, "Recent Banana")
    }
    
    func test_setNutritionService_loadsDataWithNewService() async throws {
        // Arrange
        let newService = MockNutritionService()
        newService.recentFoodsToReturn = [createSampleFoodItem(name: "New Service Banana")]
        
        // Act
        sut.setNutritionService(newService)
        await sut.loadTodaysData()
        
        // Assert
        XCTAssertFalse(sut.recentFoods.isEmpty)
        XCTAssertEqual(sut.recentFoods.first?.name, "New Service Banana")
    }
    
    func test_loadTodaysData_populatesUIFromNutritionService() async throws {
        // Arrange
        mockNutritionService.recentFoodsToReturn = [createSampleFoodItem()]
        
        // Act
        await sut.loadTodaysData()
        
        // Assert
        XCTAssertFalse(sut.recentFoods.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Voice Input Tests
    
    func test_startVoiceInput_callsAdapter() async throws {
        // Act
        await sut.startVoiceInput()
        
        // Assert
        XCTAssertTrue(mockFoodVoiceAdapter.startRecordingCalled)
    }
    
    func test_stopVoiceInput_callsAdapter() async throws {
        // Act
        await sut.stopVoiceInput()
        
        // Assert
        XCTAssertTrue(mockFoodVoiceAdapter.stopRecordingCalled)
    }
    
    func test_processVoiceInput_success_parsesFoodAndUpdatesUI() async throws {
        // Arrange
        let parsedItem = createSampleParsedItem()
        mockFoodVoiceAdapter.parsedItemsToReturn = [parsedItem]
        mockFoodVoiceAdapter.errorToThrow = nil
        
        // Act
        await sut.processVoiceInput()
        
        // Assert
        XCTAssertFalse(sut.pendingFoodItems.isEmpty)
        XCTAssertEqual(sut.pendingFoodItems.first?.name, "Apple")
        XCTAssertFalse(sut.isProcessingVoice)
        XCTAssertNil(sut.voiceError)
    }
    
    func test_processVoiceInput_failure_setsError() async throws {
        // Arrange
        mockFoodVoiceAdapter.parsedItemsToReturn = []
        mockFoodVoiceAdapter.errorToThrow = MockError(message: "Voice processing failed")
        
        // Act
        await sut.processVoiceInput()
        
        // Assert
        XCTAssertTrue(sut.pendingFoodItems.isEmpty)
        XCTAssertNotNil(sut.voiceError)
        XCTAssertFalse(sut.isProcessingVoice)
    }
    
    // MARK: - Text Input Tests
    
    func test_parseTextInput_success_updatesPendingItems() async throws {
        // Arrange
        let parsedItem = createSampleParsedItem(name: "Chicken Breast", calories: 165)
        mockNutritionService.stubbedParseTextInputResult = .success([parsedItem])
        
        // Act
        await sut.parseTextInput("chicken breast 100g")
        
        // Assert
        XCTAssertFalse(sut.pendingFoodItems.isEmpty)
        XCTAssertEqual(sut.pendingFoodItems.first?.name, "Chicken Breast")
        XCTAssertEqual(sut.pendingFoodItems.first?.calories, 165)
        XCTAssertFalse(sut.isProcessingText)
    }
    
    func test_parseTextInput_failure_setsError() async throws {
        // Arrange
        mockNutritionService.stubbedParseTextInputResult = .failure(MockError(message: "Parse failed"))
        
        // Act
        await sut.parseTextInput("invalid food")
        
        // Assert
        XCTAssertTrue(sut.pendingFoodItems.isEmpty)
        XCTAssertNotNil(sut.textError)
        XCTAssertFalse(sut.isProcessingText)
    }
    
    // MARK: - Food Confirmation Tests
    
    func test_confirmFoodItem_addsToTodaysEntries() async throws {
        // Arrange
        let parsedItem = createSampleParsedItem()
        sut.pendingFoodItems = [parsedItem]
        sut.selectedMealType = .breakfast
        
        // Act
        await sut.confirmFoodItem(parsedItem)
        
        // Assert
        XCTAssertTrue(sut.pendingFoodItems.isEmpty)
        XCTAssertTrue(sut.todaysMealsByType[.breakfast] != nil)
        XCTAssertFalse(sut.todaysMealsByType[.breakfast]!.foodItems.isEmpty)
        XCTAssertEqual(sut.todaysMealsByType[.breakfast]!.foodItems.first?.name, "Apple")
    }
    
    func test_confirmMultipleItems_addsAllToSameMeal() async throws {
        // Arrange
        let item1 = createSampleParsedItem(name: "Apple", calories: 95)
        let item2 = createSampleParsedItem(name: "Banana", calories: 105)
        sut.pendingFoodItems = [item1, item2]
        sut.selectedMealType = .lunch
        
        // Act
        await sut.confirmFoodItem(item1)
        await sut.confirmFoodItem(item2)
        
        // Assert
        XCTAssertTrue(sut.pendingFoodItems.isEmpty)
        XCTAssertEqual(sut.todaysMealsByType[.lunch]?.foodItems.count, 2)
    }
    
    func test_updateFoodItem_modifiesExistingItem() throws {
        // Arrange
        let parsedItem = createSampleParsedItem()
        sut.pendingFoodItems = [parsedItem]
        
        // Act
        sut.updateFoodItem(parsedItem, quantity: 2, unit: "large")
        
        // Assert
        XCTAssertEqual(sut.pendingFoodItems.first?.quantity, 2)
        XCTAssertEqual(sut.pendingFoodItems.first?.unit, "large")
    }
    
    func test_removePendingItem_removesFromList() throws {
        // Arrange
        let item1 = createSampleParsedItem(name: "Apple")
        let item2 = createSampleParsedItem(name: "Banana")
        sut.pendingFoodItems = [item1, item2]
        
        // Act
        sut.removePendingItem(item1)
        
        // Assert
        XCTAssertEqual(sut.pendingFoodItems.count, 1)
        XCTAssertEqual(sut.pendingFoodItems.first?.name, "Banana")
    }
    
    // MARK: - Search Tests
    
    func test_searchFoods_success_updatesSearchResults() async throws {
        // Arrange
        let dbItem = createSampleFoodDatabaseItem()
        mockNutritionService.stubbedSearchFoodsResult = .success([dbItem])
        
        // Act
        await sut.searchFoods(query: "apple")
        
        // Assert
        XCTAssertFalse(sut.searchResults.isEmpty)
        XCTAssertEqual(sut.searchResults.first?.name, "Apple")
        XCTAssertFalse(sut.isSearching)
    }
    
    func test_searchFoods_emptyQuery_clearsResults() async throws {
        // Arrange
        sut.searchResults = [createSampleFoodDatabaseItem()]
        
        // Act
        await sut.searchFoods(query: "")
        
        // Assert
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }
    
    func test_selectSearchResult_addsToPendingItems() throws {
        // Arrange
        let dbItem = createSampleFoodDatabaseItem()
        sut.searchResults = [dbItem]
        
        // Act
        sut.selectSearchResult(dbItem)
        
        // Assert
        XCTAssertFalse(sut.pendingFoodItems.isEmpty)
        XCTAssertEqual(sut.pendingFoodItems.first?.name, "Apple")
        XCTAssertEqual(sut.pendingFoodItems.first?.databaseId, "db_apple")
    }
    
    // MARK: - Quick Add Tests
    
    func test_quickAddRecentFood_addsToTodaysMeal() async throws {
        // Arrange
        let recentItem = createSampleFoodItem()
        sut.recentFoods = [recentItem]
        sut.selectedMealType = .snack
        
        // Act
        await sut.quickAddRecentFood(recentItem)
        
        // Assert
        XCTAssertNotNil(sut.todaysMealsByType[.snack])
        XCTAssertEqual(sut.todaysMealsByType[.snack]?.foodItems.first?.name, "Logged Apple")
    }
    
    // MARK: - Water Tracking Tests
    
    func test_logWater_updatesWaterIntake() async throws {
        // Act
        await sut.logWater(amount: 16, unit: .ounces)
        
        // Assert
        XCTAssertEqual(sut.todayWaterOunces, 16)
    }
    
    func test_logWater_accumulates() async throws {
        // Act
        await sut.logWater(amount: 8, unit: .ounces)
        await sut.logWater(amount: 12, unit: .ounces)
        
        // Assert
        XCTAssertEqual(sut.todayWaterOunces, 20)
    }
    
    func test_logWater_convertsUnits() async throws {
        // Act
        await sut.logWater(amount: 500, unit: .milliliters)
        
        // Assert
        XCTAssertEqual(sut.todayWaterOunces, 16.9, accuracy: 0.1)
    }
    
    // MARK: - Editing Tests
    
    func test_editFoodItem_updatesExistingItem() async throws {
        // Arrange
        let foodItem = createSampleFoodItem()
        let entry = FoodEntry(date: Date(), mealType: .breakfast, user: testUser)
        entry.foodItems.append(foodItem)
        modelContext.insert(entry)
        try modelContext.save()
        
        sut.todaysMealsByType[.breakfast] = entry
        
        // Act
        await sut.editFoodItem(foodItem, newQuantity: 2, newUnit: "large")
        
        // Assert
        XCTAssertEqual(foodItem.quantity, 2)
        XCTAssertEqual(foodItem.unit, "large")
    }
    
    func test_deleteFoodItem_removesFromMeal() async throws {
        // Arrange
        let foodItem = createSampleFoodItem()
        let entry = FoodEntry(date: Date(), mealType: .dinner, user: testUser)
        entry.foodItems.append(foodItem)
        modelContext.insert(entry)
        modelContext.insert(foodItem)
        try modelContext.save()
        
        sut.todaysMealsByType[.dinner] = entry
        
        // Act
        await sut.deleteFoodItem(foodItem, from: .dinner)
        
        // Assert
        XCTAssertTrue(entry.foodItems.isEmpty)
    }
    
    // MARK: - Nutrition Summary Tests
    
    func test_nutritionSummary_calculatesCorrectly() async throws {
        // Arrange
        let item1 = FoodItem(name: "Item1", calories: 100, proteinGrams: 10, carbGrams: 20, fatGrams: 5)
        let item2 = FoodItem(name: "Item2", calories: 200, proteinGrams: 15, carbGrams: 30, fatGrams: 8)
        
        let breakfast = FoodEntry(date: Date(), mealType: .breakfast, user: testUser)
        breakfast.foodItems = [item1]
        
        let lunch = FoodEntry(date: Date(), mealType: .lunch, user: testUser)
        lunch.foodItems = [item2]
        
        sut.todaysMealsByType[.breakfast] = breakfast
        sut.todaysMealsByType[.lunch] = lunch
        
        // Act
        let summary = sut.nutritionSummary
        
        // Assert
        XCTAssertEqual(summary.calories, 300)
        XCTAssertEqual(summary.protein, 25)
        XCTAssertEqual(summary.carbs, 50)
        XCTAssertEqual(summary.fat, 13)
    }
    
    // MARK: - Progress Calculation Tests
    
    func test_calculateProgress_withTargets() throws {
        // Arrange
        let item = FoodItem(name: "Food", calories: 500, proteinGrams: 50, carbGrams: 50, fatGrams: 20)
        let entry = FoodEntry(date: Date(), mealType: .breakfast, user: testUser)
        entry.foodItems = [item]
        sut.todaysMealsByType[.breakfast] = entry
        
        sut.dailyTargets = NutritionTargets(
            calories: 2_000,
            protein: 150,
            carbs: 250,
            fat: 65,
            fiber: 25,
            water: 64
        )
        
        // Act
        let calorieProgress = sut.calorieProgress
        let proteinProgress = sut.proteinProgress
        let carbProgress = sut.carbProgress
        let fatProgress = sut.fatProgress
        
        // Assert
        XCTAssertEqual(calorieProgress, 0.25, accuracy: 0.01)
        XCTAssertEqual(proteinProgress, 0.33, accuracy: 0.01)
        XCTAssertEqual(carbProgress, 0.20, accuracy: 0.01)
        XCTAssertEqual(fatProgress, 0.31, accuracy: 0.01)
    }
    
    // MARK: - AI Coach Tests
    
    func test_getCoachSuggestions_callsCoachEngine() async throws {
        // Arrange
        mockCoachEngine.mockSuggestions = ["Eat more protein", "Drink water"]
        
        // Act
        await sut.getCoachSuggestions()
        
        // Assert
        XCTAssertFalse(sut.coachSuggestions.isEmpty)
        XCTAssertEqual(sut.coachSuggestions.count, 2)
        XCTAssertTrue(mockCoachEngine.didGenerateSuggestions)
    }
    
    // MARK: - Error Handling Tests
    
    func test_handleVoiceError_setsAppropriateMessage() {
        // Arrange & Act
        sut.voiceError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone not available"])
        
        // Assert
        XCTAssertNotNil(sut.voiceError)
    }
    
    func test_clearErrors_removesAllErrors() {
        // Arrange
        sut.voiceError = NSError(domain: "Test", code: 1)
        sut.textError = "Text error"
        sut.searchError = "Search error"
        
        // Act
        sut.voiceError = nil
        sut.textError = nil
        sut.searchError = nil
        
        // Assert
        XCTAssertNil(sut.voiceError)
        XCTAssertNil(sut.textError)
        XCTAssertNil(sut.searchError)
    }
    
    // MARK: - Integration Tests
    
    func test_fullFoodLoggingFlow() async throws {
        // Arrange
        let parsedItem = createSampleParsedItem(name: "Grilled Chicken", calories: 165)
        mockFoodVoiceAdapter.parsedItemsToReturn = [parsedItem]
        
        // Act - Voice input
        await sut.startVoiceInput()
        await sut.processVoiceInput()
        
        // Assert - Item is pending
        XCTAssertEqual(sut.pendingFoodItems.count, 1)
        XCTAssertEqual(sut.pendingFoodItems.first?.name, "Grilled Chicken")
        
        // Act - Confirm item
        sut.selectedMealType = .lunch
        await sut.confirmFoodItem(parsedItem)
        
        // Assert - Item is logged
        XCTAssertTrue(sut.pendingFoodItems.isEmpty)
        XCTAssertNotNil(sut.todaysMealsByType[.lunch])
        XCTAssertEqual(sut.todaysMealsByType[.lunch]?.foodItems.count, 1)
        XCTAssertEqual(sut.nutritionSummary.calories, 165)
    }
    
    func test_dataConsistencyAfterMultipleOperations() async throws {
        // Add multiple items
        let item1 = createSampleParsedItem(name: "Apple", calories: 95)
        let item2 = createSampleParsedItem(name: "Banana", calories: 105)
        let item3 = createSampleParsedItem(name: "Orange", calories: 62)
        
        // Add to different meals
        sut.selectedMealType = .breakfast
        sut.pendingFoodItems = [item1]
        await sut.confirmFoodItem(item1)
        
        sut.selectedMealType = .lunch
        sut.pendingFoodItems = [item2]
        await sut.confirmFoodItem(item2)
        
        sut.selectedMealType = .snack
        sut.pendingFoodItems = [item3]
        await sut.confirmFoodItem(item3)
        
        // Verify totals
        let summary = sut.nutritionSummary
        XCTAssertEqual(summary.calories, 262) // 95 + 105 + 62
        
        // Delete one item
        if let orangeItem = sut.todaysMealsByType[.snack]?.foodItems.first {
            await sut.deleteFoodItem(orangeItem, from: .snack)
        }
        
        // Verify updated totals
        let updatedSummary = sut.nutritionSummary
        XCTAssertEqual(updatedSummary.calories, 200) // 95 + 105
    }
}
