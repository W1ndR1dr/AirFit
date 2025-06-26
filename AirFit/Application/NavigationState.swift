import SwiftUI
import Observation
import SwiftData

/// Manages app-wide navigation state and cross-tab communication
///
/// NavigationState serves as the central navigation hub for the AI-centric app experience.
/// It coordinates between tabs, manages the floating AI assistant state, and handles
/// voice navigation intents.
@MainActor
@Observable
public final class NavigationState {
    // MARK: - Tab Management
    public var selectedTab: AppTab = .chat
    public var previousTab: AppTab?
    
    // MARK: - AI Chat State
    public var isChatMinimized = false
    public var hasUnreadMessages = false
    public var lastAIPrompt: String?
    
    // MARK: - Cross-Tab Communication
    public var pendingChatPrompt: String?
    public var navigationIntent: NavigationIntent?
    
    // MARK: - Voice State
    public var isListeningForWakeWord = true
    public var voiceInputActive = false
    
    // MARK: - Floating Assistant State
    public var fabPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 160)
    public var fabDragOffset: CGSize = .zero
    public var fabScale: CGFloat = 1.0
    public var fabIsExpanded = false
    
    // MARK: - Quick Action State
    public var suggestedQuickActions: [QuickAction] = []
    public var lastQuickActionUpdate = Date()
    
    // MARK: - Public Methods
    
    /// Navigate to a specific tab with optional intent
    public func navigateToTab(_ tab: AppTab, with intent: NavigationIntent? = nil) {
        previousTab = selectedTab
        selectedTab = tab
        navigationIntent = intent
        
        // Haptic feedback for tab switches
        HapticService.impact(.light)
        
        AppLogger.info("NavigationState: Navigated to \(tab.rawValue) tab", category: .app)
    }
    
    /// Return to the previous tab
    public func navigateToPreviousTab() {
        if let previous = previousTab {
            let current = selectedTab
            selectedTab = previous
            previousTab = current
            
            HapticService.impact(.light)
            AppLogger.info("NavigationState: Returned to \(previous.rawValue) tab", category: .app)
        }
    }
    
    /// Show chat from any screen
    public func showChat(with prompt: String? = nil) {
        pendingChatPrompt = prompt
        navigateToTab(.chat)
        isChatMinimized = false
        fabIsExpanded = false
    }
    
    /// Toggle floating assistant expansion
    public func toggleFAB() {
        withAnimation(.spring(duration: 0.3)) {
            fabIsExpanded.toggle()
            fabScale = fabIsExpanded ? 1.2 : 1.0
        }
        HapticService.impact(.medium)
    }
    
    /// Update quick actions based on context
    public func updateQuickActions(for context: AppContext) {
        let hour = Calendar.current.component(.hour, from: Date())
        var actions: [QuickAction] = []
        
        // Time-based suggestions
        switch hour {
        case 6...9:
            if !context.hasLoggedBreakfast {
                actions.append(QuickAction(
                    title: "Log Breakfast",
                    subtitle: "Start your day right",
                    systemImage: "sunrise.fill",
                    color: "orange",
                    action: .logMeal(type: .breakfast)
                ))
            }
        case 11...13:
            if !context.hasLoggedLunch {
                actions.append(QuickAction(
                    title: "Log Lunch",
                    subtitle: "Track your midday meal",
                    systemImage: "sun.max.fill",
                    color: "yellow",
                    action: .logMeal(type: .lunch)
                ))
            }
        case 17...20:
            if !context.hasLoggedDinner {
                actions.append(QuickAction(
                    title: "Log Dinner",
                    subtitle: "End the day well",
                    systemImage: "moon.fill",
                    color: "purple",
                    action: .logMeal(type: .dinner)
                ))
            }
        default:
            break
        }
        
        // Activity-based suggestions
        if let lastWorkout = context.lastWorkoutDate,
           Calendar.current.dateComponents([.day], from: lastWorkout, to: Date()).day ?? 0 > 2 {
            actions.append(QuickAction(
                title: "Start Workout",
                subtitle: "Time to get moving",
                systemImage: "figure.run",
                color: "green",
                action: .startWorkout
            ))
        }
        
        // Hydration reminder
        if context.waterIntakeML < context.waterGoalML * 0.5 {
            actions.append(QuickAction(
                title: "Log Water",
                subtitle: "Stay hydrated",
                systemImage: "drop.fill",
                color: "blue",
                action: .logWater
            ))
        }
        
        suggestedQuickActions = Array(actions.prefix(3)) // Limit to 3 suggestions
        lastQuickActionUpdate = Date()
    }
    
    /// Handle navigation intent execution
    public func executeIntent(_ intent: NavigationIntent) {
        navigationIntent = intent
        
        switch intent {
        case .showFood:
            navigateToTab(.food)
        case .startWorkout:
            navigateToTab(.workouts)
        case .showStats:
            navigateToTab(.profile)
        case .logQuickAction(let type):
            handleQuickAction(type)
        case .executeCommand(let command):
            executeLocalCommand(command)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleQuickAction(_ type: QuickAction.QuickActionType) {
        switch type {
        case .logMeal(let mealType):
            navigateToTab(.food, with: .showFood(date: Date(), mealType: mealType))
        case .logWater:
            // This could trigger a quick water logging sheet
            pendingChatPrompt = "Log water intake"
            showChat()
        case .startWorkout:
            navigateToTab(.workouts, with: .startWorkout(type: nil))
        case .checkIn:
            navigateToTab(.dashboard)
        }
    }
    
    private func executeLocalCommand(_ command: LocalCommand) {
        switch command {
        case .showDashboard:
            navigateToTab(.dashboard)
        case .navigateToTab(let tab):
            navigateToTab(tab)
        case .showProfile:
            navigateToTab(.profile)
        case .startWorkout:
            navigateToTab(.workouts, with: .startWorkout(type: nil))
        default:
            // Other commands might be handled by chat
            pendingChatPrompt = "Execute command: \(command)"
            showChat()
        }
    }
}

// MARK: - Supporting Types

/// Represents a navigation intent that can be executed across tabs
public enum NavigationIntent: Hashable {
    case showFood(date: Date?, mealType: MealType?)
    case startWorkout(type: WorkoutType?)
    case showStats(metric: String?) // TODO: Replace with proper HealthMetric when available
    case logQuickAction(type: QuickAction.QuickActionType)
    case executeCommand(parsed: LocalCommand)
    
    public static func == (lhs: NavigationIntent, rhs: NavigationIntent) -> Bool {
        switch (lhs, rhs) {
        case let (.showFood(lDate, lType), .showFood(rDate, rType)):
            return lDate == rDate && lType == rType
        case let (.startWorkout(lType), .startWorkout(rType)):
            return lType == rType
        case let (.showStats(lMetric), .showStats(rMetric)):
            return lMetric == rMetric
        case let (.logQuickAction(lType), .logQuickAction(rType)):
            return lType == rType
        case (.executeCommand, .executeCommand):
            return true // LocalCommand already conforms to Equatable
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .showFood(date, mealType):
            hasher.combine("showFood")
            hasher.combine(date)
            hasher.combine(mealType)
        case let .startWorkout(type):
            hasher.combine("startWorkout")
            hasher.combine(type)
        case let .showStats(metric):
            hasher.combine("showStats")
            hasher.combine(metric)
        case let .logQuickAction(type):
            hasher.combine("logQuickAction")
            hasher.combine(type)
        case .executeCommand:
            hasher.combine("executeCommand")
        }
    }
}

/// Context for making intelligent navigation decisions
public struct AppContext {
    public let hasLoggedBreakfast: Bool
    public let hasLoggedLunch: Bool
    public let hasLoggedDinner: Bool
    public let lastWorkoutDate: Date?
    public let waterIntakeML: Double
    public let waterGoalML: Double
    public let currentTab: AppTab
    public let timeOfDay: TimeOfDay
    
    public enum TimeOfDay {
        case morning, afternoon, evening, night
    }
}

// MARK: - Extensions

extension NavigationState {
    /// Create a mock instance for previews
    static var preview: NavigationState {
        let state = NavigationState()
        state.suggestedQuickActions = [
            QuickAction(
                title: "Log Breakfast",
                subtitle: "Start your day right",
                systemImage: "sunrise.fill",
                color: "orange",
                action: .logMeal(type: .breakfast)
            ),
            QuickAction(
                title: "Log Water",
                subtitle: "Stay hydrated",
                systemImage: "drop.fill",
                color: "blue",
                action: .logWater
            ),
            QuickAction(
                title: "Start Workout",
                subtitle: "Time to get moving",
                systemImage: "figure.run",
                color: "green",
                action: .startWorkout
            )
        ]
        return state
    }
}