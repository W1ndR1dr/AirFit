import SwiftUI

// MARK: - OnboardingNavigationButtons
struct OnboardingNavigationButtons: View {
    let backAction: () -> Void
    let nextAction: () -> Void
    let isNextEnabled: Bool
    let nextTitle: String
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    init(
        backAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        isNextEnabled: Bool = true,
        nextTitle: String = "action.next"
    ) {
        self.backAction = backAction
        self.nextAction = nextAction
        self.isNextEnabled = isNextEnabled
        self.nextTitle = nextTitle
    }

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: {
                HapticService.impact(.light)
                backAction()
            }) {
                Text("action.back")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.05),
                                Color.primary.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityIdentifier("onboarding.back.button")

            Button(action: {
                HapticService.impact(.medium)
                nextAction()
            }) {
                Text(LocalizedStringKey(nextTitle))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: isNextEnabled ?
                                gradientManager.active.colors(for: colorScheme) :
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: isNextEnabled ?
                            gradientManager.active.colors(for: colorScheme)[0].opacity(0.2) :
                            Color.clear,
                        radius: 8,
                        y: 2
                    )
            }
            .disabled(!isNextEnabled)
            .accessibilityIdentifier("onboarding.next.button")
        }
        .padding(.horizontal, AppSpacing.large)
    }
}
