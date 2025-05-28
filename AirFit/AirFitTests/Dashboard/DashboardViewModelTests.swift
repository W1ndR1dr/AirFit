import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var modelContext: ModelContext!
    var mockHealth: MockHealthKitService!
    var mockAI: MockAICoachService!
    var mockNutrition: MockNutritionService!
    var testUser: User!

    override func setUp() async throws {
        try await super.setUp()
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        testUser = User(name: "Tester")
        modelContext.insert(testUser)
        try modelContext.save()

        mockHealth = MockHealthKitService()
        mockAI = MockAICoachService()
        mockNutrition = MockNutritionService()

        sut = DashboardViewModel(
            user: testUser,
            modelContext: modelContext,
            healthKitService: mockHealth,
            aiCoachService: mockAI,
            nutritionService: mockNutrition
        )
    }

    func test_loadQuickActions_generatesContextualActions() async {
        sut.nutritionSummary.waterLiters = 1.0
        sut.nutritionSummary.meals = [:]
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        await sut.loadQuickActions(for: noon)
        XCTAssertTrue(sut.suggestedActions.contains(.logMeal(type: .lunch)))
        XCTAssertTrue(sut.suggestedActions.contains(.logWater))
        XCTAssertTrue(sut.suggestedActions.contains(.startWorkout))
    }

    func test_loadQuickActions_updatesWhenConditionsChange() async {
        sut.nutritionSummary.waterLiters = 3.0
        sut.nutritionSummary.meals[.lunch] = FoodEntry(mealType: .lunch, user: testUser)
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        await sut.loadQuickActions(for: noon)
        XCTAssertFalse(sut.suggestedActions.contains(.logMeal(type: .lunch)))
        XCTAssertFalse(sut.suggestedActions.contains(.logWater))
    }

    func test_quickActionButton_tap_invokesCallback() {
        var tapped = false
        let button = QuickActionButton(action: .startWorkout) {
            tapped = true
        }
        button.onTap()
        XCTAssertTrue(tapped)
    }
}
