import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Server state
    @State private var serverStatus: ServerInfo?
    @State private var isLoadingSettings = true
    @State private var showServerSetup = false

    // Confirmation dialogs
    @State private var showClearChatConfirm = false
    @State private var showClearProfileConfirm = false
    @State private var showClearGeminiKeyConfirm = false

    // Appearance
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    // AI Provider
    @AppStorage("aiProvider") private var aiProvider = "claude"
    @AppStorage("hasAcceptedGeminiTerms") private var hasAcceptedGeminiTerms = false
    @State private var showGeminiDisclosure = false
    @State private var geminiAPIKey = ""
    @State private var hasGeminiKey = false
    @State private var isTestingGemini = false
    @State private var geminiTestResult: GeminiTestResult?

    // Gemini Privacy Controls
    @AppStorage("geminiShareNutrition") private var geminiShareNutrition = true
    @AppStorage("geminiShareWorkouts") private var geminiShareWorkouts = true
    @AppStorage("geminiShareHealth") private var geminiShareHealth = false
    @AppStorage("geminiShareProfile") private var geminiShareProfile = false
    @AppStorage("geminiParanoidMode") private var geminiParanoidMode = false
    @State private var showPrivacyDetail: PrivacyCategory?

    // Tracking Features
    @AppStorage("waterTrackingEnabled") private var waterTrackingEnabled = false

    // Speech Recognition
    @AppStorage("speechRecognitionEnabled") private var speechRecognitionEnabled = true
    @State private var modelManager = ModelManager.shared
    @State private var showDeleteModelsConfirm = false
    @State private var pendingSpeechDisable = false

    private let apiClient = APIClient()
    private let keychainManager = KeychainManager.shared

    enum GeminiTestResult {
        case success
        case failure(String)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Provider Selection (moved to top)
                SettingsSection(title: "AI Provider") {
                    // Bubble-style provider selector
                    HStack(spacing: 12) {
                        ProviderBubble(
                            title: "Claude",
                            subtitle: "Private",
                            logoImage: "ClaudeLogo",
                            iconColor: Color(red: 0.85, green: 0.55, blue: 0.35),  // Claude orange
                            isSelected: aiProvider == "claude"
                        ) {
                            withAnimation(.airfit) { aiProvider = "claude" }
                        }

                        ProviderBubble(
                            title: "Gemini",
                            subtitle: "Free",
                            logoImage: "GeminiLogo",
                            iconColor: .blue,
                            isSelected: aiProvider == "gemini"
                        ) {
                            if hasAcceptedGeminiTerms {
                                withAnimation(.airfit) { aiProvider = "gemini" }
                            } else {
                                showGeminiDisclosure = true
                            }
                        }
                    }

                    // Provider description
                    if aiProvider == "gemini" {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Theme.accent)
                                .font(.caption)
                            Text("Direct calls to Google. Free tier uses your data to improve models.")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Theme.success)
                                .font(.caption)
                            Text("Runs through your server. Conversations stay completely private.")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Gemini API Key (only shown when Gemini selected or key exists)
                if aiProvider == "gemini" || hasGeminiKey {
                    SettingsSection(title: "Gemini API Key") {
                        if hasGeminiKey {
                            // Key is set
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

                            // Test connection button
                            Button {
                                Task { await testGeminiConnection() }
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(AirFitButtonStyle())
                            .disabled(isTestingGemini)

                            // Test result
                            if let result = geminiTestResult {
                                HStack(spacing: 8) {
                                    switch result {
                                    case .success:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.success)
                                        Text("Connection successful!")
                                            .font(.caption)
                                            .foregroundStyle(Theme.success)
                                    case .failure(let error):
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Theme.error)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(Theme.error)
                                    }
                                }
                            }

                            // Remove key button
                            Button {
                                showClearGeminiKeyConfirm = true
                            } label: {
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(AirFitButtonStyle())

                        } else {
                            // No key - show input
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Paste your API key", text: $geminiAPIKey)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Theme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
                                    )

                                Button {
                                    Task { await saveGeminiAPIKey() }
                                } label: {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .font(.caption)
                                        Text("Save API Key")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(geminiAPIKey.isEmpty ? Theme.textMuted : Theme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(AirFitButtonStyle())
                                .disabled(geminiAPIKey.isEmpty)
                            }

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
                }

                // Gemini Privacy Controls (only shown when Gemini selected)
                if aiProvider == "gemini" {
                    SettingsSection(title: "Privacy Controls") {
                        // Paranoid mode toggle
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundStyle(.purple)
                                            .font(.subheadline)
                                        Text("Claude Only Mode")
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                    Text("Route everything through your server")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textMuted)
                                }
                                Spacer()
                                Toggle("", isOn: $geminiParanoidMode)
                                    .labelsHidden()
                                    .tint(.purple)
                            }

                            if geminiParanoidMode {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundStyle(.purple)
                                        .font(.caption)
                                    Text("Maximum privacy. All requests go to Claude via your server. Gemini is disabled until you turn this off.")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .padding(12)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        if !geminiParanoidMode {
                            Divider()
                                .background(Theme.textMuted.opacity(0.2))

                            Text("What can Gemini access?")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Nutrition toggle
                            PrivacyToggleRow(
                                title: "Nutrition Data",
                                subtitle: "Foods, calories, macros",
                                risk: .low,
                                isOn: $geminiShareNutrition,
                                onInfoTap: { showPrivacyDetail = .nutrition }
                            )

                            // Workouts toggle
                            PrivacyToggleRow(
                                title: "Workout Data",
                                subtitle: "Exercises, PRs, volume",
                                risk: .low,
                                isOn: $geminiShareWorkouts,
                                onInfoTap: { showPrivacyDetail = .workouts }
                            )

                            // Health toggle
                            PrivacyToggleRow(
                                title: "Health Metrics",
                                subtitle: "Weight, sleep, heart rate",
                                risk: .medium,
                                isOn: $geminiShareHealth,
                                onInfoTap: { showPrivacyDetail = .health }
                            )

                            // Profile toggle
                            PrivacyToggleRow(
                                title: "Personal Profile",
                                subtitle: "Name, goals, memories",
                                risk: .high,
                                isOn: $geminiShareProfile,
                                onInfoTap: { showPrivacyDetail = .profile }
                            )

                            Divider()
                                .background(Theme.textMuted.opacity(0.2))

                            // Explanation of hybrid routing
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(Theme.accent)
                                    .font(.caption)
                                Text("Disabled categories route to Claude automatically. Your server handles the sensitive stuff; Gemini handles the rest.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                }

                // Server Configuration (only shown when Claude selected)
                if aiProvider == "claude" {
                    SettingsSection(title: "Server") {
                        // Current URL
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                            Text(ServerConfiguration.shared.isConfigured
                                 ? ServerConfiguration.shared.currentURL
                                 : "Not configured")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.textMuted)
                                .lineLimit(1)
                        }

                        // Connection status
                        HStack {
                            Text("Status")
                                .font(.body)
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
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.success)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Theme.error)
                                        .frame(width: 8, height: 8)
                                    Text("Disconnected")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.error)
                                }
                            }
                        }

                        // Change server button
                        Button {
                            showServerSetup = true
                        } label: {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.caption)
                                Text("Change Server")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(AirFitButtonStyle())

                        // Server providers (if connected)
                        if let status = serverStatus {
                            Divider()
                                .background(Theme.textMuted.opacity(0.2))

                            HStack {
                                Text("Active Provider")
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(status.activeProvider.capitalized)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.accent)
                            }

                            // Session info
                            if let sessionId = status.sessionId {
                                HStack {
                                    Text("Session")
                                        .font(.body)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(String(sessionId.prefix(8)) + "...")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }

                            if let messageCount = status.messageCount, messageCount > 0 {
                                Button {
                                    showClearChatConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                        Text("Clear Chat History (\(messageCount) messages)")
                                            .font(.subheadline.weight(.medium))
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
                }

                // Appearance
                SettingsSection(title: "Appearance") {
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Tracking Features
                SettingsSection(title: "Tracking") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(.blue)
                                    .font(.subheadline)
                                Text("Water Tracking")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Text("Log daily water intake on the Nutrition tab")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $waterTrackingEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                }

                // Speech Recognition
                SettingsSection(title: "Speech") {
                    // Enable/Disable Toggle
                    Toggle(isOn: Binding(
                        get: { speechRecognitionEnabled },
                        set: { newValue in
                            if newValue {
                                // Enabling - just turn it on
                                speechRecognitionEnabled = true
                            } else {
                                // Disabling - check if models are installed
                                if modelManager.hasInstalledModels {
                                    pendingSpeechDisable = true
                                    showDeleteModelsConfirm = true
                                } else {
                                    speechRecognitionEnabled = false
                                }
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: "waveform")
                                .font(.body)
                                .foregroundStyle(speechRecognitionEnabled ? Theme.accent : Theme.textMuted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Speech Recognition")
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Voice input for chat messages")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                    .tint(Theme.accent)

                    // Model settings link (only when enabled)
                    if speechRecognitionEnabled {
                        NavigationLink {
                            SpeechSettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.body)
                                    .foregroundStyle(Theme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice Models")
                                        .font(.body)
                                        .foregroundStyle(Theme.textPrimary)
                                    if modelManager.installedModels.isEmpty {
                                        Text("Download required for voice input")
                                            .font(.caption)
                                            .foregroundStyle(Theme.warning)
                                    } else {
                                        Text("\(modelManager.installedModels.count) model\(modelManager.installedModels.count == 1 ? "" : "s") ready")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textMuted)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Coaching Persona
                SettingsSection(title: "Coaching") {
                    NavigationLink {
                        CoachingPersonaView()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.body)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Coaching Persona")
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("View and customize how your AI coach interacts with you")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Permissions (moved lower)
                SettingsSection(title: "Permissions") {
                    Button {
                        openHealthSettings()
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.body)
                                .foregroundStyle(.red)
                            Text("Health Data Access")
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("More health data = better coaching insights.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                // App Info Section
                SettingsSection(title: "About") {
                    HStack {
                        Text("Version")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }

                    HStack {
                        Text("Build")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                // Danger Zone
                SettingsSection(title: "Danger Zone") {
                    Button {
                        showClearProfileConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("Clear All Profile Data")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(Theme.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(AirFitButtonStyle())

                    Text("This will erase everything the AI has learned about you.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(
            // Settings needs its own aurora since it's pushed onto the nav stack
            BreathingMeshBackground(scrollProgress: 4.0)  // Use profile/settings palette
                .ignoresSafeArea()
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
        .confirmationDialog(
            "Clear all learned data?",
            isPresented: $showClearProfileConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Everything", role: .destructive) {
                Task { await clearProfile() }
            }
        } message: {
            Text("The AI will start fresh and learn about you again through conversation.")
        }
        .task {
            await loadStatus()
            await loadGeminiKeyStatus()
            await modelManager.load()
        }
        .refreshable {
            await loadStatus()
            await loadGeminiKeyStatus()
            await modelManager.load()
        }
        .confirmationDialog(
            "Remove Gemini API key?",
            isPresented: $showClearGeminiKeyConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Key", role: .destructive) {
                Task { await removeGeminiAPIKey() }
            }
        } message: {
            Text("You'll need to enter a new key to use Gemini again.")
        }
        .confirmationDialog(
            "Delete Voice Models?",
            isPresented: $showDeleteModelsConfirm,
            titleVisibility: .visible
        ) {
            Button("Disable & Delete Models", role: .destructive) {
                Task {
                    await modelManager.deleteAllModels()
                    speechRecognitionEnabled = false
                    pendingSpeechDisable = false
                }
            }
            Button("Disable & Keep Models") {
                speechRecognitionEnabled = false
                pendingSpeechDisable = false
            }
            Button("Cancel", role: .cancel) {
                pendingSpeechDisable = false
            }
        } message: {
            Text("You have \(modelManager.installedModels.count) model\(modelManager.installedModels.count == 1 ? "" : "s") installed. Delete them to free up storage?")
        }
        .sheet(isPresented: $showServerSetup) {
            NavigationStack {
                ServerSetupView(
                    onComplete: {
                        showServerSetup = false
                        Task { await loadStatus() }
                    },
                    onSkip: {
                        showServerSetup = false
                    }
                )
                .navigationTitle("Server Configuration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showServerSetup = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showGeminiDisclosure) {
            GeminiPrivacyDisclosureSheet(
                onAccept: {
                    hasAcceptedGeminiTerms = true
                    withAnimation(.airfit) { aiProvider = "gemini" }
                    showGeminiDisclosure = false
                },
                onDecline: {
                    showGeminiDisclosure = false
                }
            )
        }
        .sheet(item: $showPrivacyDetail) { category in
            PrivacyDetailSheet(category: category)
                .presentationBackground(Theme.surface)
        }
    }

    // MARK: - Actions

    private func openHealthSettings() {
        // Open the Health app's Sources tab where users can manage AirFit's permissions
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }

    private func loadStatus() async {
        isLoadingSettings = true
        do {
            serverStatus = try await apiClient.getServerStatus()
        } catch {
            serverStatus = nil
        }
        withAnimation(.easeOut(duration: 0.2)) {
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

    private func clearProfile() async {
        do {
            try await apiClient.clearProfile()
            NotificationCenter.default.post(name: .profileReset, object: nil)
            dismiss()
        } catch {
            print("Failed to clear profile: \(error)")
        }
    }

    // MARK: - Gemini API Key Management

    private func loadGeminiKeyStatus() async {
        hasGeminiKey = await keychainManager.hasGeminiAPIKey()
    }

    private func saveGeminiAPIKey() async {
        let key = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        do {
            try await keychainManager.setGeminiAPIKey(key)
            geminiAPIKey = ""  // Clear the input
            hasGeminiKey = true
            geminiTestResult = nil

            // Auto-test the connection
            await testGeminiConnection()
        } catch {
            geminiTestResult = .failure("Failed to save key: \(error.localizedDescription)")
        }
    }

    private func removeGeminiAPIKey() async {
        do {
            try await keychainManager.deleteGeminiAPIKey()
            hasGeminiKey = false
            geminiTestResult = nil

            // Switch back to Claude if Gemini was selected
            if aiProvider == "gemini" {
                aiProvider = "claude"
            }
        } catch {
            print("Failed to remove Gemini key: \(error)")
        }
    }

    private func testGeminiConnection() async {
        isTestingGemini = true
        geminiTestResult = nil

        let geminiService = GeminiService()

        do {
            // Simple test message
            let response = try await geminiService.chat(
                message: "Say 'Connection successful!' and nothing else.",
                history: [],
                systemPrompt: "You are a connection test. Respond only with 'Connection successful!'"
            )

            if response.lowercased().contains("successful") {
                geminiTestResult = .success
            } else {
                geminiTestResult = .success  // Any response is a success
            }
        } catch {
            geminiTestResult = .failure(error.localizedDescription)
        }

        isTestingGemini = false
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

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

// MARK: - Provider Bubble

/// A tappable bubble for selecting AI provider
struct ProviderBubble: View {
    let title: String
    let subtitle: String
    var icon: String? = nil  // SF Symbol name (optional)
    var logoImage: String? = nil  // Asset catalog image name (optional)
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? iconColor.opacity(0.2) : Theme.surface)
                        .frame(width: 48, height: 48)

                    if let logoImage = logoImage {
                        Image(logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .opacity(isSelected ? 1.0 : 0.5)
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(isSelected ? iconColor : Theme.textMuted)
                    }
                }

                // Title
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)

                // Subtitle
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? iconColor : Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? iconColor.opacity(0.1) : Theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? iconColor : Theme.textMuted.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Gemini Privacy Disclosure Sheet

/// Comprehensive privacy disclosure shown when user first selects Gemini
struct GeminiPrivacyDisclosureSheet: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image("GeminiLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                        Text("Using Gemini")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // What data goes to Google
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What's sent to Google", systemImage: "arrow.up.doc.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        DisclosureBullet(text: "Chat messages and conversation history")
                        DisclosureBullet(text: "Food descriptions for nutrition parsing")
                        DisclosureBullet(text: "Health context (steps, weight, sleep, etc.)")
                        DisclosureBullet(text: "Food photos for analysis")
                    }
                    .padding(16)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Privacy tradeoff
                    VStack(alignment: .leading, spacing: 12) {
                        Label("The tradeoff", systemImage: "scale.3d")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Google's free tier uses your conversations to improve their AI models. This is the \"data-as-payment\" model.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)

                        Text("For complete privacy, use Claude mode with your own server.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(16)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What you get", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.success)

                        DisclosureBullet(text: "Works without your server running", color: Theme.success)
                        DisclosureBullet(text: "Fast responses via Google infrastructure", color: Theme.success)
                        DisclosureBullet(text: "1,500 free requests per day", color: Theme.success)
                        DisclosureBullet(text: "Food photo analysis", color: Theme.success)
                    }
                    .padding(16)
                    .background(Theme.success.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 20)
                }
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Privacy Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDecline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("I Understand") { onAccept() }
                        .bold()
                }
            }
        }
    }
}

/// A bullet point for the disclosure sheet
private struct DisclosureBullet: View {
    let text: String
    var color: Color = Theme.textSecondary

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(color)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Privacy Controls

enum PrivacyRisk {
    case low, medium, high

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var label: String {
        switch self {
        case .low: return "Low risk"
        case .medium: return "Medium"
        case .high: return "Sensitive"
        }
    }
}

enum PrivacyCategory: Identifiable {
    case nutrition, workouts, health, profile

    var id: String {
        switch self {
        case .nutrition: return "nutrition"
        case .workouts: return "workouts"
        case .health: return "health"
        case .profile: return "profile"
        }
    }

    var title: String {
        switch self {
        case .nutrition: return "Nutrition Data"
        case .workouts: return "Workout Data"
        case .health: return "Health Metrics"
        case .profile: return "Personal Profile"
        }
    }

    var icon: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .workouts: return "dumbbell.fill"
        case .health: return "heart.fill"
        case .profile: return "person.fill"
        }
    }

    var risk: PrivacyRisk {
        switch self {
        case .nutrition, .workouts: return .low
        case .health: return .medium
        case .profile: return .high
        }
    }

    var explanation: String {
        switch self {
        case .nutrition:
            return """
            What you eat, minus the existential judgment. Calories, macros, food names—anonymized fuel metrics.

            Google can't identify you from "3 eggs and avocado toast" any more than a gas station knows who filled up at pump 7.

            This data helps Gemini parse your food logs faster and understand your dietary patterns for better coaching. It's the least personal category—unless your meal choices are genuinely that distinctive.

            Risk: Minimal. Millions of people eat the same things. You're a statistical blip in the breakfast data.
            """

        case .workouts:
            return """
            Your lift PRs, exercise selection, and training volume. The quantified evidence of your gym life.

            Unless you're secretly training for Olympic gold under a pseudonym, this data has the identifying power of a gym locker number. "Benched 185 for 8" describes roughly 40% of gym-going males at any given moment.

            Sharing this lets Gemini give smarter training advice and track your progression. Volume trends, weak points, exercise selection—all useful coaching inputs.

            Risk: Low. You're one of millions of people who also did leg day this week.
            """

        case .health:
            return """
            Weight, body fat percentage, sleep hours, resting heart rate, HRV—the quantified self's autobiography.

            Still fairly anonymous in isolation (lots of people weigh 180lbs), but the pattern becomes more personal over time. Your sleep architecture + weight trend + HRV signature starts to paint a picture.

            This data makes coaching significantly better. Understanding your recovery state, sleep quality, and body composition trends lets the AI actually coach instead of guess.

            Risk: Medium. Share if better coaching > theoretical privacy risk. The tradeoff is real but manageable.
            """

        case .profile:
            return """
            Your name, fitness goals, communication preferences, and the memories Coach has formed about you. This is the "you" part of the data.

            This includes things like: "Prefers direct feedback," "Working toward specific body fat goal," "Responds well to data-driven reasoning."

            Disabled by default because, well, it's literally your identity attached to your habits. Claude keeps this locked in your server's vault.

            Risk: High. This is genuinely personal. Only enable if you're comfortable with Google knowing who's behind the data.
            """
        }
    }
}

struct PrivacyToggleRow: View {
    let title: String
    let subtitle: String
    let risk: PrivacyRisk
    let isOn: Binding<Bool>
    let onInfoTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)

                    // Risk badge
                    Text(risk.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(risk.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(risk.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            // Info button
            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(Theme.textMuted.opacity(0.6))
            }
            .buttonStyle(.plain)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(risk.color)
        }
    }
}

struct PrivacyDetailSheet: View {
    let category: PrivacyCategory

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.risk.color.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: category.icon)
                        .font(.title)
                        .foregroundStyle(category.risk.color)
                }

                Text(category.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                // Risk badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(category.risk.color)
                        .frame(width: 8, height: 8)
                    Text(category.risk.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(category.risk.color)
                }
            }

            // Explanation
            Text(category.explanation)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Gemini Disclosure") {
    GeminiPrivacyDisclosureSheet(
        onAccept: {},
        onDecline: {}
    )
}
