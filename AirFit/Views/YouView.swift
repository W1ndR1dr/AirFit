import SwiftUI
import UniformTypeIdentifiers

// MARK: - Unified "You" View
/// The user's personal hub - shows what the AI knows about them,
/// with settings access secondary to personal information.

struct YouView: View {
    // MARK: - State

    @Environment(\.modelContext) private var modelContext

    // Profile data (device-first: LocalProfile is authoritative)
    @State private var profile: APIClient.ProfileResponse?  // Server fallback
    @State private var localProfile: LocalProfile?           // Primary source
    @State private var isLoading = true

    // Server/Connection state
    @State private var serverStatus: ServerInfo?
    @State private var isCheckingConnection = false

    // Gemini state
    @State private var hasGeminiKey = false
    @State private var isTestingGemini = false
    @State private var geminiTestResult: (success: Bool, message: String)?

    // UI state
    @State private var showCoachConfig = false
    @State private var showAdvanced = false
    @State private var showServerSetup = false
    @State private var showGeminiSetup = false
    @State private var geminiAPIKeyInput = ""

    // Export/Import state
    @State private var showExportShare = false
    @State private var exportData: Data?
    @State private var showImportPicker = false
    @State private var importError: String?
    @State private var showImportSuccess = false

    // Settings (persisted)
    @AppStorage("aiProvider") private var aiProvider: String = "claude"
    @AppStorage("appearanceMode") private var appearanceMode: String = "System"
    @AppStorage("hasAcceptedGeminiTerms") private var hasAcceptedGeminiTerms = false

    // Privacy settings
    @AppStorage("geminiShareNutrition") private var geminiShareNutrition = true
    @AppStorage("geminiShareWorkouts") private var geminiShareWorkouts = true
    @AppStorage("geminiShareHealth") private var geminiShareHealth = false
    @AppStorage("geminiShareProfile") private var geminiShareProfile = false

    // Thinking level setting (for Gemini)
    @AppStorage("geminiThinkingLevel") private var geminiThinkingLevelRaw = ThinkingLevel.medium.rawValue

    private let apiClient = APIClient()
    private let keychainManager = KeychainManager.shared

    // MARK: - Computed Properties

    /// Combined profile for display - LocalProfile is authoritative when available
    private var displayProfile: APIClient.ProfileResponse? {
        // If we have LocalProfile data, use it (device-first architecture)
        if let local = localProfile, local.hasProfile {
            return APIClient.ProfileResponse(
                name: local.name,
                summary: local.summary,
                goals: local.goals ?? [],
                constraints: local.constraints ?? [],
                preferences: local.preferences ?? [],
                context: local.lifeContext ?? [],
                patterns: local.patterns ?? [],
                communication_style: "",
                insights_count: 0,
                recent_insights: [],  // Insights come from server
                has_profile: true,
                onboarding_complete: local.onboardingComplete,
                current_phase: local.goalPhase,
                phase_context: local.phaseContext
            )
        }
        // Fall back to server profile
        return profile
    }

    /// The effective AI mode based on current configuration
    private var currentMode: AIMode {
        switch aiProvider {
        case "claude": return .claude
        case "gemini": return .gemini
        case "both": return .both
        default: return .claude
        }
    }

    /// Whether Claude is properly configured
    private var isClaudeReady: Bool {
        serverStatus != nil
    }

    /// Whether Gemini is properly configured
    private var isGeminiReady: Bool {
        hasGeminiKey && (geminiTestResult?.success ?? false || geminiTestResult == nil)
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable {
                await loadAll()
            }
            .task {
                await loadAll()
            }
            .onReceive(NotificationCenter.default.publisher(for: .profileReset)) { _ in
                Task { await loadAll() }
            }
            .sheet(isPresented: $showCoachConfig) {
                CoachConfigurationSheet(
                    currentMode: $aiProvider,
                    thinkingLevelRaw: $geminiThinkingLevelRaw,
                    shareNutrition: $geminiShareNutrition,
                    shareWorkouts: $geminiShareWorkouts,
                    shareHealth: $geminiShareHealth,
                    shareProfile: $geminiShareProfile,
                    isClaudeReady: isClaudeReady,
                    isGeminiReady: isGeminiReady,
                    serverStatus: serverStatus,
                    onServerSetup: {
                        showCoachConfig = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showServerSetup = true
                        }
                    },
                    onGeminiSetup: {
                        showCoachConfig = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showGeminiSetup = true
                        }
                    },
                    onDismiss: { showCoachConfig = false }
                )
            }
            .sheet(isPresented: $showServerSetup) {
                NavigationStack {
                    ServerSetupView(
                        onComplete: {
                            showServerSetup = false
                            Task { await checkConnection() }
                        },
                        onSkip: {
                            showServerSetup = false
                        }
                    )
                    .navigationTitle("Server Setup")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showServerSetup = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showGeminiSetup) {
                GeminiSetupSheet(
                    apiKeyInput: $geminiAPIKeyInput,
                    hasGeminiKey: hasGeminiKey,
                    isTestingGemini: isTestingGemini,
                    testResult: geminiTestResult,
                    onSave: saveGeminiKey,
                    onTest: testGeminiConnection,
                    onRemove: removeGeminiKey,
                    onDismiss: { showGeminiSetup = false }
                )
            }
            .sheet(isPresented: $showExportShare) {
                if let data = exportData {
                    ProfileExportShareSheet(data: data)
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleProfileImport(result)
            }
            .alert("Import Successful", isPresented: $showImportSuccess) {
                Button("OK") {}
            } message: {
                Text("Your profile has been restored.")
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "Unknown error")
            }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Quick Settings Row (Appearance at top)
                quickSettingsRow
                    .padding(.top, 8)

                // 2. Profile Hero (uses displayProfile: LocalProfile first, server fallback)
                if let displayedProfile = displayProfile, displayedProfile.has_profile {
                    ProfileHeroView(
                        name: displayedProfile.name,
                        summary: displayedProfile.summary,
                        phase: displayedProfile.current_phase,
                        phaseContext: displayedProfile.phase_context
                    )
                } else if !isLoading {
                    // No profile yet - show gentle prompt
                    emptyProfileHero
                }

                // 3. What I Know (THE MAIN CONTENT)
                if let displayedProfile = displayProfile, displayedProfile.has_profile {
                    whatIKnowSection(displayedProfile)
                }

                // 4. Recent Insights (insights still come from server)
                if let serverProfile = profile, !serverProfile.recent_insights.isEmpty {
                    RecentInsightsSection(insights: serverProfile.recent_insights)
                }

                // 5. Coach Configuration Card (compact)
                coachConfigCard

                // 6. Advanced (collapsed)
                AdvancedSection(
                    isExpanded: $showAdvanced,
                    serverStatus: serverStatus,
                    onClearHistory: clearChatHistory,
                    onResetProfile: resetProfile,
                    onExportProfile: exportProfile,
                    onImportProfile: { showImportPicker = true },
                    onRestartOnboarding: restartOnboarding
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Quick Settings Row

    private var quickSettingsRow: some View {
        HStack(spacing: 0) {
            Spacer()

            // Appearance toggle (centered, larger icons)
            HStack(spacing: 4) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.bloom) {
                            appearanceMode = mode.rawValue
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(appearanceMode == mode.rawValue ? Theme.accent : Theme.textMuted)

                            Text(mode.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(appearanceMode == mode.rawValue ? Theme.accent : Theme.textMuted.opacity(0.7))
                        }
                        .frame(width: 56, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(appearanceMode == mode.rawValue ? Theme.accent.opacity(0.15) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: appearanceMode)
                }
            }
            .padding(6)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()
        }
    }

    // MARK: - Empty Profile Hero

    private var emptyProfileHero: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 70, height: 70)
                    .blur(radius: 20)
                    .opacity(0.4)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
            }

            // Main message
            VStack(spacing: 6) {
                Text("I'm still learning about you")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Let's chat! Tap a topic below to get started.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Conversation Seeds - tappable cards that start fun conversations
            VStack(alignment: .leading, spacing: 12) {
                Text("Start a conversation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                // Grid of seed cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(ConversationSeed.initialSeeds.prefix(6)) { seed in
                        SeedCardButton(seed: seed)
                    }
                }
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - What I Know Section

    @ViewBuilder
    private func whatIKnowSection(_ profile: APIClient.ProfileResponse) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("What I Know")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            // Goals - most important
            if !profile.goals.isEmpty {
                ProfileSectionView(
                    title: "What you're working toward",
                    items: profile.goals,
                    category: "goals",
                    onItemUpdated: { old, new in updateItem("goals", old, new) },
                    onItemDeleted: { item in deleteItem("goals", item) }
                )
            }

            // Context - what the AI has learned
            if !profile.context.isEmpty {
                ProfileSectionView(
                    title: "What I've learned",
                    items: profile.context,
                    category: "context",
                    onItemUpdated: { old, new in updateItem("context", old, new) },
                    onItemDeleted: { item in deleteItem("context", item) }
                )
            }

            // Preferences
            if !profile.preferences.isEmpty {
                ProfileSectionView(
                    title: "Your preferences",
                    items: profile.preferences,
                    category: "preferences",
                    onItemUpdated: { old, new in updateItem("preferences", old, new) },
                    onItemDeleted: { item in deleteItem("preferences", item) }
                )
            }

            // Constraints
            if !profile.constraints.isEmpty {
                ProfileSectionView(
                    title: "Things to keep in mind",
                    items: profile.constraints,
                    category: "constraints",
                    onItemUpdated: { old, new in updateItem("constraints", old, new) },
                    onItemDeleted: { item in deleteItem("constraints", item) }
                )
            }

            // Patterns
            if !profile.patterns.isEmpty {
                ProfileSectionView(
                    title: "Patterns I'm noticing",
                    items: profile.patterns,
                    category: "patterns",
                    onItemUpdated: { old, new in updateItem("patterns", old, new) },
                    onItemDeleted: { item in deleteItem("patterns", item) }
                )
            }
        }
    }

    // MARK: - Coach Configuration Card

    private var coachConfigCard: some View {
        Button {
            showCoachConfig = true
        } label: {
            HStack(spacing: 14) {
                // Mode icon
                ZStack {
                    Circle()
                        .fill(modeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: currentMode.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(modeColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 6) {
                        Text(currentMode.displayName)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)

                        // Connection status dot
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 6, height: 6)

                        Text(connectionStatusText)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var modeColor: Color {
        switch currentMode {
        case .claude: return Theme.tertiary
        case .both: return Theme.secondary
        case .gemini: return Theme.accent
        }
    }

    private var connectionStatusColor: Color {
        switch currentMode {
        case .claude:
            return isClaudeReady ? Theme.success : Theme.error
        case .gemini:
            return isGeminiReady ? Theme.success : Theme.error
        case .both:
            return (isClaudeReady && isGeminiReady) ? Theme.success : Theme.warning
        }
    }

    private var connectionStatusText: String {
        if isCheckingConnection {
            return "Checking..."
        }

        switch currentMode {
        case .claude:
            return isClaudeReady ? "Ready" : "Server offline"
        case .gemini:
            return isGeminiReady ? "Ready" : "Setup needed"
        case .both:
            if isClaudeReady && isGeminiReady {
                return "Ready"
            } else if !isClaudeReady && !isGeminiReady {
                return "Setup needed"
            } else {
                return isClaudeReady ? "Gemini setup needed" : "Server offline"
            }
        }
    }

    // MARK: - Actions

    private func loadAll() async {
        isLoading = true
        isCheckingConnection = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProfile() }
            group.addTask { await self.checkConnection() }
            group.addTask { await self.checkGeminiKey() }

            let deadline = Date().addingTimeInterval(5)
            for await _ in group {
                if Date() > deadline { break }
            }
        }

        withAnimation(.easeOut(duration: 0.2)) {
            isLoading = false
            isCheckingConnection = false
        }
    }

    private func loadProfile() async {
        // DEVICE-FIRST: Load LocalProfile immediately (instant, offline-capable)
        await MainActor.run {
            localProfile = LocalProfile.current(in: modelContext)
        }

        // Background sync: fetch server profile for insights and backup
        do {
            profile = try await apiClient.getProfile()
        } catch {
            print("[YouView] Server profile fetch failed (offline?): \(error)")
            // That's OK - LocalProfile is authoritative
        }
    }

    private func checkConnection() async {
        do {
            serverStatus = try await apiClient.getServerStatus()
        } catch {
            serverStatus = nil
        }
    }

    private func checkGeminiKey() async {
        hasGeminiKey = await keychainManager.hasGeminiAPIKey()
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

    private func clearChatHistory() {
        Task {
            do {
                try await apiClient.clearSession()
            } catch {
                print("Failed to clear session: \(error)")
            }
        }
    }

    private func resetProfile() {
        Task {
            do {
                try await apiClient.clearProfile()
                NotificationCenter.default.post(name: .profileReset, object: nil)
            } catch {
                print("Failed to reset profile: \(error)")
            }
        }
    }

    private func restartOnboarding() {
        // Clear onboarding state - will show onboarding on next app launch
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(0, forKey: "onboardingStep")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Gemini Key Management

    private func saveGeminiKey() {
        let key = geminiAPIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        Task {
            do {
                try await keychainManager.setGeminiAPIKey(key)
                geminiAPIKeyInput = ""
                hasGeminiKey = true
                geminiTestResult = nil
                await testGeminiConnection()
            } catch {
                geminiTestResult = (success: false, message: "Failed to save key")
            }
        }
    }

    private func testGeminiConnection() async {
        isTestingGemini = true
        geminiTestResult = nil

        let geminiService = GeminiService()

        do {
            let response = try await geminiService.chat(
                message: "Say 'Connection successful!' and nothing else.",
                history: [],
                systemPrompt: "You are a connection test. Respond only with 'Connection successful!'"
            )

            if response.lowercased().contains("successful") || !response.isEmpty {
                geminiTestResult = (success: true, message: "Connected!")
            }
        } catch {
            geminiTestResult = (success: false, message: error.localizedDescription)
        }

        isTestingGemini = false
    }

    private func removeGeminiKey() {
        Task {
            do {
                try await keychainManager.deleteGeminiAPIKey()
                hasGeminiKey = false
                geminiTestResult = nil
                geminiAPIKeyInput = ""

                if aiProvider == "gemini" {
                    aiProvider = "claude"
                }
            } catch {
                print("Failed to remove Gemini key: \(error)")
            }
        }
    }

    // MARK: - Profile Export/Import

    private func exportProfile() {
        Task {
            do {
                let data = try await apiClient.exportProfile()
                await MainActor.run {
                    exportData = data
                    showExportShare = true
                }
            } catch {
                print("Failed to export profile: \(error)")
            }
        }
    }

    private func handleProfileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Need to access the file with security scope
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access the file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)

                Task {
                    do {
                        let response = try await apiClient.importProfile(data: data)
                        await MainActor.run {
                            if response.success {
                                showImportSuccess = true
                                Task { await loadProfile() }
                            } else {
                                importError = response.error ?? "Import failed"
                            }
                        }
                    } catch {
                        await MainActor.run {
                            importError = error.localizedDescription
                        }
                    }
                }
            } catch {
                importError = "Could not read file: \(error.localizedDescription)"
            }

        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

// MARK: - Profile Export Share Sheet

struct ProfileExportShareSheet: UIViewControllerRepresentable {
    let data: Data

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file with the profile data
        let fileName = "AirFit-Profile-\(formattedDate).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Gemini Setup Sheet

struct GeminiSetupSheet: View {
    @Binding var apiKeyInput: String
    let hasGeminiKey: Bool
    let isTestingGemini: Bool
    let testResult: (success: Bool, message: String)?
    let onSave: () -> Void
    let onTest: () async -> Void
    let onRemove: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image("GeminiLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)

                        Text("Gemini API Key")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.top, 20)

                    if hasGeminiKey {
                        // Key is configured
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(Theme.success)
                                Text("API key configured")
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.success)
                            }
                            .padding(16)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Test result
                            if let result = testResult {
                                HStack(spacing: 8) {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(result.success ? Theme.success : Theme.error)
                                    Text(result.message)
                                        .font(.caption)
                                        .foregroundStyle(result.success ? Theme.success : Theme.error)
                                    Spacer()
                                }
                            }

                            // Test button
                            Button {
                                Task { await onTest() }
                            } label: {
                                HStack {
                                    if isTestingGemini {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "bolt.horizontal.fill")
                                            .font(.caption)
                                    }
                                    Text(isTestingGemini ? "Testing..." : "Test Connection")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isTestingGemini)

                            // Remove button
                            Button(action: onRemove) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                    Text("Remove API Key")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(Theme.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.error.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        // No key - show input
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Enter your Gemini API key to enable direct AI access without a server.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)

                            SecureField("Paste your API key", text: $apiKeyInput)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
                                )

                            Button(action: onSave) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .font(.caption)
                                    Text("Save API Key")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(apiKeyInput.isEmpty ? Theme.textMuted : Theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(apiKeyInput.isEmpty)

                            // Get API key link
                            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                    Text("Get free API key from Google AI Studio")
                                        .font(.caption)
                                }
                                .foregroundStyle(Theme.accent)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Gemini Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - AI Mode Enum

enum AIMode: String, CaseIterable {
    case claude = "claude"
    case both = "both"
    case gemini = "gemini"

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .both: return "Hybrid"
        case .gemini: return "Gemini"
        }
    }

    var description: String {
        switch self {
        case .claude: return "Maximum privacy, requires server"
        case .both: return "Private chat, Gemini for photos"
        case .gemini: return "Full features, easiest setup"
        }
    }

    var detailedDescription: String {
        switch self {
        case .claude:
            return "All conversations stay on your personal server. Complete privacy—nothing leaves your network. Requires a running server with Claude CLI configured."
        case .both:
            return "Text conversations route through your private server (Claude). Photo features like food logging use Gemini's vision API. Best balance of privacy and functionality."
        case .gemini:
            return "Everything goes through Google's Gemini API. Full features including photo analysis. Free tier uses your data to improve their models. No server required."
        }
    }

    var icon: String {
        switch self {
        case .claude: return "lock.shield.fill"
        case .both: return "arrow.triangle.branch"
        case .gemini: return "sparkles"
        }
    }
}

// MARK: - Thinking Level Control

/// Segmented picker for Gemini thinking/reasoning depth.
struct ThinkingLevelControl: View {
    @Binding var selectedLevel: ThinkingLevel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Thinking")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Menu {
                    Text("Controls how deeply Gemini reasons about your questions.")
                    Text("")
                    Text("• Fast: Quick responses for simple queries")
                    Text("• Balanced: Good for everyday conversations")
                    Text("• Deep: Thorough analysis for complex questions")
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Picker("Thinking Level", selection: $selectedLevel) {
                ForEach(ThinkingLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedLevel.description)
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .sensoryFeedback(.selection, trigger: selectedLevel)
    }
}

// MARK: - Seed Card Button

/// A tappable card that starts a conversation with a specific seed.
/// Navigates to the Coach tab and initiates a warm, lighthearted conversation.
struct SeedCardButton: View {
    let seed: ConversationSeed
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            startSeedConversation()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: seed.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.accent)

                VStack(spacing: 2) {
                    Text(seed.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text(seed.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(SeedCardButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: seed.id)
    }

    private func startSeedConversation() {
        // Post notification with the selected seed
        NotificationCenter.default.post(
            name: .conversationSeedSelected,
            object: nil,
            userInfo: ["seed": seed]
        )

        // Switch to Coach tab using existing notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .openCoachTab, object: nil)
        }
    }
}

/// Custom button style for seed cards with nice press feedback
struct SeedCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        YouView()
    }
}
