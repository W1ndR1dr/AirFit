import Foundation

/// Centralized feature toggles for personal-mode development.
/// Change defaults here for quick, reversible behavior adjustments.
enum FeatureToggles {
    /// If true, AI/API keys are optional for onboarding and initial app use.
    static let aiOptionalForOnboarding: Bool = true

    /// If true, skip the heavy onboarding flow and go straight to the dashboard after user creation.
    static let simpleOnboarding: Bool = false

    /// If false, the watch setup step is skipped (onboarding and scheme).
    static let watchSetupEnabled: Bool = false

    /// If true, use the new persona-first onboarding flow.
    static let newOnboardingEnabled: Bool = true
}
