import SwiftUI

/// Progress indicator for onboarding flow
struct OnboardingProgressIndicator: View {
    let progress: Double
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    private let totalSteps = 9
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, AppSpacing.xl)
    }
}

// MARK: - Convenience initializer for legacy phase-based progress
extension OnboardingProgressIndicator {
    init(currentPhase: Int) {
        self.progress = Double(currentPhase + 1) / 9.0
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        OnboardingProgressIndicator(progress: 0.1)
        OnboardingProgressIndicator(progress: 0.3)
        OnboardingProgressIndicator(progress: 0.5)
        OnboardingProgressIndicator(progress: 0.7)
        OnboardingProgressIndicator(progress: 0.9)
        OnboardingProgressIndicator(progress: 1.0)
    }
    .padding()
    .environmentObject(GradientManager())
}