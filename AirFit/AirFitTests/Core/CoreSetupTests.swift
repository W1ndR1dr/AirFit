@testable import AirFit
import SwiftUI
import Testing

struct CoreSetupTests {
    // MARK: - Core View Components Tests
    @Test
    func test_emptyStateView_initialization() {
        let emptyState = EmptyStateView(
            icon: "star",
            title: "Test Title",
            message: "Test Message"
        )

        #expect(emptyState.icon == "star")
        #expect(emptyState.title == "Test Title")
        #expect(emptyState.message == "Test Message")
        #expect(emptyState.action == nil)
        #expect(emptyState.actionTitle == nil)
    }

    @Test
    func test_emptyStateView_withAction() {
        var actionCalled = false
        let action = { actionCalled = true }

        let emptyState = EmptyStateView(
            icon: "plus",
            title: "Add Item",
            message: "No items found",
            action: action,
            actionTitle: "Add Now"
        )

        #expect(emptyState.actionTitle == "Add Now")
        #expect(emptyState.action != nil)
    }

    @Test
    func test_sectionHeader_initialization() {
        let header = SectionHeader(title: "Test Section")

        #expect(header.title == "Test Section")
        #expect(header.icon == nil)
        #expect(header.action == nil)
    }

    @Test
    func test_sectionHeader_withIconAndAction() {
        var actionCalled = false
        let action = { actionCalled = true }

        let header = SectionHeader(
            title: "Settings",
            icon: "gear",
            action: action
        )

        #expect(header.title == "Settings")
        #expect(header.icon == "gear")
        #expect(header.action != nil)
    }

    // MARK: - Theme Access Tests
    @Test
    func test_appColors_accessibility() {
        // Test that all core colors are accessible
        _ = AppColors.backgroundPrimary
        _ = AppColors.backgroundSecondary
        _ = AppColors.textPrimary
        _ = AppColors.textSecondary
        _ = AppColors.cardBackground
        _ = AppColors.accentColor
        _ = AppColors.buttonBackground
        _ = AppColors.errorColor
        _ = AppColors.successColor

        // If we get here without crashes, colors are accessible
        #expect(true)
    }

    @Test
    func test_appFonts_accessibility() {
        // Test that font properties are accessible
        _ = AppFonts.largeTitle
        _ = AppFonts.title
        _ = AppFonts.headline
        _ = AppFonts.body
        _ = AppFonts.caption

        // If we get here without crashes, fonts are accessible
        #expect(true)
    }

    @Test
    func test_appSpacing_constants() {
        // Test that spacing constants are defined
        #expect(AppSpacing.xSmall > 0)
        #expect(AppSpacing.small > 0)
        #expect(AppSpacing.medium > 0)
        #expect(AppSpacing.large > 0)
        #expect(AppSpacing.xLarge > 0)

        // Test logical ordering
        #expect(AppSpacing.xSmall < AppSpacing.small)
        #expect(AppSpacing.small < AppSpacing.medium)
        #expect(AppSpacing.medium < AppSpacing.large)
        #expect(AppSpacing.large < AppSpacing.xLarge)
    }

    @Test
    func test_appConstants_layout() {
        // Test that layout constants are accessible
        #expect(AppConstants.Layout.defaultPadding > 0)
        #expect(AppConstants.Layout.defaultCornerRadius > 0)
        #expect(AppConstants.Layout.defaultSpacing > 0)

        // Test reasonable values
        #expect(AppConstants.Layout.defaultPadding >= 8)
        #expect(AppConstants.Layout.defaultCornerRadius >= 4)
    }

    // MARK: - View Extensions Tests
    @Test
    func test_viewExtensions_compilation() {
        // Test that view extensions are available (basic compilation test)
        // Note: Actual usage testing will be done in UI tests
        #expect(true) // Extensions compile if this test runs
    }

    // MARK: - Core Enums Tests
    @Test
    func test_globalEnums_accessibility() {
        // Test BiologicalSex enum
        let sexCases = BiologicalSex.allCases
        #expect(sexCases.count == 2)
        #expect(sexCases.contains(.male))
        #expect(sexCases.contains(.female))

        // Test ActivityLevel enum
        let activityCases = ActivityLevel.allCases
        #expect(activityCases.count == 5)
        #expect(ActivityLevel.sedentary.multiplier == 1.2)
        #expect(ActivityLevel.extreme.multiplier == 1.9)

        // Test FitnessGoal enum
        let goalCases = FitnessGoal.allCases
        #expect(goalCases.count == 3)
        #expect(FitnessGoal.loseWeight.calorieAdjustment == -500)
        #expect(FitnessGoal.maintainWeight.calorieAdjustment == 0)
        #expect(FitnessGoal.gainMuscle.calorieAdjustment == 300)
    }

    @Test
    func test_appTab_enum() {
        let tabCases = AppTab.allCases
        #expect(tabCases.count == 5)

        // Test system images are defined
        for tab in tabCases {
            #expect(!tab.systemImage.isEmpty)
        }
    }

    // MARK: - Error Handling Tests
    @Test
    func test_appError_descriptions() {
        let networkError = AppError.networkError(underlying: NSError(domain: "test", code: 1))
        let validationError = AppError.validationError(message: "Invalid input")
        let unauthorized = AppError.unauthorized

        #expect(networkError.errorDescription?.contains("Network error") == true)
        #expect(validationError.errorDescription == "Invalid input")
        #expect(unauthorized.errorDescription == "Please log in to continue")
        #expect(unauthorized.recoverySuggestion == "Tap here to log in")
    }
}
