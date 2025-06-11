import SwiftUI
import Observation

struct OpeningScreenView: View {
    @Bindable var viewModel: OnboardingViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                Spacer()

                // Animated icon with gradient
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .scaleEffect(iconScale)
                    .opacity(animateIn ? 1 : 0)
                    .padding(.bottom, AppSpacing.lg)

                // AirFit title with cascade animation
                if animateIn {
                    CascadeText("AirFit")
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .padding(.bottom, AppSpacing.xl)
                }

                // Glass card for main content
                GlassCard {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Let's design your")
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("AirFit Coach")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))

                        Text("Est. 3-4 minutes to create your personalized experience")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, AppSpacing.xs)
                    }
                    .padding(.vertical, AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                Spacer()

                // Action buttons
                VStack(spacing: AppSpacing.sm) {
                    StandardButton(
                        "Begin",
                        style: .primary,
                        isFullWidth: true
                    ) {
                        viewModel.navigateToNextScreen()
                    }
                    .accessibilityIdentifier("onboarding.begin.button")

                    Button(
                        action: {
                            AppLogger.info("Onboarding skipped", category: .onboarding)
                        },
                        label: {
                            Text("Maybe Later")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    )
                    .accessibilityIdentifier("onboarding.skip.button")
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.lg)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
            }
        }
        .onAppear {
            // Orchestrated entrance animation
            withAnimation(MotionToken.standardSpring.delay(0.2)) {
                animateIn = true
            }
            
            // Icon bounce effect
            withAnimation(
                .interpolatingSpring(stiffness: 180, damping: 15)
                .delay(0.4)
            ) {
                iconScale = 1.0
            }
        }
    }
}
