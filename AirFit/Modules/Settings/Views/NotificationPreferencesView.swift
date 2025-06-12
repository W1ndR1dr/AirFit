import SwiftUI

struct NotificationPreferencesView: View {
    var viewModel: SettingsViewModel
    @State private var preferences: NotificationPreferences
    @State private var quietHours: QuietHours
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _preferences = State(initialValue: viewModel.notificationPreferences)
        _quietHours = State(initialValue: viewModel.quietHours)
    }
    
    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("Notifications")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)
                    
                    VStack(spacing: AppSpacing.xl) {
                        systemNotificationStatus
                        notificationTypes
                        quietHoursSection
                        saveButton
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var systemNotificationStatus: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("System Settings")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Notification Status")
                                .font(.headline)
                            Text(preferences.systemEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundStyle(preferences.systemEnabled ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.openSystemNotificationSettings()
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    if !preferences.systemEnabled {
                        Label {
                            Text("Enable notifications in Settings to receive alerts from AirFit")
                                .font(.caption)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }
    
    private var notificationTypes: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Notification Types")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    NotificationToggle(
                        title: "Workout Reminders",
                        description: "Daily motivation to stay active",
                        icon: "figure.run",
                        isOn: $preferences.workoutReminders
                    )
                    
                    Divider()
                    
                    NotificationToggle(
                        title: "Meal Reminders",
                        description: "Track your nutrition on time",
                        icon: "fork.knife",
                        isOn: $preferences.mealReminders
                    )
                    
                    Divider()
                    
                    NotificationToggle(
                        title: "Daily Check-ins",
                        description: "Log your progress and mood",
                        icon: "checkmark.square",
                        isOn: $preferences.dailyCheckins
                    )
                    
                    Divider()
                    
                    NotificationToggle(
                        title: "Achievement Alerts",
                        description: "Celebrate your milestones",
                        icon: "trophy",
                        isOn: $preferences.achievementAlerts
                    )
                    
                    Divider()
                    
                    NotificationToggle(
                        title: "Coach Messages",
                        description: "Personalized guidance from your AI coach",
                        icon: "bubble.left.and.bubble.right",
                        isOn: $preferences.coachMessages
                    )
                }
            }
            .disabled(!preferences.systemEnabled)
        }
    }
    
    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Quiet Hours")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    Toggle(isOn: $quietHours.enabled) {
                        Label {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("Enable Quiet Hours")
                                    .font(.headline)
                                Text("Pause notifications during set hours")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    
                    if quietHours.enabled {
                        Divider()
                        
                        VStack(spacing: AppSpacing.md) {
                            DatePicker(
                                "Start Time",
                                selection: $quietHours.startTime,
                                displayedComponents: .hourAndMinute
                            )
                            
                            DatePicker(
                                "End Time",
                                selection: $quietHours.endTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                        .disabled(!preferences.systemEnabled)
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            savePreferences()
        } label: {
            Label("Save Preferences", systemImage: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: (preferences != viewModel.notificationPreferences || quietHours != viewModel.quietHours)
                            ? [Color.accentColor, Color.accentColor.opacity(0.8)]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!(preferences != viewModel.notificationPreferences || quietHours != viewModel.quietHours))
    }
    
    private func savePreferences() {
        Task {
            do {
                try await viewModel.updateNotificationPreferences(preferences)
                try await viewModel.updateQuietHours(quietHours)
                HapticService.impact(.medium)
            } catch {
                // Error is handled by the view model
                AppLogger.error("Failed to update notification preferences", error: error, category: .general)
            }
        }
    }
}

// MARK: - Supporting Views
struct NotificationToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(.subheadline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
            }
        }
    }
}

// NotificationPreferences already conforms to Codable which includes Equatable

// QuietHours already conforms to Equatable
/*extension QuietHours: Equatable {
    static func == (lhs: QuietHours, rhs: QuietHours) -> Bool {
        lhs.enabled == rhs.enabled &&
        Calendar.current.dateComponents([.hour, .minute], from: lhs.startTime) ==
        Calendar.current.dateComponents([.hour, .minute], from: rhs.startTime) &&
        Calendar.current.dateComponents([.hour, .minute], from: lhs.endTime) ==
        Calendar.current.dateComponents([.hour, .minute], from: rhs.endTime)
    }
}*/