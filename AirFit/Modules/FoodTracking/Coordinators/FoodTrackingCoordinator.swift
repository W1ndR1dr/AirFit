import SwiftUI

// MARK: - Navigation Destinations
enum FoodTrackingDestination: Hashable {
    case history
    case insights
    case favorites
    case recipes
    case mealPlan
}

// MARK: - Sheet Types
enum FoodTrackingSheet: Identifiable {
    case voiceInput
    case photoCapture
    case foodSearch
    case manualEntry
    case waterTracking
    case mealDetails(FoodEntry)

    var id: String {
        switch self {
        case .voiceInput: return "voice"
        case .photoCapture: return "photo"
        case .foodSearch: return "search"
        case .manualEntry: return "manual"
        case .waterTracking: return "water"
        case .mealDetails(let entry): return "meal_\(entry.id)"
        }
    }
}

// MARK: - Alert Types (for future use)
enum FoodTrackingAlert: Identifiable {
    case deleteEntry(entryId: String)
    case nutritionWarning(message: String)

    var id: String {
        switch self {
        case .deleteEntry(let id): return "delete_\(id)"
        case .nutritionWarning: return "warning"
        }
    }
}

@MainActor
@Observable
final class FoodTrackingCoordinator: BaseCoordinator<FoodTrackingDestination, FoodTrackingSheet, FoodTrackingAlert>, FoodTrackingCoordinatorProtocol {
    typealias SheetType = FoodTrackingSheet
    typealias CoverType = FoodTrackingFullScreenCover

    // MARK: - Additional State
    var activeFullScreenCover: FoodTrackingFullScreenCover?

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

    // MARK: - Additional Methods
    func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
        activeFullScreenCover = cover
    }

    override func dismiss() {
        super.dismiss()
        activeFullScreenCover = nil
    }
}
