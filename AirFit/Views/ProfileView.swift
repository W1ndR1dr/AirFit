import SwiftUI

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct ProfileView: View {
    @State private var profile: APIClient.ProfileResponse?
    @State private var isLoading = true
    @State private var showClearConfirm = false
    @State private var showClearChatConfirm = false

    // Settings state
    @State private var serverStatus: ServerInfo?
    @State private var isLoadingSettings = true

    // Appearance
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private let apiClient = APIClient()

    var body: some View {
        ZStack {
            // Ethereal background
            EtherealBackground(currentTab: 4)
                .ignoresSafeArea()

            Group {
                if isLoading {
                    loadingView
                } else if let profile = profile {
                    if profile.has_profile {
                        profileContent(profile)
                    } else {
                        emptyState
                    }
                } else {
                    errorState
                }
            }
        }
        .navigationTitle("What I Know")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if profile?.has_profile == true {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showClearConfirm = true
                    } label: {
                        Text("Clear")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.error)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
            }
        }
        .confirmationDialog(
            "Clear all learned data?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Everything", role: .destructive) {
                Task { await clearProfile() }
            }
        } message: {
            Text("The AI will start fresh and learn about you again through conversation.")
        }
        .confirmationDialog(
            "Clear chat history?",
            isPresented: $showClearChatConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                Task { await clearSession() }
            }
        } message: {
            Text("This will start a fresh conversation with the AI coach.")
        }
        .refreshable {
            await loadAll()
        }
        .task {
            await loadAll()
        }
    }

    private func loadAll() async {
        async let profileTask: () = loadProfile()
        async let statusTask: () = loadStatus()
        await profileTask
        await statusTask
    }

    private func loadStatus() async {
        isLoadingSettings = true
        do {
            serverStatus = try await apiClient.getServerStatus()
        } catch {
            serverStatus = nil
        }
        withAnimation(.airfit) {
            isLoadingSettings = false
        }
    }

    private func clearSession() async {
        do {
            try await apiClient.clearSession()
            await loadStatus()
        } catch {
            print("Failed to clear session: \(error)")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Theme.accent)

            Text("Loading profile...")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: APIClient.ProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goals Section
                if !profile.goals.isEmpty {
                    ProfileSection(title: "GOALS", icon: "target", color: Theme.accent) {
                        ForEach(profile.goals, id: \.self) { goal in
                            ProfileItem(text: goal, icon: "checkmark.circle.fill", color: Theme.accent)
                        }
                    }
                }

                // About You Section
                if !profile.context.isEmpty {
                    ProfileSection(title: "ABOUT YOU", icon: "person.fill", color: Theme.protein) {
                        ForEach(profile.context, id: \.self) { item in
                            ProfileItem(text: item, icon: "info.circle.fill", color: Theme.protein)
                        }
                    }
                }

                // Preferences Section
                if !profile.preferences.isEmpty {
                    ProfileSection(title: "PREFERENCES", icon: "heart.fill", color: Theme.secondary) {
                        ForEach(profile.preferences, id: \.self) { pref in
                            ProfileItem(text: pref, icon: "heart.fill", color: Theme.secondary)
                        }
                    }
                }

                // Constraints Section
                if !profile.constraints.isEmpty {
                    ProfileSection(title: "CONSTRAINTS", icon: "exclamationmark.triangle.fill", color: Theme.warning) {
                        ForEach(profile.constraints, id: \.self) { constraint in
                            ProfileItem(text: constraint, icon: "exclamationmark.circle.fill", color: Theme.warning)
                        }
                    }
                }

                // Patterns Section
                if !profile.patterns.isEmpty {
                    ProfileSection(title: "PATTERNS I'VE NOTICED", icon: "chart.line.uptrend.xyaxis", color: Theme.tertiary) {
                        ForEach(profile.patterns, id: \.self) { pattern in
                            ProfileItem(text: pattern, icon: "waveform.path.ecg", color: Theme.tertiary)
                        }
                    }
                }

                // Communication Style
                if !profile.communication_style.isEmpty {
                    ProfileSection(title: "COMMUNICATION", icon: "bubble.left.fill", color: Theme.accent) {
                        ProfileItem(text: profile.communication_style, icon: "text.bubble.fill", color: Theme.accent)
                    }
                }

                // Recent Insights
                if !profile.recent_insights.isEmpty {
                    ProfileSection(title: "RECENT INSIGHTS", icon: "lightbulb.fill", color: Theme.warm) {
                        ForEach(profile.recent_insights, id: \.date) { insight in
                            InsightItem(insight: insight)
                        }
                    }
                }

                // Stats footer
                HStack {
                    Spacer()
                    Text("Total insights: \(profile.insights_count)")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .padding(.top, 8)

                // Settings Section
                settingsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 24) {
            // Appearance
            ProfileSection(title: "APPEARANCE", icon: "paintbrush.fill", color: Theme.warm) {
                Picker("Appearance", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Server Status
            ProfileSection(title: "SERVER", icon: "server.rack", color: Theme.tertiary) {
                HStack {
                    Text("Status")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if isLoadingSettings {
                        ProgressView()
                            .tint(Theme.accent)
                    } else if serverStatus != nil {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.success)
                                .frame(width: 8, height: 8)
                            Text("Connected")
                                .font(.labelMedium)
                                .foregroundStyle(Theme.success)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.error)
                                .frame(width: 8, height: 8)
                            Text("Disconnected")
                                .font(.labelMedium)
                                .foregroundStyle(Theme.error)
                        }
                    }
                }

                if let status = serverStatus {
                    HStack {
                        Text("Host")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(status.host)
                            .font(.labelMedium)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            // AI Provider Section
            if let status = serverStatus {
                ProfileSection(title: "AI PROVIDER", icon: "brain", color: Theme.accent) {
                    HStack {
                        Text("Active")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(status.activeProvider.capitalized)
                            .font(.labelLarge)
                            .foregroundStyle(Theme.accent)
                    }

                    ForEach(status.availableProviders, id: \.self) { provider in
                        HStack {
                            Text(provider.capitalized)
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(Theme.success)
                        }
                    }
                }

                // Session Section
                if let sessionId = status.sessionId {
                    ProfileSection(title: "SESSION", icon: "number", color: Theme.protein) {
                        HStack {
                            Text("ID")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(String(sessionId.prefix(8)) + "...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.textMuted)
                        }

                        if let messageCount = status.messageCount {
                            HStack {
                                Text("Messages")
                                    .font(.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text("\(messageCount)")
                                    .font(.labelLarge)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        Button {
                            showClearChatConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.caption)
                                Text("Clear Chat History")
                                    .font(.labelMedium)
                            }
                            .foregroundStyle(Theme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(AirFitButtonStyle())
                    }
                }
            }

            // App Info Section
            ProfileSection(title: "ABOUT", icon: "info.circle", color: Theme.secondary) {
                HStack {
                    Text("Version")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                }

                HStack {
                    Text("Build")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.5)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: 8) {
                Text("I'm still learning about you")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("As we chat and you log food, I'll pick up on your goals, preferences, and patterns.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(AirFitButtonStyle())
        }
        .padding(40)
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(Theme.textMuted)

            VStack(spacing: 8) {
                Text("Couldn't load profile")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("Check your connection and try again.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(AirFitButtonStyle())
        }
        .padding(40)
    }

    // MARK: - Actions

    private func loadProfile() async {
        isLoading = true
        do {
            profile = try await apiClient.getProfile()
        } catch {
            print("Failed to load profile: \(error)")
            profile = nil
        }
        withAnimation(.airfit) {
            isLoading = false
        }
    }

    private func clearProfile() async {
        isLoading = true
        do {
            try await apiClient.clearProfile()
            profile = try await apiClient.getProfile()
            // Post notification for other views
            NotificationCenter.default.post(name: .profileReset, object: nil)
        } catch {
            print("Failed to clear profile: \(error)")
            profile = nil
        }
        withAnimation(.airfit) {
            isLoading = false
        }
    }

    private func formatDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: isoDate) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return isoDate
    }
}

// MARK: - Profile Section

struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            // Content
            VStack(spacing: 12) {
                content()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Profile Item

struct ProfileItem: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Insight Item

struct InsightItem: View {
    let insight: APIClient.ProfileInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(insight.insight)
                .font(.bodyMedium)
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Text(insight.source.uppercased())
                    .font(.labelMicro)
                    .tracking(1)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Text(formatDate(insight.date))
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: isoDate) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return isoDate
    }
}

// MARK: - Server Info Model

struct ServerInfo {
    let host: String
    let activeProvider: String
    let availableProviders: [String]
    let sessionId: String?
    let messageCount: Int?
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
