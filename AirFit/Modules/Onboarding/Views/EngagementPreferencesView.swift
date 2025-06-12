import SwiftUI
import Observation

// MARK: - EngagementPreferencesView
struct EngagementPreferencesView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    CascadeText("Engagement Style")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text(LocalizedStringKey("onboarding.engagement.prompt"))
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .accessibilityIdentifier("onboarding.engagement.prompt")

                        VStack(spacing: AppSpacing.md) {
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
                        .padding(.horizontal, AppSpacing.lg)

                        if viewModel.engagementPreferences.trackingStyle == .custom {
                            customOptions
                        }
                    }
                    .padding(.bottom, AppSpacing.lg)
                }

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.navigateToPreviousScreen()
                    } label: {
                        Text(LocalizedStringKey("action.back"))
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
                    .accessibilityIdentifier("onboarding.back.button")
                    
                    Button {
                        viewModel.navigateToNextScreen()
                    } label: {
                        Text(LocalizedStringKey("action.next"))
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
                    .accessibilityIdentifier("onboarding.next.button")
                }
                .padding(AppSpacing.lg)
            }
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
        Button {
            HapticService.impact(.light)
            selectPreset(style)
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.engagementPreferences.trackingStyle == style {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
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
                        viewModel.engagementPreferences.trackingStyle == style
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
        .accessibilityIdentifier(id)
    }

    // MARK: - Custom Options
    @ViewBuilder private var customOptions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Information Depth Section
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Information Depth:")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(EngagementPreferences.InformationDepth.allCases, id: \.self) { depth in
                        radioOption(
                            title: depth.displayName,
                            isSelected: viewModel.engagementPreferences.informationDepth == depth,
                            action: {
                                HapticService.impact(.light)
                                viewModel.engagementPreferences.informationDepth = depth
                            },
                            id: "onboarding.engagement.depth.\(depth.rawValue)"
                        )
                    }
                }
            }

            // Update Frequency Section
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Proactivity & Updates:")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(EngagementPreferences.UpdateFrequency.allCases, id: \.self) { freq in
                        radioOption(
                            title: freq.displayName,
                            isSelected: viewModel.engagementPreferences.updateFrequency == freq,
                            action: {
                                HapticService.impact(.light)
                                viewModel.engagementPreferences.updateFrequency = freq
                            },
                            id: "onboarding.engagement.frequency.\(freq.rawValue)"
                        )
                    }
                }
            }

            // Auto Recovery Toggle
            HStack {
                Toggle(isOn: $viewModel.engagementPreferences.autoRecoveryLogicPreference) {
                    Text("Automatically suggest workout adjustments based on my recovery data")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .tint(Color.accentColor)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .accessibilityIdentifier("onboarding.engagement.autoRecovery")
        }
        .padding(.horizontal, AppSpacing.lg)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.smooth, value: viewModel.engagementPreferences.trackingStyle)
    }

    private func radioOption(title: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
        Button(action: action) {
            HStack {
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
                Text(title)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
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