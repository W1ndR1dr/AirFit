import Foundation
import RegexBuilder

enum LocalCommand: Equatable {
    case showDashboard
    case navigateToTab(AppTab)
    case logWater(amount: Double, unit: WaterUnit)
    case quickLog(type: QuickLogType)
    case showSettings
    case showProfile
    case startWorkout
    case help
    case none

    enum WaterUnit: String {
        case ounces = "oz"
        case milliliters = "ml"
        case liters = "l"
        case cups = "cup"

        var toMilliliters: Double {
            switch self {
            case .ounces: return 29.5735
            case .milliliters: return 1.0
            case .liters: return 1000.0
            case .cups: return 236.588
            }
        }
    }

    enum QuickLogType {
        case meal(MealType)
        case mood
        case energy
        case weight
    }
}

@MainActor
final class LocalCommandParser {
    // MARK: - Properties
    private let waterPattern: Regex<(Substring, Substring?, Substring?)>
    private let navigationCommands: [String: LocalCommand]
    private let quickLogPatterns: [(pattern: String, command: LocalCommand)]

    // MARK: - Initialization
    init() {
        // Initialize water logging pattern
        waterPattern = Regex {
            "log"
            ZeroOrMore(.whitespace)
            Optionally {
                TryCapture {
                    OneOrMore(.digit)
                    Optionally {
                        "."
                        OneOrMore(.digit)
                    }
                } transform: { Double($0) }
            }
            ZeroOrMore(.whitespace)
            Optionally {
                TryCapture {
                    ChoiceOf {
                        "oz"
                        "ounces"
                        "ml"
                        "milliliters"
                        "l"
                        "liters"
                        "cup"
                        "cups"
                    }
                } transform: { String($0) }
            }
            ZeroOrMore(.whitespace)
            "water"
        }
        .ignoresCase()

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
        for (pattern, command) in navigationCommands {
            if normalizedInput.contains(pattern) {
                return command
            }
        }

        // Check quick log commands
        for (pattern, command) in quickLogPatterns {
            if normalizedInput.contains(pattern) {
                return command
            }
        }

        // Check for tab navigation
        if let tabCommand = parseTabNavigation(normalizedInput) {
            return tabCommand
        }

        return .none
    }

    // MARK: - Private Methods
    private func parseWaterCommand(_ input: String) -> LocalCommand? {
        guard let match = try? waterPattern.firstMatch(in: input) else {
            return nil
        }

        let amount = match.1 ?? 8.0 // Default to 8oz
        let unitString = match.2?.lowercased() ?? "oz"

        let unit: LocalCommand.WaterUnit = {
            switch unitString {
            case "ml", "milliliters": return .milliliters
            case "l", "liters": return .liters
            case "cup", "cups": return .cups
            default: return .ounces
            }
        }()

        return .logWater(amount: amount, unit: unit)
    }

    private func parseTabNavigation(_ input: String) -> LocalCommand? {
        let tabPatterns: [(pattern: String, tab: AppTab)] = [
            ("food|nutrition|meal", .meals),
            ("workout|exercise|gym", .progress),
            ("coach|chat|ai", .discover),
            ("setting|preference", .settings)
        ]

        for (pattern, tab) in tabPatterns {
            if input.range(of: pattern, options: .regularExpression) != nil {
                return .navigateToTab(tab)
            }
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
