import SwiftUI

// MARK: - Environment Keys

private struct DIContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue = DIContainer()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerEnvironmentKey.self] }
        set { self[DIContainerEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Inject a DI container into the environment
    func withDIContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }
}