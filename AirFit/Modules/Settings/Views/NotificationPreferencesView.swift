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
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                systemNotificationStatus
                notificationTypes
                quietHoursSection
                saveButton
            }
            .padding()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var systemNotificationStatus: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "System Settings", icon: "bell.badge")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Notification Status")
                                .font(.headline)
                            Text(preferences.systemEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundStyle(preferences.systemEnabled ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button("Open Settings") {
                            viewModel.openSystemNotificationSettings()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Notification Types", icon: "bell")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Quiet Hours", icon: "moon.zzz")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    Toggle(isOn: $quietHours.enabled) {
                        Label {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
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
                        
                        VStack(spacing: AppSpacing.medium) {
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
        Button(action: savePreferences) {
            Label("Save Preferences", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryProminent)
        .disabled(preferences == viewModel.notificationPreferences && quietHours == viewModel.quietHours)
    }
    
    private func savePreferences() {
        Task {
            do {
                try await viewModel.updateNotificationPreferences(preferences)
                try await viewModel.updateQuietHours(quietHours)
                HapticManager.notification(.success)
            } catch {
                // Error is handled by the view model
                print("Failed to update notification preferences: \(error)")
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