import SwiftUI
import Observation

/// Manages navigation for the Onboarding module
/// Uses SimpleCoordinator since we only need navigation (no sheets or alerts)
/// Tracks current screen for linear flow navigation
@MainActor
@Observable
final class OnboardingCoordinator: SimpleCoordinator<OnboardingScreen> {
    var currentScreen: OnboardingScreen = .opening

    func navigateToNext() {
        let allScreens = OnboardingScreen.allCases
        guard let currentIndex = allScreens.firstIndex(of: currentScreen),
              currentIndex < allScreens.count - 1 else { return }

        currentScreen = allScreens[currentIndex + 1]
        navigateTo(currentScreen)
    }

    func navigateToPrevious() {
        let allScreens = OnboardingScreen.allCases
        guard let currentIndex = allScreens.firstIndex(of: currentScreen),
              currentIndex > 0 else { return }

        currentScreen = allScreens[currentIndex - 1]
        pop()
    }

    override func navigateTo(_ screen: OnboardingScreen) {
        currentScreen = screen
        super.navigateTo(screen)
    }

    func reset() {
        popToRoot()
        currentScreen = .opening
    }
}
