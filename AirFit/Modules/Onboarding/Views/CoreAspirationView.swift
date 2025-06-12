import SwiftUI
import Observation

// MARK: - CoreAspirationView
struct CoreAspirationView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible())]

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    CascadeText("Core Aspiration")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text(LocalizedStringKey("onboarding.coreAspiration.prompt"))
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .accessibilityIdentifier("onboarding.goal.prompt")

                        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                            ForEach(Goal.GoalFamily.allCases, id: \.self) { family in
                                goalCard(family: family)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        Text(LocalizedStringKey("onboarding.coreAspiration.freeformPrompt"))
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)

                        HStack(alignment: .center, spacing: AppSpacing.sm) {
                            TextField("", text: $viewModel.goal.rawText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .padding(AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .accessibilityIdentifier("onboarding.goal.text")

                            Button {
                                HapticService.impact(.light)
                                if viewModel.isTranscribing {
                                    viewModel.stopVoiceCapture()
                                } else {
                                    viewModel.startVoiceCapture()
                                }
                            } label: {
                                Image(systemName: viewModel.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        viewModel.isTranscribing
                                            ? LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                              )
                                            : LinearGradient(
                                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                              )
                                    )
                            }
                            .accessibilityIdentifier("onboarding.goal.voice")
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .accessibilityIdentifier("onboarding.coreAspiration")

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
                        Task {
                            await viewModel.analyzeGoalText()
                            viewModel.navigateToNextScreen()
                        }
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
    }

    private func goalCard(family: Goal.GoalFamily) -> some View {
        Button {
            HapticService.impact(.light)
            viewModel.goal.family = family
        } label: {
            HStack {
                Text(family.displayName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.goal.family == family {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GlassCard {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        viewModel.goal.family == family 
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
        .accessibilityIdentifier("onboarding.goal.\(family.rawValue)")
    }
}