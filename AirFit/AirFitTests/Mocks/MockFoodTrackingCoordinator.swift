import SwiftUI
@testable import AirFit

@MainActor
final class MockFoodTrackingCoordinator {
    // MARK: - Internal coordinator
    private let coordinator = FoodTrackingCoordinator()
    
    // MARK: - Call Recording
    var didShowSheet: FoodTrackingCoordinator.FoodTrackingSheet?
    var didShowFullScreenCover: FoodTrackingCoordinator.FoodTrackingFullScreenCover?
    var didDismiss = false
    var didPop = false
    var didPopToRoot = false
    var pushCalls: [FoodTrackingDestination] = []
    
    // MARK: - Delegation with tracking
    var navigationPath: NavigationPath {
        get { coordinator.navigationPath }
        set { coordinator.navigationPath = newValue }
    }
    
    var activeSheet: FoodTrackingCoordinator.FoodTrackingSheet? {
        get { coordinator.activeSheet }
        set { coordinator.activeSheet = newValue }
    }
    
    var activeFullScreenCover: FoodTrackingCoordinator.FoodTrackingFullScreenCover? {
        get { coordinator.activeFullScreenCover }
        set { coordinator.activeFullScreenCover = newValue }
    }
    
    func showSheet(_ sheet: FoodTrackingCoordinator.FoodTrackingSheet) {
        didShowSheet = sheet
        coordinator.showSheet(sheet)
    }
    
    func showFullScreenCover(_ cover: FoodTrackingCoordinator.FoodTrackingFullScreenCover) {
        didShowFullScreenCover = cover
        coordinator.showFullScreenCover(cover)
    }
    
    func dismiss() {
        didDismiss = true
        coordinator.dismiss()
    }
    
    func push(_ destination: FoodTrackingDestination) {
        pushCalls.append(destination)
        coordinator.navigateTo(destination)
    }
    
    func pop() {
        didPop = true
        coordinator.pop()
    }
    
    func popToRoot() {
        didPopToRoot = true
        coordinator.popToRoot()
    }
    
    // MARK: - Test Helpers
    func reset() {
        coordinator.popToRoot()
        coordinator.dismiss()
        didShowSheet = nil
        didShowFullScreenCover = nil
        didDismiss = false
        didPop = false
        didPopToRoot = false
        pushCalls.removeAll()
    }
}
