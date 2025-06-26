import Foundation
import RegexBuilder

public enum LocalCommand: Equatable {
    case showDashboard
    case navigateToTab(AppTab)
    case logWater(amount: Double, unit: WaterUnit)
    case quickLog(type: QuickLogType)
    case showSettings
    case showProfile
    case startWorkout
    case help
    case none

    public enum WaterUnit: String {
        case ounces = "oz"
        case milliliters = "ml"
        case liters = "l"
        case cups = "cup"

        public var toMilliliters: Double {
            switch self {
            case .ounces: return 29.5735
            case .milliliters: return 1.0
            case .liters: return 1_000.0
            case .cups: return 236.588
            }
        }
    }

    public enum QuickLogType: Equatable {
        case meal(MealType)
        case mood
        case energy
        case weight
    }
}

@MainActor
final class LocalCommandParser {
    // MARK: - Properties
    private let navigationCommands: [String: LocalCommand]
    private let quickLogPatterns: [(pattern: String, command: LocalCommand)]

    // MARK: - Initialization
    init() {

        // Navigation shortcuts
        navigationCommands = [
            "dashboard": .showDashboard,
            "home": .showDashboard,
            "settings": .showSettings,
            "profile": .showProfile,
            "start workout": .startWorkout,
            "workout": .startWorkout,
            "help": .help,
            "?": .help
        ]

        // Quick log patterns
        quickLogPatterns = [
            ("log breakfast", .quickLog(type: .meal(.breakfast))),
            ("log lunch", .quickLog(type: .meal(.lunch))),
            ("log dinner", .quickLog(type: .meal(.dinner))),
            ("log snack", .quickLog(type: .meal(.snack))),
            ("log mood", .quickLog(type: .mood)),
            ("log energy", .quickLog(type: .energy)),
            ("log weight", .quickLog(type: .weight))
        ]
    }

    // MARK: - Public Methods
    func parse(_ input: String) -> LocalCommand {
        let normalizedInput = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Check water logging
        if let waterCommand = parseWaterCommand(normalizedInput) {
            return waterCommand
        }

        // Check navigation commands
        for (pattern, command) in navigationCommands where normalizedInput.contains(pattern) {
            return command
        }

        // Check quick log commands
        for (pattern, command) in quickLogPatterns where normalizedInput.contains(pattern) {
            return command
        }

        // Check for tab navigation
        if let tabCommand = parseTabNavigation(normalizedInput) {
            return tabCommand
        }

        return .none
    }

    // MARK: - Private Methods
    private func parseWaterCommand(_ input: String) -> LocalCommand? {
        // Check if input contains "water" or water-related terms
        guard input.contains("water") || input.contains("h2o") ||
                (input.contains("log") && (input.contains("oz") || input.contains("ml") || input.contains("liter"))) else {
            return nil
        }

        // Extract amount using simple pattern matching
        let components = input.components(separatedBy: .whitespacesAndNewlines)
        var amount: Double = 8.0 // Default
        var unit: LocalCommand.WaterUnit = .ounces // Default

        // Look for numeric values followed by units
        for i in 0..<components.count {
            let component = components[i]
            if let value = Double(component.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                amount = value

                // Check if next component or current component has unit
                let unitText = component + (i + 1 < components.count ? components[i + 1] : "")
                if unitText.contains("ml") || unitText.contains("milliliter") {
                    unit = .milliliters
                } else if unitText.contains("oz") || unitText.contains("ounce") {
                    unit = .ounces
                } else if (unitText.contains("l") && !unitText.contains("ml")) || unitText.contains("liter") {
                    unit = .liters
                } else if unitText.contains("cup") {
                    unit = .cups
                }
                break
            }
        }

        return .logWater(amount: amount, unit: unit)
    }

    private func parseTabNavigation(_ input: String) -> LocalCommand? {
        let tabPatterns: [(pattern: String, tab: AppTab)] = [
            ("food|nutrition|meal", .food),
            ("workout|exercise|gym", .workouts),
            ("coach|chat|ai", .chat),
            ("setting|preference|profile", .profile)
        ]

        for (pattern, tab) in tabPatterns where input.range(of: pattern, options: .regularExpression) != nil {
            return .navigateToTab(tab)
        }

        return nil
    }
}

// MARK: - Command Metadata
extension LocalCommand {
    var requiresNavigation: Bool {
        switch self {
        case .showDashboard, .navigateToTab, .showSettings,
             .showProfile, .startWorkout:
            return true
        default:
            return false
        }
    }

    var analyticsName: String {
        switch self {
        case .showDashboard: return "show_dashboard"
        case .navigateToTab(let tab): return "navigate_\(tab)"
        case .logWater: return "log_water"
        case .quickLog(let type): return "quick_log_\(type)"
        case .showSettings: return "show_settings"
        case .showProfile: return "show_profile"
        case .startWorkout: return "start_workout"
        case .help: return "help"
        case .none: return "none"
        }
    }
}
