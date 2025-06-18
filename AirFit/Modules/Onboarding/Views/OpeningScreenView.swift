import SwiftUI
import Observation

struct OpeningScreenView: View {
    @Bindable var viewModel: OnboardingViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false
    @State private var iconScale: CGFloat = 0.5
    
    // Compute optimal text colors based on gradient using color theory
    private var textColor: Color {
        gradientManager.active.optimalTextColor(for: colorScheme)
    }
    
    private var secondaryTextColor: Color {
        gradientManager.active.secondaryTextColor(for: colorScheme)
    }
    
    private var accentColor: Color {
        gradientManager.active.accentColor(for: colorScheme)
    }

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                Spacer()
                Spacer()  // Extra spacer for status bar area

                // Animated icon with gradient
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .scaleEffect(iconScale)
                    .opacity(animateIn ? 1 : 0)
                    .padding(.bottom, AppSpacing.lg)

                // Welcome text with cascade animation
                if animateIn {
                    CascadeText("Welcome to AirFit")
                        .font(.system(size: 44, weight: .thin, design: .rounded))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.sm)
                }
                
                // Subtitle - text directly on gradient (o3-inspired)
                Text("Your personal AI fitness coach")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).delay(0.3), value: animateIn)

                Spacer()

                // Single action button - simplified
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        HapticService.impact(.light)
                        viewModel.beginOnboarding()
                    } label: {
                        Text("Let's begin")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: accentColor.opacity(0.3), 
                                    radius: 8, x: 0, y: 4)
                    }
                    .accessibilityIdentifier("onboarding.begin.button")
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 60)  // Account for home indicator + extra space
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