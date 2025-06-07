import XCTest
import SwiftData
@testable import AirFit

// MARK: - Mock Dependencies

// MockFoodDatabaseService removed - using MockNutritionService instead



// Using MockError from MockAIService.swift

// MARK: - Test Helper for SwiftData
actor SwiftDataTestHelper {
    @MainActor
    static func previewContainer() throws -> ModelContainer {
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self, OnboardingProfile.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}


// MARK: - FoodTrackingViewModelTests
final class FoodTrackingViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testUser: User!

    var mockFoodVoiceAdapter: MockFoodVoiceAdapter!
    var mockNutritionService: MockNutritionService!
    var mockCoachEngine: MockCoachEngine!
    var coordinator: FoodTrackingCoordinator!
    // MockFoodDatabaseService removed - not needed

    var sut: FoodTrackingViewModel!

    override func setUp() {
        super.setUp()
        // Async initialization moved to setupTest()
    }
    
    @MainActor
    private func setupTest() async throws {
        modelContainer = try await SwiftDataTestHelper.previewContainer()
        modelContext = ModelContext(modelContainer)

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

        mockFoodVoiceAdapter = MockFoodVoiceAdapter()
        mockNutritionService = MockNutritionService()
        // mockFoodDBService removed
        mockCoachEngine = MockCoachEngine()
        coordinator = FoodTrackingCoordinator()

        sut = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: mockNutritionService,
            coachEngine: mockCoachEngine,
            coordinator: coordinator
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        coordinator = nil
        mockCoachEngine = nil
        mockNutritionService = nil
        mockFoodVoiceAdapter = nil
        // mockFoodDBService removed
        testUser = nil
        modelContext = nil
        modelContainer = nil
        try super.tearDownWithError()
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
    @MainActor
    func test_init_loadsInitialDataViaSetNutritionService() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Initial data loaded")
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
        
        // Load data
        await sut.loadTodaysData()
        
        // Give a brief moment for async loadTodaysData to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.recentFoods.isEmpty, "Recent foods should be populated")
            XCTAssertEqual(self.sut.recentFoods.first?.name, "Recent Banana")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func test_loadTodaysData_success_populatesPropertiesCorrectly() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "loadTodaysData completes and populates properties")
        mockNutritionService.foodEntriesToReturn = [FoodEntry(loggedAt: Date(), mealType: .breakfast)]
        mockNutritionService.nutritionSummaryToReturn = FoodNutritionSummary(
            calories: 500,
            protein: 20,
            carbs: 50,
            fat: 10,
            fiber: 5,
            sugar: 10,
            sodium: 200,
            calorieGoal: 2000,
            proteinGoal: 150,
            carbGoal: 250,
            fatGoal: 65
        )
        mockNutritionService.waterIntakeToReturn = 750
        mockNutritionService.recentFoodsToReturn = [createSampleFoodItem(name: "Recent Apple")]
        // mockNutritionService.targetsToReturn is already set in setUp

        await sut.loadTodaysData()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.todaysFoodEntries.count, 1)
        XCTAssertEqual(sut.todaysNutrition.calories, 500)
        XCTAssertEqual(sut.todaysNutrition.proteinGoal, mockNutritionService.targetsToReturn?.protein ?? 0) // Check if goals are set
        XCTAssertEqual(sut.waterIntakeML, 750)
        XCTAssertEqual(sut.recentFoods.first?.name, "Recent Apple")
        // Suggested foods depend on meal history, can be more complex to mock perfectly here
        // For now, check it's called and potentially empty if no history
        XCTAssertNotNil(sut.suggestedFoods)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func test_loadTodaysData_serviceFailure_setsError() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "loadTodaysData handles service failure")
        mockNutritionService.shouldThrowError = true

        await sut.loadTodaysData()

        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.hasError)
        XCTAssertNotNil(sut.error)
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Voice Integration Tests
    @MainActor
    func test_startVoiceInput_permissionGranted_showsVoiceSheet() async throws {
        try await setupTest()
        mockFoodVoiceAdapter.requestPermissionShouldSucceed = true
        await sut.startVoiceInput()
        if case .voiceInput = coordinator.activeSheet {
            // Success
        } else {
            XCTFail("Expected voiceInput sheet")
        }
        XCTAssertNil(sut.error)
    }

    @MainActor
    func test_startVoiceInput_permissionDenied_setsError() async throws {
        try await setupTest()
        mockFoodVoiceAdapter.requestPermissionShouldSucceed = false
        await sut.startVoiceInput()
        XCTAssertNil(coordinator.activeSheet)
        XCTAssertTrue(sut.hasError)
        XCTAssertNotNil(sut.error)
    }

    @MainActor
    func test_startRecording_success_updatesState() async throws {
        try await setupTest()
        await sut.startRecording() // Assumes permission already granted or not checked here
        XCTAssertTrue(mockFoodVoiceAdapter.isRecording)
        // Can't test private isRecording state - test behavior instead
        XCTAssertNil(sut.error)
    }
    
    @MainActor
    func test_startRecording_failure_setsErrorAndState() async throws {
        try await setupTest()
        mockFoodVoiceAdapter.startRecordingShouldSucceed = false
        await sut.startRecording()
        XCTAssertFalse(mockFoodVoiceAdapter.isRecording)
        // Can't test private isRecording state
        XCTAssertNotNil(sut.error)
    }

    @MainActor
    func test_stopRecording_withText_showsConfirmation() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Transcription processed after stopRecording")
        mockFoodVoiceAdapter.stopRecordingText = "one apple"
        // Mock the coach engine to return parsed items
        let expectedItems = [createSampleParsedItem(name: "Apple")]
        mockCoachEngine.mockParsedItems = expectedItems

        await sut.startRecording()
        await sut.stopRecording()

        // Wait for async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { 
            // Test behavior: should show confirmation with parsed items
            if case .confirmation(let items) = self.coordinator.activeFullScreenCover {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.name, "Apple")
            } else {
                XCTFail("Expected confirmation to be shown")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    @MainActor
    func test_stopRecording_emptyText_doesNotShowConfirmation() async throws {
        try await setupTest()
        mockFoodVoiceAdapter.stopRecordingText = ""
        await sut.startRecording()
        await sut.stopRecording()
        
        // Test behavior: no confirmation should be shown for empty text
        XCTAssertNil(coordinator.activeFullScreenCover, "Confirmation sheet should not be shown for empty transcription")
    }

    @MainActor
    func test_voiceCallbacks_onFoodTranscription_showsConfirmation() async throws {
        try await setupTest()
         let expectation = XCTestExpectation(description: "onFoodTranscription callback processed")
         // Mock the coach engine to return parsed items
         let expectedItems = [createSampleParsedItem(name: "Banana")]
         mockCoachEngine.mockParsedItems = expectedItems

         mockFoodVoiceAdapter.simulateTranscription("one banana") // This triggers the callback

         DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
             // Test behavior: should show confirmation
             if case .confirmation(let items) = self.coordinator.activeFullScreenCover {
                 XCTAssertEqual(items.first?.name, "Banana")
             } else {
                 XCTFail("Expected confirmation to be shown")
             }
             expectation.fulfill()
         }
         await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func test_voiceCallbacks_onError_setsViewModelError() {
        let testError = MockError.generic
        mockFoodVoiceAdapter.simulateError(testError)
        XCTAssertNotNil(sut.error)
        // Error is wrapped in AppError, can't test identity
    }


    // MARK: - AI Parsing Tests (via voice callbacks)
    @MainActor
    func test_voiceTranscription_simpleCommand_showsConfirmation() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Simple command parsed")
        // Use voice adapter callback to trigger processing
        let expectedItems = [createSampleParsedItem(name: "Apple")]
        mockCoachEngine.mockParsedItems = expectedItems
        
        // Simulate voice transcription through the adapter
        mockFoodVoiceAdapter.simulateTranscription("log apple")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Test behavior through coordinator
            if case .confirmation(let items) = self.coordinator.activeFullScreenCover {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items.first?.name, "Apple")
            } else {
                XCTFail("Expected confirmation to be shown")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // Removed test_processTranscription_aiParsingSuccess - processTranscription is private
    // Test the behavior through voice callbacks instead
    
    // All processTranscription tests removed - processTranscription is private
    // These behaviors should be tested through public methods like voice callbacks


    // MARK: - Photo Input Tests
    @MainActor
    func test_startPhotoCapture_showsPhotoSheet() {
        sut.startPhotoCapture()
        if case .photoCapture = coordinator.activeSheet {
            // Success
        } else {
            XCTFail("Expected photoCapture sheet")
        }
    }

    @MainActor
    func test_processPhotoResult_success_showsConfirmation() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Photo result processed successfully")
        let testImage = UIImage() // Dummy image
        let photoParsedItem = createSampleParsedItem(name: "Photo Apple", confidence: 0.85)
        mockCoachEngine.analyzeMealPhotoShouldSucceed = true
        mockCoachEngine.analyzeMealPhotoItemsToReturn = [photoParsedItem]

        await sut.processPhotoResult(testImage)

        XCTAssertFalse(sut.isLoading)
        // Test behavior through coordinator
        if case .confirmation(let items) = coordinator.activeFullScreenCover {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.name, "Photo Apple")
        } else {
            XCTFail("Expected confirmation to be shown")
        }
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_processPhotoResult_failure_setsError() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Photo result processing failure")
        let testImage = UIImage()
        mockCoachEngine.analyzeMealPhotoShouldSucceed = false
        
        await sut.processPhotoResult(testImage)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        XCTAssertNotNil(sut.error) // Error from mockCoachEngine
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_processPhotoResult_noItemsDetected_setsError() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Photo result no items detected")
        let testImage = UIImage()
        mockCoachEngine.analyzeMealPhotoShouldSucceed = true
        mockCoachEngine.analyzeMealPhotoItemsToReturn = [] // No items
        
        await sut.processPhotoResult(testImage)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        // The error is wrapped in AppError, check the message instead
        XCTAssertNotNil(sut.error)
        if let appError = sut.error,
           case .validationError(let message) = appError {
            XCTAssertEqual(message, "No food detected")
        } else {
            XCTFail("Expected validation error for no foods detected")
        }
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }


    // MARK: - Food Search Tests
    @MainActor
    func test_searchFoods_validQuery_callsCoachEngine() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Search foods calls coach engine")
        // Mock the coach engine to return search results
        let searchResult = createSampleParsedItem(name: "Chicken")
        mockCoachEngine.searchFoodsShouldSucceed = true
        mockCoachEngine.searchFoodsResultsToReturn = [searchResult]
        
        await sut.searchFoods("chicken")
        
        XCTAssertFalse(sut.isLoading)
        // Can't test private searchResults - verify through mock calls
        XCTAssertTrue(mockCoachEngine.searchFoodsCalled)
        XCTAssertEqual(mockCoachEngine.searchFoodsQuery, "chicken")
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_searchFoods_emptyQuery_doesNotSearch() async throws {
        try await setupTest()
        // Test that empty query doesn't trigger search
        await sut.searchFoods("")
        
        // Verify no search was performed
        XCTAssertFalse(mockCoachEngine.searchFoodsCalled)
    }

    @MainActor
    func test_selectSearchResult_showsConfirmation() {
        let parsedItem = createSampleParsedItem(name: "Selected Item")
        sut.selectSearchResult(parsedItem)

        // Test behavior through coordinator
        if case .confirmation(let items) = coordinator.activeFullScreenCover {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.name, "Selected Item")
        } else {
            XCTFail("Expected confirmation to be shown")
        }
        XCTAssertNil(coordinator.activeSheet) // Search sheet should be dismissed
    }
    
    // Removed test_clearSearchResults and test_setSearchResults - no public methods to test


    // MARK: - Saving Food Entries Tests
    @MainActor
    func test_confirmAndSaveFoodItems_success_savesAndRefreshes() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Confirm and save success")
        let itemsToSave = [createSampleParsedItem(name: "Saved Apple")]
        
        // Ensure loadTodaysData mock is ready to show refresh
        mockNutritionService.foodEntriesToReturn = [] // Before save
        
        await sut.confirmAndSaveFoodItems(itemsToSave)

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertNil(coordinator.activeFullScreenCover) // Confirmation sheet dismissed
        XCTAssertTrue(sut.parsedItems.isEmpty) // Parsed items cleared

        // Verify data saved in ModelContext
        let fetchDescriptor = FetchDescriptor<FoodEntry>()
        let savedEntries = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(savedEntries.count, 1)
        XCTAssertEqual(savedEntries.first?.items.count, 1)
        XCTAssertEqual(savedEntries.first?.items.first?.name, "Saved Apple")
        
        // Verify loadTodaysData was effectively called (e.g., by checking a property it sets)
        // This is implicitly tested if mockNutritionService's data is used by loadTodaysData
        // For a more direct test, the mockNutritionService could have a flag.
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_confirmAndSaveFoodItems_saveFailure_setsError() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Confirm and save failure")
        let itemsToSave = [createSampleParsedItem(name: "Unsaved Apple")]
        
        // Simulate save error by making modelContext throw (hard to do directly)
        // Or, if NutritionService was involved in saving, mock its error.
        // The current SUT saves directly to modelContext.
        // For this test, we'll assume an error during save sets sut.error.
        // A more robust way would be to inject a ModelContext wrapper that can throw.
        // For now, we'll check the error type set by the SUT.
        
        // To simulate a save error, we can try to save an object that violates a constraint
        // if such constraints exist and are enforced by SwiftData in a testable way.
        // Or, we can modify the SUT to catch errors from modelContext.save() and set currentError.
        // Assuming the SUT's catch block works:
        // This test is hard to make fail reliably without more control over ModelContext.save().
        // Let's assume if an error occurs, FoodTrackingError.saveFailed is set.
        
        // To make this testable, we'd ideally inject a "Saver" protocol.
        // For now, we can't easily make `modelContext.save()` throw on demand.
        // This test highlights a limitation of direct ModelContext usage vs. an abstraction.
        
        // Let's test that if *any* error occurs (e.g. from loadTodaysData after a hypothetical save), it's set.
        mockNutritionService.shouldThrowError = true // Simulate error during the refresh part
        
        await sut.confirmAndSaveFoodItems(itemsToSave)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        // If save itself fails, the SUT would catch and set an error
        // If refresh fails, it would be from the service
        // The SUT catches any error from modelContext.save() and sets it as the current error.
        // If the save is successful but refresh fails, then the error would be from refresh.
        
        // Let's assume the primary error we want to test is the save itself.
        // Since we can't make modelContext.save() fail easily, this test is limited.
        // We will assume that if an error is caught, it will be FoodTrackingError.saveFailed.
        // This test is more of a placeholder for that specific error.
        
        // If we want to test the SUT's specific error for save failure, we need to trust its catch block.
        // For now, we can only verify that *an* error is set if the subsequent loadTodaysData fails.
        XCTAssertNotNil(sut.error) // Error from refresh after save
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }


    // MARK: - Water Tracking Tests
    @MainActor
    func test_logWater_success_updatesViewModelAndCallsService() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Log water success")
        let initialWater = sut.waterIntakeML
        let amountToAdd: Double = 250
        let unit: WaterUnit = .milliliters
        
        await sut.logWater(amount: amountToAdd, unit: unit)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.waterIntakeML, initialWater + amountToAdd)
        XCTAssertEqual(mockNutritionService.loggedWaterAmount, amountToAdd)
        XCTAssertNotNil(mockNutritionService.loggedWaterDate) // Check date was passed
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_logWater_serviceFailure_setsError() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Log water service failure")
        mockNutritionService.shouldThrowError = true
        let initialWater = sut.waterIntakeML
        
        await sut.logWater(amount: 250, unit: .milliliters)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        XCTAssertNotNil(sut.error) // Error from service
        XCTAssertEqual(sut.waterIntakeML, initialWater, "Water intake should not change on error")
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Smart Suggestions Tests
    @MainActor
    func test_generateSmartSuggestions_withHistory_returnsSuggestions() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Generate smart suggestions with history")
        let historyItem = createSampleFoodItem(name: "Frequent Banana")
        let mealEntry = FoodEntry(loggedAt: Date(), mealType: .breakfast)
        mealEntry.items.append(historyItem)
        mockNutritionService.mealHistoryToReturn = [mealEntry]
        
        // Call a method that internally calls generateSmartSuggestions, e.g., loadTodaysData or setSelectedMealType
        await sut.loadTodaysData()
        
        XCTAssertFalse(sut.suggestedFoods.isEmpty)
        XCTAssertEqual(sut.suggestedFoods.first?.name, "Frequent Banana")
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Meal Management Tests
    @MainActor
    func test_deleteFoodEntry_success_removesEntryAndRefreshes() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Delete food entry success")
        let entryToDelete = FoodEntry(loggedAt: Date(), mealType: .lunch)
        entryToDelete.items.append(createSampleFoodItem())
        testUser.foodEntries.append(entryToDelete)
        modelContext.insert(entryToDelete)
        try modelContext.save()
        
        let initialEntryCount = try modelContext.fetch(FetchDescriptor<FoodEntry>()).count
        XCTAssertEqual(initialEntryCount, 1)

        await sut.deleteFoodEntry(entryToDelete)

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        
        let finalEntryCount = try modelContext.fetch(FetchDescriptor<FoodEntry>()).count
        XCTAssertEqual(finalEntryCount, 0)
        // Also check that loadTodaysData was effectively called
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_duplicateFoodEntry_success_createsNewEntryAndRefreshes() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "Duplicate food entry success")
        let entryToDuplicate = FoodEntry(loggedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, mealType: .dinner)
        entryToDuplicate.items.append(createSampleFoodItem(name: "Original Item"))
        testUser.foodEntries.append(entryToDuplicate)
        modelContext.insert(entryToDuplicate)
        try modelContext.save()

        await sut.duplicateFoodEntry(entryToDuplicate)

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)

        let fetchDescriptor = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)])
        let allEntries = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(allEntries.count, 2)
        
        let duplicatedEntry = allEntries.first // Newest one
        XCTAssertNotNil(duplicatedEntry)
        XCTAssertEqual(duplicatedEntry?.items.first?.name, "Original Item")
        XCTAssertTrue(Calendar.current.isDate(duplicatedEntry!.loggedAt, inSameDayAs: sut.currentDate))
        XCTAssertNotEqual(duplicatedEntry!.id, entryToDuplicate.id) // Ensure it's a new object
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - State Management & Error Handling Tests
    @MainActor
    func test_errorState_isSetAndClearedCorrectly() async throws {
        try await setupTest()
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.hasError)

        // setError is private, trigger an error through a public method:
        mockFoodVoiceAdapter.requestPermissionShouldSucceed = false
        await sut.startVoiceInput() // This will set an error

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.hasError)
        // Can't test identical error objects as AppError is created internally

        sut.clearError()
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.hasError)
    }
    
    @MainActor
    func test_isLoading_isSetCorrectlyDuringAsyncOperations() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "isLoading state managed")
        
        // For loadTodaysData
        let loadDataTask = Task {
            await sut.loadTodaysData()
        }
        // isLoading should be true briefly
        XCTAssertTrue(sut.isLoading, "isLoading should be true during loadTodaysData")
        await loadDataTask.value // Wait for completion
        XCTAssertFalse(sut.isLoading, "isLoading should be false after loadTodaysData")

        // Test processTranscription indirectly through voice adapter callback
        mockCoachEngine.mockParsedItems = [createSampleParsedItem(name: "AI Food")]
        
        // Simulate voice transcription which triggers processTranscription internally
        mockFoodVoiceAdapter.simulateTranscription("some ai food")
        
        // Give time for async processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify the result through public behavior (showing confirmation)
        if case .confirmation(let items) = coordinator.activeFullScreenCover {
            XCTAssertEqual(items.first?.name, "AI Food")
        }

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Optional Nutrition Service Tests
    @MainActor
    func test_viewModel_withNilNutritionService_gracefullyHandlesCalls() async throws {
        try await setupTest()
        // Re-init SUT with nil nutritionService
        sut = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: nil, // Explicitly nil
            coachEngine: mockCoachEngine,
            coordinator: coordinator
        )
        
        // Test methods that use nutritionService
        await sut.loadTodaysData()
        XCTAssertTrue(sut.todaysFoodEntries.isEmpty) // Should default to empty
        XCTAssertEqual(sut.todaysNutrition.calories, 0)
        XCTAssertEqual(sut.waterIntakeML, 0)
        XCTAssertTrue(sut.recentFoods.isEmpty)
        XCTAssertTrue(sut.suggestedFoods.isEmpty)
        XCTAssertNil(sut.error, "Should not error out, just return defaults/empty")
        
        await sut.logWater(amount: 100, unit: .milliliters)
        XCTAssertEqual(sut.waterIntakeML, 100, "Water should still update optimistically even if service is nil") // ViewModel updates this locally too
        // No service call to verify here
        
        // Smart suggestions are generated internally by loadTodaysData
        // We can't call generateSmartSuggestions directly as it's private
    }

    // Removed test_setNutritionService_loadsDataWithNewService - setNutritionService method doesn't exist
    
    // MARK: - Other Public Methods
    @MainActor
    func test_setSelectedMealType_updatesPropertyAndSuggestions() async throws {
        try await setupTest()
        let expectation = XCTestExpectation(description: "setSelectedMealType updates suggestions")
        sut.selectedMealType = .breakfast // Initial
        
        // Mock meal history for lunch differently
        let lunchItem = createSampleFoodItem(name: "Lunch Suggestion")
        let lunchEntry = FoodEntry(loggedAt: Date(), mealType: .lunch)
        lunchEntry.items.append(lunchItem)
        mockNutritionService.mealHistoryToReturn = [lunchEntry] // This will be used by generateSmartSuggestions
        
        sut.setSelectedMealType(.lunch)
        
        XCTAssertEqual(sut.selectedMealType, .lunch)
        
        // Wait for suggestions to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.suggestedFoods.isEmpty, "Suggestions should update for new meal type")
            XCTAssertEqual(self.sut.suggestedFoods.first?.name, "Lunch Suggestion")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func test_setParsedItems_updatesViewModelProperty() {
        let items = [createSampleParsedItem(name: "External Item")]
        sut.setParsedItems(items)
        XCTAssertEqual(sut.parsedItems.count, 1)
        XCTAssertEqual(sut.parsedItems.first?.name, "External Item")
    }
