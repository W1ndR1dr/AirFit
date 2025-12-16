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

// MARK: - Profile View

struct ProfileView: View {
    @State private var profile: APIClient.ProfileResponse?
    @State private var isLoading = true
    @State private var showSettings = false

    private let apiClient = APIClient()

    var body: some View {
        ZStack {
            if isLoading {
                ShimmerLoadingView(text: "Connecting...")
            } else if let profile = profile {
                if profile.has_profile {
                    profileContent(profile)
                } else {
                    emptyState
                }
            } else {
                errorState
            }

            // Settings button overlay - always accessible
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .refreshable {
            await loadProfile()
        }
        .task {
            await loadProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileReset)) { _ in
            Task { await loadProfile() }
        }
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: APIClient.ProfileResponse) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                ProfileHeroView(
                    name: profile.name,
                    summary: profile.summary,
                    phase: profile.current_phase,
                    phaseContext: profile.phase_context
                )
                .padding(.top, 8)

                // What you're working toward
                if !profile.goals.isEmpty {
                    ProfileSectionView(
                        title: "What you're working toward",
                        items: profile.goals,
                        category: "goals",
                        onItemUpdated: { old, new in updateItem("goals", old, new) },
                        onItemDeleted: { item in deleteItem("goals", item) }
                    )
                }

                // What I've learned
                if !profile.context.isEmpty {
                    ProfileSectionView(
                        title: "What I've learned",
                        items: profile.context,
                        category: "context",
                        onItemUpdated: { old, new in updateItem("context", old, new) },
                        onItemDeleted: { item in deleteItem("context", item) }
                    )
                }

                // Your preferences
                if !profile.preferences.isEmpty {
                    ProfileSectionView(
                        title: "Your preferences",
                        items: profile.preferences,
                        category: "preferences",
                        onItemUpdated: { old, new in updateItem("preferences", old, new) },
                        onItemDeleted: { item in deleteItem("preferences", item) }
                    )
                }

                // Things to keep in mind
                if !profile.constraints.isEmpty {
                    ProfileSectionView(
                        title: "Things to keep in mind",
                        items: profile.constraints,
                        category: "constraints",
                        onItemUpdated: { old, new in updateItem("constraints", old, new) },
                        onItemDeleted: { item in deleteItem("constraints", item) }
                    )
                }

                // Patterns I'm noticing
                if !profile.patterns.isEmpty {
                    ProfileSectionView(
                        title: "Patterns I'm noticing",
                        items: profile.patterns,
                        category: "patterns",
                        onItemUpdated: { old, new in updateItem("patterns", old, new) },
                        onItemDeleted: { item in deleteItem("patterns", item) }
                    )
                }

                // How we talk (read-only for now - communication_style is a single string)
                if !profile.communication_style.isEmpty {
                    ProfileSectionView(
                        title: "How we talk",
                        items: [profile.communication_style]
                    )
                }

                // Recent insights
                if !profile.recent_insights.isEmpty {
                    RecentInsightsSection(insights: profile.recent_insights)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private func updateItem(_ category: String, _ oldValue: String, _ newValue: String) {
        Task {
            do {
                try await apiClient.updateProfileItem(category: category, oldValue: oldValue, newValue: newValue)
                await loadProfile()
            } catch {
                print("Failed to update item: \(error)")
            }
        }
    }

    private func deleteItem(_ category: String, _ value: String) {
        Task {
            do {
                try await apiClient.updateProfileItem(category: category, oldValue: value, newValue: nil)
                await loadProfile()
            } catch {
                print("Failed to delete item: \(error)")
            }
        }
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("As we chat and you log food, I'll pick up on your goals, preferences, and patterns.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Check your connection and try again.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
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
        withAnimation(.easeOut(duration: 0.2)) {
            isLoading = false
        }
    }
}

// MARK: - Profile Hero View

struct ProfileHeroView: View {
    let name: String?
    let summary: String?
    let phase: String?
    let phaseContext: String?

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Name
            if let name = name, !name.isEmpty {
                Text(name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            // Summary (one-liner)
            if let summary = summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Phase badge
            if let phase = phase, !phase.isEmpty {
                HStack(spacing: 8) {
                    Text(phase.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(phaseColor)

                    if let context = phaseContext, !context.isEmpty {
                        Text("•")
                            .foregroundStyle(Theme.textMuted)
                        Text(context)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(phaseColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var initials: String {
        guard let name = name, !name.isEmpty else { return "?" }
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var phaseColor: Color {
        guard let phase = phase?.lowercased() else { return Theme.accent }
        switch phase {
        case "cut", "cutting": return Theme.error
        case "bulk", "bulking": return Theme.success
        case "maintain", "maintenance": return Theme.accent
        default: return Theme.accent
        }
    }
}

// MARK: - Profile Section View

struct ProfileSectionView: View {
    let title: String
    let items: [String]
    var category: String = ""  // For edit API: "goals", "context", etc.
    var onItemUpdated: ((String, String) -> Void)?  // (oldValue, newValue)
    var onItemDeleted: ((String) -> Void)?

    @State private var isExpanded = false
    @State private var editingItem: String?
    @State private var editText = ""

    private let previewCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            // Items
            VStack(alignment: .leading, spacing: 10) {
                ForEach(displayItems, id: \.self) { item in
                    if editingItem == item {
                        // Edit mode
                        ProfileItemEditor(
                            text: $editText,
                            onSave: {
                                if !editText.isEmpty && editText != item {
                                    onItemUpdated?(item, editText)
                                }
                                editingItem = nil
                            },
                            onCancel: {
                                editingItem = nil
                            },
                            onDelete: {
                                onItemDeleted?(item)
                                editingItem = nil
                            }
                        )
                    } else {
                        // Display mode
                        Text(item)
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if onItemUpdated != nil {
                                    editText = item
                                    editingItem = item
                                }
                            }
                    }
                }

                // Show more button
                if items.count > previewCount {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Show less" : "Show \(items.count - previewCount) more")
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .animation(.easeOut(duration: 0.2), value: editingItem)
    }

    private var displayItems: [String] {
        if isExpanded || items.count <= previewCount {
            return items
        }
        return Array(items.prefix(previewCount))
    }
}

// MARK: - Profile Item Editor

struct ProfileItemEditor: View {
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("", text: $text, axis: .vertical)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .lineLimit(1...5)
                .padding(12)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(Theme.error)
                }

                Button(action: onSave) {
                    Text("Save")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Recent Insights Section

struct RecentInsightsSection: View {
    let insights: [APIClient.ProfileInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent insights")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 16) {
                ForEach(insights.prefix(3), id: \.date) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.insight)
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)

                        Text(formatDate(insight.date))
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }

                    if insight.date != insights.prefix(3).last?.date {
                        Divider()
                            .background(Theme.textMuted.opacity(0.2))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
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
