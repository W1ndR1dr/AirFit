import Foundation

enum UserRole {
    case freeUser
    case premiumUser
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case personalInfo
    case healthGoals
    case notifications
    case completed
} 