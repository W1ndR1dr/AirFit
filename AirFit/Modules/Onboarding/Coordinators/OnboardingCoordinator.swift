import SwiftUI
import Observation

@MainActor
@Observable
final class OnboardingCoordinator {
    var path = NavigationPath()
    var currentScreen: OnboardingScreen = .openingScreen

    func navigateToNext() {
        let allScreens = OnboardingScreen.allCases
        guard let currentIndex = allScreens.firstIndex(of: currentScreen),
              currentIndex < allScreens.count - 1 else { return }

        currentScreen = allScreens[currentIndex + 1]
        path.append(currentScreen)
    }

    func navigateToPrevious() {
        let allScreens = OnboardingScreen.allCases
        guard let currentIndex = allScreens.firstIndex(of: currentScreen),
              currentIndex > 0 else { return }

        currentScreen = allScreens[currentIndex - 1]
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func navigateTo(_ screen: OnboardingScreen) {
        currentScreen = screen
        path.append(screen)
    }

    func reset() {
        path = NavigationPath()
        currentScreen = .openingScreen
    }
}
