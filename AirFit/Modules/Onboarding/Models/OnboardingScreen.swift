import Foundation

// MARK: - OnboardingScreen
enum OnboardingScreen: String, CaseIterable {
    case opening
    case healthKit
    case lifeContext
    case goals
    case weightObjectives
    case bodyComposition
    case communicationStyle
    case synthesis
    case coachReady
    
    var title: String {
        switch self {
        case .opening: return "Welcome"
        case .healthKit: return "Health Data"
        case .lifeContext: return "About You"
        case .goals: return "Your Goals"
        case .weightObjectives: return "Weight Goals"
        case .bodyComposition: return "Body Goals"
        case .communicationStyle: return "Coaching Style"
        case .synthesis: return "Creating Coach"
        case .coachReady: return "Coach Ready"
        }
    }
    
    var progress: Double {
        let screens = OnboardingScreen.allCases
        guard let index = screens.firstIndex(of: self) else { return 0 }
        return Double(index + 1) / Double(screens.count)
    }
    
    var next: OnboardingScreen? {
        let screens = OnboardingScreen.allCases
        guard let index = screens.firstIndex(of: self),
              index < screens.count - 1 else { return nil }
        return screens[index + 1]
    }
    
    var previous: OnboardingScreen? {
        let screens = OnboardingScreen.allCases
        guard let index = screens.firstIndex(of: self),
              index > 0 else { return nil }
        return screens[index - 1]
    }
}