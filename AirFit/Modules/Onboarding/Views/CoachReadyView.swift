import SwiftUI

struct CoachReadyView: View {
    @Bindable
    var viewModel: OnboardingViewModel
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @EnvironmentObject
    private var gradientManager: GradientManager
    
    @State private var animateIn = false
    @State private var showDescription = false
    @State private var showButtons = false
    
    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.large) {
                Spacer()
                    .frame(height: AppSpacing.xxLarge)
                
                // Success icon with celebration animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIn)
                
                // Main heading
                CascadeText("We're all set!")
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .opacity(animateIn ? 1 : 0)
                
                Spacer()
                    .frame(height: AppSpacing.large)
                
                // Generated coach description
                if let synthesis = viewModel.synthesizedGoals {
                    VStack(spacing: AppSpacing.medium) {
                        Text(generateCoachDescription(from: synthesis))
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .opacity(showDescription ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5).delay(1.2),
                                value: showDescription
                            )
                        
                        // Key focus areas
                        if !synthesis.coachingFocus.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text("Here's what we'll focus on:")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                ForEach(synthesis.coachingFocus.prefix(3), id: \.self) { focus in
                                    HStack(spacing: AppSpacing.small) {
                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                                        Text(focus)
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(AppSpacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            .opacity(showDescription ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5).delay(1.5),
                                value: showDescription
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.medium)
                } else {
                    // Fallback description if synthesis failed
                    Text("I'm your new AI fitness buddy - thoughtful, adaptive, and ready to help you crush your goals.")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .opacity(showDescription ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.5).delay(1.2),
                            value: showDescription
                        )
                        .padding(.horizontal, AppSpacing.medium)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: AppSpacing.medium) {
                    // Primary action - complete onboarding
                    Button {
                        HapticService.impact(.light)
                        Task {
                            await viewModel.completeOnboarding()
                        }
                    } label: {
                        HStack {
                            Text("Let's do this")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.footnote)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.medium)
                        .background(
                            gradientManager.currentGradient(for: colorScheme)
                                .shadow(.drop(color: .black.opacity(0.15), radius: 10, x: 0, y: 5))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    // Secondary action - learn more
                    Button {
                        HapticService.impact(.soft)
                        // TODO: Show coach details or tips
                    } label: {
                        Text("Wait, tell me more")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }
                .padding(.horizontal, AppSpacing.large)
                .padding(.bottom, AppSpacing.large)
                .opacity(showButtons ? 1 : 0)
                .animation(
                    .easeOut(duration: 0.5).delay(2.0),
                    value: showButtons
                )
            }
        }
        .onAppear {
            // Gradient has settled on user's home color
            gradientManager.setGradient(.sageMelon)
            
            // Trigger animations
            animateIn = true
            showDescription = true
            showButtons = true
            
            // Celebration haptic
            HapticService.notification(.success)
        }
    }
    
    private func generateCoachDescription(from synthesis: LLMGoalSynthesis) -> String {
        // Create a personalized description based on synthesis
        let strategy = synthesis.unifiedStrategy
        
        // Use the persona mode if available, otherwise use a default description
        if let persona = viewModel.generatedPersona {
            return "I'm your \(persona.name) coach, here to help you \(strategy). I'll work around your life and celebrate every win along the way."
        } else {
            return "I'm your personal coach, here to help you \(strategy). I'll work around your life and celebrate every win."
        }
    }
}