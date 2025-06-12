import SwiftUI
import Observation

// MARK: - CoachingStyleView
struct CoachingStyleView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    CascadeText("Coaching Style")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text(LocalizedStringKey("onboarding.coaching.prompt"))
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .accessibilityIdentifier("onboarding.coaching.header")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.md) {
                            ForEach(PersonaMode.allCases, id: \.self) { persona in
                                PersonaOptionCard(
                                    persona: persona,
                                    isSelected: viewModel.selectedPersonaMode == persona,
                                    onTap: {
                                        HapticService.impact(.light)
                                        viewModel.selectedPersonaMode = persona
                                    }
                                )
                                .accessibilityIdentifier("onboarding.persona.\(persona.rawValue)")
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        if viewModel.selectedPersonaMode != .supportiveCoach {
                            PersonaPreviewCard(preview: PersonaPreview(
                                name: viewModel.selectedPersonaMode.displayName,
                                archetype: getArchetype(for: viewModel.selectedPersonaMode),
                                sampleGreeting: getSampleGreeting(for: viewModel.selectedPersonaMode),
                                voiceDescription: getVoiceDescription(for: viewModel.selectedPersonaMode)
                            ))
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.navigateToPreviousScreen()
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Button {
                        viewModel.validatePersonaSelection()
                        viewModel.navigateToNextScreen()
                    } label: {
                        Text("Next")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding.coachingStyle")
    }
}

// MARK: - PersonaOptionCard
private struct PersonaOptionCard: View {
    let persona: PersonaMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(persona.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(
                            isSelected
                                ? LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [Color.secondary, Color.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                }

                Text(persona.description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
            .background(
                GlassCard {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Functions

private func getArchetype(for mode: PersonaMode) -> String {
    switch mode {
    case .supportiveCoach:
        return "The Empathetic Mentor"
    case .directTrainer:
        return "The Results-Driven Coach"
    case .analyticalAdvisor:
        return "The Data-Driven Expert"
    case .motivationalBuddy:
        return "The Energetic Companion"
    }
}

private func getSampleGreeting(for mode: PersonaMode) -> String {
    switch mode {
    case .supportiveCoach:
        return "Good morning! How are you feeling today? Let's work together to make today a great one, no matter where you're starting from."
    case .directTrainer:
        return "Morning! Time to get to work. Let's review your goals and plan today's actions for maximum impact."
    case .analyticalAdvisor:
        return "Good morning! Based on your recent metrics, I've identified some optimization opportunities for today's routine."
    case .motivationalBuddy:
        return "Hey there superstar! 🌟 Ready to crush some goals today? Let's make fitness fun and exciting!"
    }
}

private func getVoiceDescription(for mode: PersonaMode) -> String {
    switch mode {
    case .supportiveCoach:
        return "Warm and understanding, speaks with patience and genuine care"
    case .directTrainer:
        return "Clear and confident, focused on actionable guidance"
    case .analyticalAdvisor:
        return "Thoughtful and precise, explains the reasoning behind recommendations"
    case .motivationalBuddy:
        return "Upbeat and playful, brings enthusiasm to every interaction"
    }
}
