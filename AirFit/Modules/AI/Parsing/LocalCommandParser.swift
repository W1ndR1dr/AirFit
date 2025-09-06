import Foundation
import RegexBuilder

public enum LocalCommand: Equatable {
    case showDashboard
    case navigateToTab(AppTab)
    case quickLog(type: QuickLogType)
    case showSettings
    case showProfile
    case startWorkout
    case help
    case none
    // Enhanced navigation commands
    case showFood(date: Date?, mealType: MealType?)
    case showWorkouts(filter: WorkoutFilter?)
    case showStats(metric: String?)
    case showRecovery
    case showProgress(timeframe: TimeFrame?)
    case quickAction(QuickAction.QuickActionType)

    public enum QuickLogType: Equatable {
        case meal(MealType)
        case mood
        case energy
        case weight
    }

    public enum WorkoutFilter: Equatable, Hashable {
        case recent
        case type(WorkoutType)
        case thisWeek
        case thisMonth
    }

    public enum TimeFrame: Equatable, Hashable {
        case today
        case thisWeek
        case thisMonth
        case lastDays(Int)
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

        // Check enhanced navigation commands
        if let enhancedCommand = parseEnhancedNavigation(normalizedInput) {
            return enhancedCommand
        }

        // Check food-specific navigation
        if let foodCommand = parseFoodNavigation(normalizedInput) {
            return foodCommand
        }

        // Check workout-specific navigation
        if let workoutCommand = parseWorkoutNavigation(normalizedInput) {
            return workoutCommand
        }

        // Check stats/progress navigation
        if let statsCommand = parseStatsNavigation(normalizedInput) {
            return statsCommand
        }

        return .none
    }

    // MARK: - Private Methods

    private func parseTabNavigation(_ input: String) -> LocalCommand? {
        let tabPatterns: [(pattern: String, tab: AppTab)] = [
            ("food|nutrition|meal", .nutrition),
            ("workout|exercise|gym", .workouts),
            ("coach|chat|ai", .chat),
            ("today|overview|home", .today),
            ("body|metric|weight|progress", .body)
        ]

        for (pattern, tab) in tabPatterns where input.range(of: pattern, options: .regularExpression) != nil {
            return .navigateToTab(tab)
        }

        return nil
    }

    private func parseEnhancedNavigation(_ input: String) -> LocalCommand? {
        // Recovery navigation
        if input.contains("recovery") || input.contains("rest") || input.contains("sleep") {
            return .showRecovery
        }

        return nil
    }

    private func parseFoodNavigation(_ input: String) -> LocalCommand? {
        // Check for food/meal navigation with context
        guard input.contains("food") || input.contains("meal") || input.contains("nutrition") ||
                input.contains("breakfast") || input.contains("lunch") || input.contains("dinner") || input.contains("snack") else {
            return nil
        }

        // Determine meal type if specified
        var mealType: MealType?
        if input.contains("breakfast") {
            mealType = .breakfast
        } else if input.contains("lunch") {
            mealType = .lunch
        } else if input.contains("dinner") {
            mealType = .dinner
        } else if input.contains("snack") {
            mealType = .snack
        }

        // Determine date if specified
        var date: Date?
        if input.contains("today") {
            date = Date()
        } else if input.contains("yesterday") {
            date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        } else if input.contains("tomorrow") {
            date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }

        return .showFood(date: date, mealType: mealType)
    }

    private func parseWorkoutNavigation(_ input: String) -> LocalCommand? {
        // Check for workout navigation with filters
        guard input.contains("workout") || input.contains("exercise") || input.contains("training") ||
                input.contains("gym") || input.contains("activity") else {
            return nil
        }

        // Determine filter if specified
        var filter: LocalCommand.WorkoutFilter?
        if input.contains("recent") || input.contains("last") {
            filter = .recent
        } else if input.contains("this week") || input.contains("week") {
            filter = .thisWeek
        } else if input.contains("this month") || input.contains("month") {
            filter = .thisMonth
        } else if input.contains("strength") || input.contains("weight") {
            filter = .type(.strength)
        } else if input.contains("cardio") || input.contains("run") || input.contains("bike") {
            filter = .type(.cardio)
        } else if input.contains("flexibility") || input.contains("stretch") || input.contains("yoga") {
            filter = .type(.flexibility)
        }

        return .showWorkouts(filter: filter)
    }

    private func parseStatsNavigation(_ input: String) -> LocalCommand? {
        // Check for stats/progress navigation
        let statsKeywords = ["stats", "statistics", "progress", "metrics", "data", "analytics", "insights"]
        guard statsKeywords.contains(where: input.contains) else {
            return nil
        }

        // Determine specific metric if mentioned
        var metric: String?
        if input.contains("weight") {
            metric = "weight"
        } else if input.contains("calories") || input.contains("energy") {
            metric = "calories"
        } else if input.contains("protein") {
            metric = "protein"
        } else if input.contains("steps") {
            metric = "steps"
        } else if input.contains("heart") || input.contains("hr") {
            metric = "heartRate"
        } else if input.contains("sleep") {
            metric = "sleep"
        }

        // Determine timeframe if specified
        var timeframe: LocalCommand.TimeFrame?
        if input.contains("today") {
            timeframe = .today
        } else if input.contains("this week") || input.contains("week") {
            timeframe = .thisWeek
        } else if input.contains("this month") || input.contains("month") {
            timeframe = .thisMonth
        } else if let match = input.range(of: #"last (\d+) days?"#, options: .regularExpression) {
            let numberStr = String(input[match]).replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if let days = Int(numberStr) {
                timeframe = .lastDays(days)
            }
        }

        if metric != nil {
            return .showStats(metric: metric)
        } else if timeframe != nil {
            return .showProgress(timeframe: timeframe)
        }

        return .showStats(metric: nil)
    }
}

// MARK: - Command Metadata
extension LocalCommand {
    var requiresNavigation: Bool {
        switch self {
        case .showDashboard, .navigateToTab, .showSettings,
             .showProfile, .startWorkout, .showFood, .showWorkouts,
             .showStats, .showRecovery, .showProgress:
            return true
        default:
            return false
        }
    }

    var analyticsName: String {
        switch self {
        case .showDashboard: return "show_dashboard"
        case .navigateToTab(let tab): return "navigate_\(tab)"
        case .quickLog(let type): return "quick_log_\(type)"
        case .showSettings: return "show_settings"
        case .showProfile: return "show_profile"
        case .startWorkout: return "start_workout"
        case .help: return "help"
        case .none: return "none"
        case .showFood: return "show_food"
        case .showWorkouts: return "show_workouts"
        case .showStats: return "show_stats"
        case .showRecovery: return "show_recovery"
        case .showProgress: return "show_progress"
        case .quickAction: return "quick_action"
        }
    }
}
