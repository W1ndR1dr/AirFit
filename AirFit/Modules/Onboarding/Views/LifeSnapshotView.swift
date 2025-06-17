import SwiftUI
import Observation

// MARK: - LifeSnapshotView
struct LifeSnapshotView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    Text("Life Snapshot")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, 60)  // Account for status bar + extra space
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Understanding your daily rhythm helps your coach provide relevant support. Tap what generally applies:")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.lg)
                            .accessibilityIdentifier("onboarding.life.prompt")

                        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.md) {
                            checkbox(
                                text: "My work is primarily at a desk",
                                binding: $viewModel.lifeContext.isDeskJob,
                                id: "onboarding.life.desk_job"
                            )
                            checkbox(
                                text: "I'm often on my feet or physically active at work",
                                binding: $viewModel.lifeContext.isPhysicallyActiveWork,
                                id: "onboarding.life.active_work"
                            )
                            checkbox(
                                text: "I travel frequently (for work or leisure)",
                                binding: $viewModel.lifeContext.travelsFrequently,
                                id: "onboarding.life.travel"
                            )
                            checkbox(
                                text: "I have children / significant family care responsibilities",
                                binding: $viewModel.lifeContext.hasChildrenOrFamilyCare,
                                id: "onboarding.life.family_care"
                            )
                            checkbox(
                                text: "My schedule is generally predictable",
                                binding: Binding(
                                    get: { viewModel.lifeContext.scheduleType == .predictable },
                                    set: { if $0 { viewModel.lifeContext.scheduleType = .predictable } }
                                ),
                                id: "onboarding.life.schedule_predictable"
                            )
                            checkbox(
                                text: "My schedule is often unpredictable or chaotic",
                                binding: Binding(
                                    get: { viewModel.lifeContext.scheduleType == .unpredictableChaotic },
                                    set: { if $0 { viewModel.lifeContext.scheduleType = .unpredictableChaotic } }
                                ),
                                id: "onboarding.life.schedule_unpredictable"
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("My preferred time for workouts is typically:")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(LifeContext.WorkoutWindow.allCases, id: \.self) { option in
                                    workoutOption(option)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
                .accessibilityIdentifier("onboarding.lifeSnapshot")

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
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 40)  // Account for home indicator
            }
        }
    }

    private func checkbox(text: String, binding: Binding<Bool>, id: String) -> some View {
        Toggle(isOn: binding) {
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .toggleStyle(GradientCheckboxToggleStyle())
        .accessibilityIdentifier(id)
    }

    private func workoutOption(_ option: LifeContext.WorkoutWindow) -> some View {
        Button {
            HapticService.impact(.light)
            viewModel.lifeContext.workoutWindowPreference = option
        } label: {
            HStack {
                Image(systemName: workoutOptionIcon(for: option))
                    .font(.system(size: 20))
                    .foregroundStyle(
                        viewModel.lifeContext.workoutWindowPreference == option
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
                Text(option.displayName)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                viewModel.lifeContext.workoutWindowPreference == option
                                    ? Color.accentColor.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.life.workout_\(option.rawValue)")
    }

    private func workoutOptionIcon(for option: LifeContext.WorkoutWindow) -> String {
        viewModel.lifeContext.workoutWindowPreference == option ? "largecircle.fill.circle" : "circle"
    }
}

// MARK: - GradientCheckboxToggleStyle
private struct GradientCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            HapticService.impact(.light)
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .center, spacing: AppSpacing.xs) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        configuration.isOn
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
                configuration.label
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}