import SwiftUI
import Observation

@MainActor
@Observable
final class FoodTrackingCoordinator {
    // MARK: - Navigation State
    var navigationPath = NavigationPath()
    var activeSheet: FoodTrackingSheet?
    var activeFullScreenCover: FoodTrackingFullScreenCover?

    // MARK: - Sheet Types
    enum FoodTrackingSheet: Identifiable {
        case voiceInput
        case barcodeScanner
        case foodSearch
        case manualEntry
        case waterTracking
        case mealDetails(FoodEntry)

        var id: String {
            switch self {
            case .voiceInput: return "voice"
            case .barcodeScanner: return "barcode"
            case .foodSearch: return "search"
            case .manualEntry: return "manual"
            case .waterTracking: return "water"
            case .mealDetails(let entry): return "meal_\(entry.id)"
            }
        }
    }

    // MARK: - Full Screen Cover Types
    enum FoodTrackingFullScreenCover: Identifiable {
        case camera
        case confirmation([ParsedFoodItem])

        var id: String {
            switch self {
            case .camera: return "camera"
            case .confirmation: return "confirmation"
            }
        }
    }

    // MARK: - Navigation
    func navigateTo(_ destination: FoodTrackingDestination) {
        navigationPath.append(destination)
    }

    func showSheet(_ sheet: FoodTrackingSheet) {
        activeSheet = sheet
    }

    func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
        activeFullScreenCover = cover
    }

    func dismiss() {
        activeSheet = nil
        activeFullScreenCover = nil
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    // MARK: - Deep Linking
    func handleDeepLink(_ destination: FoodTrackingDestination) {
        popToRoot()
        navigateTo(destination)
    }
}

// MARK: - Navigation Destinations
enum FoodTrackingDestination: Hashable {
    case history
    case insights
    case favorites
    case recipes
    case mealPlan
}
