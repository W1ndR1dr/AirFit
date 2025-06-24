import SwiftUI

/// Container view that handles DI resolution for OnboardingView
struct OnboardingContainerView: View {
    @Environment(\.diContainer) private var diContainer: DIContainer
    @State private var intelligence: OnboardingIntelligence?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Setting up...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let intelligence = intelligence {
                OnboardingView(intelligence: intelligence)
            } else if let error = error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Failed to initialize onboarding")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadIntelligence()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadIntelligence()
        }
    }
    
    private func loadIntelligence() async {
        isLoading = true
        error = nil
        
        do {
            intelligence = try await diContainer.resolve(OnboardingIntelligence.self)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            AppLogger.error("Failed to resolve OnboardingIntelligence", error: error, category: .app)
        }
    }
}
