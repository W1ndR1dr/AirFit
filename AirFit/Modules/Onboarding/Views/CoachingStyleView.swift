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
                        PersonaPreviewCard(selectedPersona: viewModel.selectedPersonaMode)
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
