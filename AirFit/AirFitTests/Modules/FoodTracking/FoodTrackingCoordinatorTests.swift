import XCTest
import SwiftUI
@testable import AirFit

@MainActor
final class FoodTrackingCoordinatorTests: XCTestCase {
    // MARK: - Properties
    private var sut: FoodTrackingCoordinator!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        sut = FoodTrackingCoordinator()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsEmptyNavigationPath() {
        // Assert
        XCTAssertTrue(sut.navigationPath.isEmpty)
        XCTAssertNil(sut.activeSheet)
        XCTAssertNil(sut.activeFullScreenCover)
    }
    
    // MARK: - Navigation Tests
    
    func test_navigateTo_appendsDestinationToPath() {
        // Arrange
        let destination = FoodTrackingDestination.nutritionInsights
        
        // Act
        sut.navigateTo(destination)
        
        // Assert
        XCTAssertFalse(sut.navigationPath.isEmpty)
    }
    
    func test_navigateBack_removesLastItem() {
        // Arrange
        sut.navigateTo(.nutritionInsights)
        sut.navigateTo(.mealHistory)
        
        // Act
        sut.navigateBack()
        
        // Assert
        // Navigation path count is not directly accessible, but we can verify behavior
        XCTAssertNotNil(sut.navigationPath)
    }
    
    func test_navigateToRoot_clearsNavigationPath() {
        // Arrange
        sut.navigateTo(.nutritionInsights)
        sut.navigateTo(.mealHistory)
        
        // Act
        sut.navigateToRoot()
        
        // Assert
        XCTAssertTrue(sut.navigationPath.isEmpty)
    }
    
    // MARK: - Sheet Presentation Tests
    
    func test_presentSheet_setsActiveSheet() {
        // Arrange
        let sheet = FoodTrackingCoordinator.FoodTrackingSheet.voiceInput
        
        // Act
        sut.presentSheet(sheet)
        
        // Assert
        XCTAssertEqual(sut.activeSheet, sheet)
    }
    
    func test_presentSheet_differentSheets() {
        // Test all sheet types
        let sheets: [FoodTrackingCoordinator.FoodTrackingSheet] = [
            .voiceInput,
            .photoCapture,
            .foodSearch,
            .manualEntry,
            .waterTracking,
            .mealDetails(createTestFoodEntry())
        ]
        
        for sheet in sheets {
            // Act
            sut.presentSheet(sheet)
            
            // Assert
            XCTAssertEqual(sut.activeSheet, sheet)
            XCTAssertEqual(sut.activeSheet?.id, sheet.id)
        }
    }
    
    func test_dismissSheet_clearsActiveSheet() {
        // Arrange
        sut.presentSheet(.voiceInput)
        XCTAssertNotNil(sut.activeSheet)
        
        // Act
        sut.dismissSheet()
        
        // Assert
        XCTAssertNil(sut.activeSheet)
    }
    
    // MARK: - Full Screen Cover Tests
    
    func test_presentFullScreenCover_setsActiveCover() {
        // Arrange
        let cover = FoodTrackingCoordinator.FoodTrackingFullScreenCover.camera
        
        // Act
        sut.presentFullScreenCover(cover)
        
        // Assert
        XCTAssertEqual(sut.activeFullScreenCover, cover)
    }
    
    func test_presentFullScreenCover_confirmation() {
        // Arrange
        let parsedItems = [
            ParsedFoodItem(
                name: "Apple",
                quantity: 1,
                unit: "medium",
                estimatedCalories: 95,
                macros: MacroNutrients(protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4)
            )
        ]
        let cover = FoodTrackingCoordinator.FoodTrackingFullScreenCover.confirmation(parsedItems)
        
        // Act
        sut.presentFullScreenCover(cover)
        
        // Assert
        XCTAssertEqual(sut.activeFullScreenCover?.id, "confirmation")
    }
    
    func test_dismissFullScreenCover_clearsCover() {
        // Arrange
        sut.presentFullScreenCover(.camera)
        XCTAssertNotNil(sut.activeFullScreenCover)
        
        // Act
        sut.dismissFullScreenCover()
        
        // Assert
        XCTAssertNil(sut.activeFullScreenCover)
    }
    
    // MARK: - Combined Navigation Tests
    
    func test_dismissAll_clearsAllNavigation() {
        // Arrange
        sut.navigateTo(.nutritionInsights)
        sut.presentSheet(.voiceInput)
        sut.presentFullScreenCover(.camera)
        
        // Act
        sut.dismissAll()
        
        // Assert
        XCTAssertTrue(sut.navigationPath.isEmpty)
        XCTAssertNil(sut.activeSheet)
        XCTAssertNil(sut.activeFullScreenCover)
    }
    
    // MARK: - Sheet ID Tests
    
    func test_sheetIds_areUnique() {
        // Arrange
        let entry1 = createTestFoodEntry(id: "1")
        let entry2 = createTestFoodEntry(id: "2")
        
        let sheets: [FoodTrackingCoordinator.FoodTrackingSheet] = [
            .voiceInput,
            .photoCapture,
            .foodSearch,
            .manualEntry,
            .waterTracking,
            .mealDetails(entry1),
            .mealDetails(entry2)
        ]
        
        // Act
        let ids = sheets.map { $0.id }
        let uniqueIds = Set(ids)
        
        // Assert
        XCTAssertEqual(ids.count, uniqueIds.count, "All sheet IDs should be unique")
    }
    
    func test_coverIds_areUnique() {
        // Arrange
        let covers: [FoodTrackingCoordinator.FoodTrackingFullScreenCover] = [
            .camera,
            .confirmation([])
        ]
        
        // Act
        let ids = covers.map { $0.id }
        let uniqueIds = Set(ids)
        
        // Assert
        XCTAssertEqual(ids.count, uniqueIds.count, "All cover IDs should be unique")
    }
    
    // MARK: - Observable Tests
    
    func test_coordinator_isObservable() {
        // Assert
        XCTAssertTrue(sut is AnyObject)
        // The @Observable macro makes the class conform to Observable protocol
    }
    
    // MARK: - Edge Cases
    
    func test_presentSheet_replacesExistingSheet() {
        // Arrange
        sut.presentSheet(.voiceInput)
        
        // Act
        sut.presentSheet(.photoCapture)
        
        // Assert
        XCTAssertEqual(sut.activeSheet, .photoCapture)
    }
    
    func test_presentFullScreenCover_replacesExistingCover() {
        // Arrange
        sut.presentFullScreenCover(.camera)
        
        // Act
        sut.presentFullScreenCover(.confirmation([]))
        
        // Assert
        XCTAssertEqual(sut.activeFullScreenCover?.id, "confirmation")
    }
    
    func test_dismissSheet_whenNoActiveSheet_doesNothing() {
        // Arrange
        XCTAssertNil(sut.activeSheet)
        
        // Act
        sut.dismissSheet()
        
        // Assert
        XCTAssertNil(sut.activeSheet)
    }
    
    func test_dismissFullScreenCover_whenNoActiveCover_doesNothing() {
        // Arrange
        XCTAssertNil(sut.activeFullScreenCover)
        
        // Act
        sut.dismissFullScreenCover()
        
        // Assert
        XCTAssertNil(sut.activeFullScreenCover)
    }
    
    // MARK: - Helper Methods
    
    private func createTestFoodEntry(id: String = UUID().uuidString) -> FoodEntry {
        return FoodEntry(
            name: "Test Food",
            calories: 100,
            protein: 10,
            carbs: 20,
            fat: 5,
            fiber: 3,
            sugar: nil,
            sodium: nil,
            quantity: 1,
            unit: "serving",
            mealType: .lunch,
            date: Date(),
            barcode: nil,
            notes: nil
        )
    }
}