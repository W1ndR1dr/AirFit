import SwiftUI

struct ProfileView: View {
    @State private var profile: APIClient.ProfileResponse?
    @State private var isLoading = true
    @State private var showClearConfirm = false

    private let apiClient = APIClient()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
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
            .navigationTitle("What I Know")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if profile?.has_profile == true {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            showClearConfirm = true
                        }
                        .foregroundColor(.red)
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
        }
        .task {
            await loadProfile()
        }
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: APIClient.ProfileResponse) -> some View {
        List {
            if !profile.goals.isEmpty {
                Section("Goals") {
                    ForEach(profile.goals, id: \.self) { goal in
                        Label(goal, systemImage: "target")
                    }
                }
            }

            if !profile.context.isEmpty {
                Section("About You") {
                    ForEach(profile.context, id: \.self) { item in
                        Label(item, systemImage: "person.fill")
                    }
                }
            }

            if !profile.preferences.isEmpty {
                Section("Preferences") {
                    ForEach(profile.preferences, id: \.self) { pref in
                        Label(pref, systemImage: "heart.fill")
                    }
                }
            }

            if !profile.constraints.isEmpty {
                Section("Constraints") {
                    ForEach(profile.constraints, id: \.self) { constraint in
                        Label(constraint, systemImage: "exclamationmark.triangle.fill")
                    }
                }
            }

            if !profile.patterns.isEmpty {
                Section("Patterns I've Noticed") {
                    ForEach(profile.patterns, id: \.self) { pattern in
                        Label(pattern, systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }

            if !profile.communication_style.isEmpty {
                Section("Communication") {
                    Label(profile.communication_style, systemImage: "bubble.left.fill")
                }
            }

            if !profile.recent_insights.isEmpty {
                Section("Recent Insights") {
                    ForEach(profile.recent_insights, id: \.date) { insight in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.insight)
                                .font(.subheadline)
                            HStack {
                                Text(insight.source)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Capsule())
                                Spacer()
                                Text(formatDate(insight.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section {
                Text("Total insights: \(profile.insights_count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("I'm still learning about you")
                .font(.headline)

            Text("As we chat and you log food, I'll pick up on your goals, preferences, and patterns.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Couldn't load profile")
                .font(.headline)

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
        }
        .padding()
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
        isLoading = false
    }

    private func clearProfile() async {
        isLoading = true
        do {
            try await apiClient.clearProfile()
            profile = try await apiClient.getProfile()
        } catch {
            print("Failed to clear profile: \(error)")
            profile = nil
        }
        isLoading = false
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

#Preview {
    ProfileView()
}
