import SwiftUI
import Observation

// MARK: - EngagementPreferencesView
struct EngagementPreferencesView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.engagement.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.engagement.prompt")

                    VStack(spacing: AppSpacing.medium) {
                        presetCard(
                            title: "Data-Driven Partnership",
                            style: .dataDrivenPartnership,
                            id: "onboarding.engagement.dataDriven"
                        )
                        presetCard(
                            title: "Balanced & Consistent",
                            style: .balancedConsistent,
                            id: "onboarding.engagement.balanced"
                        )
                        presetCard(
                            title: "Guidance on Demand",
                            style: .guidanceOnDemand,
                            id: "onboarding.engagement.guidance"
                        )
                        presetCard(
                            title: "Customise My Preferences",
                            style: .custom,
                            id: "onboarding.engagement.custom"
                        )
                    }
                    .padding(.horizontal, AppSpacing.large)

                    if viewModel.engagementPreferences.trackingStyle == .custom {
                        customOptions
                    }
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: handleNext
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding.engagementPreferences")
    }

    // MARK: - Preset Card
    private func presetCard(
        title: LocalizedStringKey,
        style: EngagementPreferences.TrackingStyle,
        id: String
    ) -> some View {
        Button(
            action: { selectPreset(style) },
            label: {
                HStack {
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    if viewModel.engagementPreferences.trackingStyle == style {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accentColor)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                        .stroke(
                            viewModel.engagementPreferences.trackingStyle == style ? AppColors.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
            }
        )
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    // MARK: - Custom Options
    @ViewBuilder private var customOptions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Information Depth:")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, AppSpacing.medium)

            ForEach(EngagementPreferences.InformationDepth.allCases, id: \.self) { depth in
                radioOption(
                    title: depth.displayName,
                    isSelected: viewModel.engagementPreferences.informationDepth == depth,
                    action: { viewModel.engagementPreferences.informationDepth = depth },
                    id: "onboarding.engagement.depth.\(depth.rawValue)"
                )
            }

            Text("Proactivity & Updates:")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, AppSpacing.medium)

            ForEach(EngagementPreferences.UpdateFrequency.allCases, id: \.self) { freq in
                radioOption(
                    title: freq.displayName,
                    isSelected: viewModel.engagementPreferences.updateFrequency == freq,
                    action: { viewModel.engagementPreferences.updateFrequency = freq },
                    id: "onboarding.engagement.frequency.\(freq.rawValue)"
                )
            }

            Toggle(isOn: $viewModel.engagementPreferences.autoRecoveryLogicPreference) {
                Text("Automatically suggest workout adjustments based on my recovery data")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.accentColor))
            .padding(.top, AppSpacing.medium)
            .accessibilityIdentifier("onboarding.engagement.autoRecovery")
        }
        .padding(.horizontal, AppSpacing.large)
    }

    private func radioOption(title: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
        Button(
            action: action
        ) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(AppColors.accentColor)
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.xSmall)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func handleNext() {
        viewModel.navigateToNextScreen()
    }

    private func selectPreset(_ preset: EngagementPreferences.TrackingStyle) {
        viewModel.engagementPreferences.trackingStyle = preset
        switch preset {
        case .dataDrivenPartnership:
            viewModel.engagementPreferences.informationDepth = .detailed
            viewModel.engagementPreferences.updateFrequency = .daily
            viewModel.engagementPreferences.autoRecoveryLogicPreference = true
        case .balancedConsistent:
            viewModel.engagementPreferences.informationDepth = .keyMetrics
            viewModel.engagementPreferences.updateFrequency = .weekly
            viewModel.engagementPreferences.autoRecoveryLogicPreference = true
        case .guidanceOnDemand:
            viewModel.engagementPreferences.informationDepth = .essentialOnly
            viewModel.engagementPreferences.updateFrequency = .onDemand
            viewModel.engagementPreferences.autoRecoveryLogicPreference = false
        case .custom:
            break
        }
    }
}

// MARK: - NavigationButtons
private struct NavigationButtons: View {
    var backAction: () -> Void
    var nextAction: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(
                action: backAction
            ) {
                Text(LocalizedStringKey("action.back"))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.back.button")

            Button(
                action: nextAction
            ) {
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
