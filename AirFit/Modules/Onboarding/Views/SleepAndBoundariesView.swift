import SwiftUI
import Observation

// MARK: - SleepAndBoundariesView
struct SleepAndBoundariesView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var bedMinutes: Double
    @State private var wakeMinutes: Double

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        _bedMinutes = State(initialValue: Self.minutes(from: viewModel.sleepWindow.bedTime))
        _wakeMinutes = State(initialValue: Self.minutes(from: viewModel.sleepWindow.wakeTime))
    }

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    CascadeText("Sleep Schedule")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(LocalizedStringKey("onboarding.sleep.prompt"))
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary)
                                .accessibilityIdentifier("onboarding.sleep.prompt")
                            
                            if viewModel.hasHealthKitIntegration {
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Pre-filled from HealthKit when available")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Time Sliders
                        VStack(spacing: AppSpacing.lg) {
                            timeSlider(
                                title: LocalizedStringKey("onboarding.sleep.bedtime"),
                                icon: "moon.fill",
                                minutes: $bedMinutes,
                                id: "onboarding.sleep.bedtime"
                            )
                            .onChange(of: bedMinutes) { _, newValue in
                                viewModel.sleepWindow.bedTime = Self.hhmm(from: newValue)
                            }

                            timeSlider(
                                title: LocalizedStringKey("onboarding.sleep.waketime"),
                                icon: "sun.max.fill",
                                minutes: $wakeMinutes,
                                id: "onboarding.sleep.waketime"
                            )
                            .onChange(of: wakeMinutes) { _, newValue in
                                viewModel.sleepWindow.wakeTime = Self.hhmm(from: newValue)
                            }
                        }

                        // Sleep Consistency Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text(LocalizedStringKey("onboarding.sleep.rhythmPrompt"))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(SleepWindow.SleepConsistency.allCases, id: \.self) { option in
                                    radioOption(
                                        title: option.displayName,
                                        isSelected: viewModel.sleepWindow.consistency == option,
                                        action: {
                                            HapticService.impact(.light)
                                            viewModel.sleepWindow.consistency = option
                                        },
                                        id: "onboarding.sleep.consistency.\(option.rawValue)"
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }

                        // Timezone Info
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text("Timezone: \(viewModel.timezone)")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
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
        .accessibilityIdentifier("onboarding.sleepBoundaries")
    }

    // MARK: - Helpers
    private func timeSlider(title: LocalizedStringKey, icon: String, minutes: Binding<Double>, id: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Text(displayTime(minutes.wrappedValue))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .accessibilityLabel("Time: \(displayTime(minutes.wrappedValue))")
            }

            Slider(value: minutes, in: 0...1_439, step: 15)
                .tint(Color.accentColor)
                .accessibilityIdentifier(id)
                .accessibilityHint("Adjust time by dragging the slider")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, AppSpacing.lg)
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

    private func displayTime(_ minutes: Double) -> String {
        let total = Int(minutes) % (24 * 60)
        let hour = total / 60
        let minute = total % 60
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func minutes(from hhmm: String) -> Double {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Double(parts[0]),
              let m = Double(parts[1]) else { return 0 }
        return h * 60 + m
    }

    private static func hhmm(from minutes: Double) -> String {
        let total = Int(minutes) % (24 * 60)
        let h = total / 60
        let m = total % 60
        return String(format: "%02d:%02d", h, m)
    }
}