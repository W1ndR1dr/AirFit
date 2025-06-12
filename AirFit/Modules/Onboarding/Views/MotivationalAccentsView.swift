import SwiftUI
import Observation

// MARK: - MotivationalAccentsView
struct MotivationalAccentsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    CascadeText("Motivational Style")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        Text(LocalizedStringKey("onboarding.motivation.prompt"))
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .accessibilityIdentifier("onboarding.motivation.prompt")

                        // Celebration Style Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text(LocalizedStringKey("onboarding.motivation.celebrationPrompt"))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(MotivationalStyle.CelebrationStyle.allCases, id: \.self) { style in
                                    radioOption(
                                        title: style.displayName,
                                        description: style.description,
                                        isSelected: viewModel.motivationalStyle.celebrationStyle == style,
                                        action: {
                                            HapticService.impact(.light)
                                            viewModel.motivationalStyle.celebrationStyle = style
                                        },
                                        id: "onboarding.motivation.celebration.\(style.rawValue)"
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }

                        // Absence Response Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text(LocalizedStringKey("onboarding.motivation.absencePrompt"))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(MotivationalStyle.AbsenceResponse.allCases, id: \.self) { style in
                                    radioOption(
                                        title: style.displayName,
                                        description: style.description,
                                        isSelected: viewModel.motivationalStyle.absenceResponse == style,
                                        action: {
                                            HapticService.impact(.light)
                                            viewModel.motivationalStyle.absenceResponse = style
                                        },
                                        id: "onboarding.motivation.absence.\(style.rawValue)"
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(.bottom, AppSpacing.lg)
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
        .accessibilityIdentifier("onboarding.motivationalAccents")
    }

    // MARK: - Helpers
    private func radioOption(
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        id: String
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
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
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.accentColor.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}