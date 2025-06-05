import SwiftUI
import Observation
import SwiftData

// MARK: - PersonaSelectionView
struct PersonaSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.persona.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.persona.prompt")

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
        .accessibilityIdentifier("onboarding.personaSelection")
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
                    .lineLimit(3)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Preview

private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func getAPIKey(for provider: AIProvider) async throws -> String {
        return "preview-key"
    }
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return true
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return [.openAI, .anthropic, .gemini]
    }
}

private final class PreviewUserService: UserServiceProtocol {
    func getCurrentUser() -> User? {
        nil
    }
    
    func createUser(from profile: OnboardingProfile) async throws -> User {
        User(email: profile.email, name: profile.name)
    }
    
    func updateProfile(_ updates: ProfileUpdate) async throws {
        // No-op for preview
    }
    
    func getCurrentUserId() async -> UUID? {
        nil
    }
    
    func completeOnboarding() async throws {
        // No-op for preview
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        // No-op for preview
    }
    
    func deleteUser(_ user: User) async throws {
        // No-op for preview
    }
}

#Preview {
    PersonaSelectionView(viewModel: {
        let tempContainer = try! ModelContainer(
            for: OnboardingProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return OnboardingViewModel(
            aiService: OfflineAIService(),
            onboardingService: OnboardingService(modelContext: tempContainer.mainContext),
            modelContext: tempContainer.mainContext,
            apiKeyManager: PreviewAPIKeyManager(),
            userService: PreviewUserService()
        )
    }())
} 