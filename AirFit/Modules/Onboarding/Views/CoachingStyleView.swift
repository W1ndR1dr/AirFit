import SwiftUI
import Observation

// MARK: - CoachingStyleView (Phase 4 Refactored)
struct CoachingStyleView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(LocalizedStringKey("onboarding.coaching.title"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(LocalizedStringKey("onboarding.coaching.prompt"))
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.large)
                    .accessibilityIdentifier("onboarding.coaching.header")

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.medium) {
                        ForEach(PersonaMode.allCases, id: \.self) { persona in
                            PersonaOptionCard(
                                persona: persona,
                                isSelected: viewModel.selectedPersonaMode == persona,
                                onTap: {
                                    viewModel.selectedPersonaMode = persona
                                }
                            )
                            .accessibilityIdentifier("onboarding.persona.\(persona.rawValue)")
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)
                    
                    if viewModel.selectedPersonaMode != .supportiveCoach {
                        PersonaPreviewCard(preview: PersonaPreview(
                            name: viewModel.selectedPersonaMode.displayName,
                            archetype: getArchetype(for: viewModel.selectedPersonaMode),
                            sampleGreeting: getSampleGreeting(for: viewModel.selectedPersonaMode),
                            voiceDescription: getVoiceDescription(for: viewModel.selectedPersonaMode)
                        ))
                        .padding(.horizontal, AppSpacing.large)
                    }
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: {
                    viewModel.validatePersonaSelection()
                    viewModel.navigateToNextScreen()
                }
            )
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
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text(persona.displayName)
                        .font(AppFonts.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accentColor)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Text(persona.description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .fill(isSelected ? AppColors.accentColor.opacity(0.1) : AppColors.cardBackground)
                    .stroke(
                        isSelected ? AppColors.accentColor : AppColors.dividerColor,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PersonaStylePreviewCard
private struct PersonaStylePreviewCard: View {
    let selectedPersona: PersonaMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(AppColors.accentColor)
                Text("Preview: \(selectedPersona.displayName)")
                    .font(AppFonts.captionBold)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            Text(selectedPersona.description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                .fill(AppColors.accentColor.opacity(0.05))
                .stroke(AppColors.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - NavigationButtons
private struct NavigationButtons: View {
    var backAction: () -> Void
    var nextAction: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: backAction) {
                Text(LocalizedStringKey("action.back"))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.back.button")

            Button(action: nextAction) {
                Text(LocalizedStringKey("action.next"))
                    .font(AppFonts.bodyBold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.next.button")
        }
        .padding(.horizontal, AppSpacing.large)
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
