import SwiftUI
import Observation

// MARK: - CoachProfileReadyView
struct CoachProfileReadyView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var checkScale: CGFloat = 0.5
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Success checkmark with gradient
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentGradient(for: colorScheme))
                            .frame(width: 120, height: 120)
                            .opacity(0.2)
                            .scaleEffect(checkScale * 1.3)
                            .blur(radius: 20)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                            .scaleEffect(checkScale)
                    }
                    .padding(.top, AppSpacing.xl)
                    .onAppear {
                        withAnimation(
                            .interpolatingSpring(stiffness: 200, damping: 15)
                            .delay(0.2)
                        ) {
                            checkScale = 1.0
                        }
                    }

                    // Title with cascade animation
                    if animateIn {
                        CascadeText("Your AirFit Coach Profile Is Ready")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.screenPadding)
                    }

                    Text("Meet your personalized AirFit Coach. This profile, based on your choices, will guide every interaction.")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                    // Summary cards with glass morphism
                    VStack(spacing: AppSpacing.sm) {
                        SummaryCard(
                            title: "Your Primary Aspiration",
                            text: aspirationText,
                            icon: "star.fill",
                            delay: 0.4
                        )
                        SummaryCard(
                            title: "Your Coach's Style",
                            text: styleText,
                            icon: "text.bubble.fill",
                            delay: 0.5
                        )
                        SummaryCard(
                            title: "Engagement & Updates",
                            text: engagementText,
                            icon: "bell.fill",
                            delay: 0.6
                        )
                        SummaryCard(
                            title: "Communication Boundaries",
                            text: boundariesText,
                            icon: "moon.fill",
                            delay: 0.7
                        )
                        SummaryCard(
                            title: "Acknowledging Success",
                            text: celebrationText,
                            icon: "hands.sparkles.fill",
                            delay: 0.8
                        )
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)

                    // Baseline toggle with glass card
                    GlassCard {
                        Toggle(isOn: $viewModel.baselineModeEnabled) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                                
                                Text("Establish my 14-day baseline before providing in-depth recommendations")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: gradientManager.active == .peachRose ? Color.pink : Color.blue))
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.9), value: animateIn)

                    // Action buttons
                    VStack(spacing: AppSpacing.sm) {
                        StandardButton(
                            "Begin with My AirFit Coach",
                            icon: "sparkles",
                            style: .primary,
                            isFullWidth: true
                        ) {
                            Task {
                                do {
                                    try await viewModel.completeOnboarding()
                                } catch {
                                    AppLogger.error("Failed to complete onboarding",
                                                    error: error,
                                                    category: .onboarding)
                                }
                            }
                        }
                        .accessibilityIdentifier("onboarding.beginCoach.button")

                        StandardButton(
                            "Review & Refine Profile",
                            icon: "slider.horizontal.3",
                            style: .secondary,
                            isFullWidth: true
                        ) {
                            viewModel.navigateToPreviousScreen()
                        }
                        .accessibilityIdentifier("onboarding.reviewProfile.button")
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xl)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(1.0), value: animateIn)
                }
            }
            .accessibilityIdentifier("onboarding.coachProfileReady")
            .onAppear {
                withAnimation(MotionToken.standardSpring.delay(0.1)) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Computed Text
    private var aspirationText: String {
        let text = viewModel.goal.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? viewModel.goal.family.displayName : text
    }

    private var styleText: String {
        let persona = viewModel.selectedPersonaMode
        return "Your coach will embody the \(persona.displayName) persona. \(persona.description)"
    }

    private var engagementText: String {
        let depth = viewModel.engagementPreferences.informationDepth.displayName
        let freq = viewModel.engagementPreferences.updateFrequency.displayName.lowercased()
        let recovery = viewModel.engagementPreferences.autoRecoveryLogicPreference ?
            "suggested automatically" : "adjusted only when you decide"
        return "Your coach will focus on \(depth) and provide updates \(freq). " +
            "Workout adaptations will be \(recovery)."
    }

    private var boundariesText: String {
        "Quiet hours are respected between \(viewModel.sleepWindow.bedTime) - " +
            "\(viewModel.sleepWindow.wakeTime) (\(viewModel.timezone)). " +
            "If you're inactive, your coach will \(viewModel.motivationalStyle.absenceResponse.description.lowercased())."
    }

    private var celebrationText: String {
        "Achievements will be met with a \(viewModel.motivationalStyle.celebrationStyle.displayName.lowercased())."
    }

}

// MARK: - SummaryCard
private struct SummaryCard: View {
    let title: String
    let text: String
    let icon: String
    let delay: Double
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(text)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(delay)) {
                animateIn = true
            }
        }
    }
}
