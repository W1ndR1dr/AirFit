import SwiftUI

struct InitialAPISetupView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var selectedProvider: AIProvider = .gemini
    @State private var selectedModel: String = ""
    @State private var apiKey: String = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showingInfo = false
    @State private var showKey = false
    @State private var validationRetryCount = 0

    let onCompletion: () -> Void

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, AppSpacing.xl)

                    CascadeText("Welcome to AirFit")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("To use AI features, you'll need an API key")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, AppSpacing.xl)

                // Provider Selection
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Select AI Provider")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        ProviderOption(
                            provider: provider,
                            isSelected: selectedProvider == provider,
                            onTap: {
                                HapticService.impact(.light)
                                selectedProvider = provider
                                selectedModel = provider.defaultModel // Set default model for provider
                                apiKey = "" // Clear key when switching providers
                                validationError = nil // Clear any previous errors
                                validationRetryCount = 0 // Reset retry count
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)

                // API Key Input
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("API Key")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Button {
                            HapticService.impact(.light)
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }

                    GlassCard {
                        HStack {
                            if showKey {
                                TextField("Enter your \(selectedProvider.displayName) API key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                                    .disabled(isValidating)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Enter your \(selectedProvider.displayName) API key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                                    .disabled(isValidating)
                            }

                            Button {
                                HapticService.impact(.light)
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(AppSpacing.md)
                    }

                    if let error = validationError {
                        Text(error)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                // Model Selection
                if !apiKey.isEmpty {
                    ModelRecommendationView(
                        provider: selectedProvider,
                        selectedModel: $selectedModel
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: !apiKey.isEmpty)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: AppSpacing.md) {
                    Button {
                        HapticService.impact(.medium)
                        validateAndSave()
                    } label: {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Text(isValidating ? "Validating Key..." : "Configure AI")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: !apiKey.isEmpty && !isValidating
                                    ? [Color.accentColor, Color.accentColor.opacity(0.8)]
                                    : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(
                            color: !apiKey.isEmpty && !isValidating ? Color.accentColor.opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                    }
                    .disabled(apiKey.isEmpty || isValidating)

                    Text("An API key is required to use AirFit")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticService.impact(.light)
                        skipAndUseDemoMode()
                    } label: {
                        Text("Skip & Use Demo Mode")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .underline()
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .sheet(isPresented: $showingInfo) {
            APIKeyInfoSheet(provider: selectedProvider)
        }
        .preferredColorScheme(.light) // Force light mode for better visibility
        .onAppear {
            // Initialize default model if not set
            if selectedModel.isEmpty {
                selectedModel = selectedProvider.defaultModel
            }
        }
    }

    private func validateAndSave() {
        isValidating = true
        validationError = nil

        Task {
            // Check if model is selected
            if selectedModel.isEmpty {
                selectedModel = selectedProvider.defaultModel
            }
            
            do {
                // Get API key manager from DI
                let apiKeyManager = try await diContainer.resolve(APIKeyManagementProtocol.self)

                // Validate format first
                guard isValidAPIKeyFormat(apiKey, for: selectedProvider) else {
                    await MainActor.run {
                        validationError = "Invalid API key format"
                        isValidating = false
                    }
                    return
                }

                // Validate with actual API call (with retry logic)
                let config = LLMProviderConfig(apiKey: apiKey)
                var isValid = false
                var lastError: Error?
                
                // Retry up to 3 times for network failures
                for attempt in 1...3 {
                    do {
                        switch selectedProvider {
                        case .anthropic:
                            let provider = AnthropicProvider(config: config)
                            isValid = try await provider.validateAPIKey(apiKey)
                        case .openAI:
                            let provider = OpenAIProvider(config: config)
                            isValid = try await provider.validateAPIKey(apiKey)
                        case .gemini:
                            let provider = GeminiProvider(config: config)
                            isValid = try await provider.validateAPIKey(apiKey)
                        }
                        
                        if isValid {
                            break // Success, exit retry loop
                        }
                    } catch {
                        lastError = error
                        
                        // Only retry for network errors
                        if error.localizedDescription.lowercased().contains("network") ||
                           error.localizedDescription.lowercased().contains("timeout") ||
                           error.localizedDescription.lowercased().contains("connection") {
                            if attempt < 3 {
                                await MainActor.run {
                                    validationError = "Network error - retrying... (attempt \(attempt)/3)"
                                }
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                                continue
                            }
                        } else {
                            // Non-network error, don't retry
                            throw error
                        }
                    }
                }
                
                guard isValid else {
                    await MainActor.run {
                        if let error = lastError {
                            let errorMessage: String
                            if error.localizedDescription.lowercased().contains("unauthorized") || 
                               error.localizedDescription.lowercased().contains("401") {
                                errorMessage = "Invalid API key - authentication failed"
                            } else if error.localizedDescription.lowercased().contains("network") {
                                errorMessage = "Network error - please check your connection and try again"
                            } else {
                                errorMessage = "Invalid API key - please check your key and try again"
                            }
                            validationError = errorMessage
                        } else {
                            validationError = "Invalid API key - please check your key and try again"
                        }
                        isValidating = false
                    }
                    return
                }

                // Save the validated key
                try await apiKeyManager.saveAPIKey(apiKey, for: selectedProvider)
                
                // Save the selected model to UserDefaults
                UserDefaults.standard.set(selectedModel, forKey: "selected_model_\(selectedProvider.rawValue)")
                UserDefaults.standard.set(selectedProvider.rawValue, forKey: "default_ai_provider")
                UserDefaults.standard.set(selectedModel, forKey: "default_ai_model")

                // Configure AI service
                let aiService = try await diContainer.resolve(AIServiceProtocol.self)
                try await aiService.configure()

                // Success
                await MainActor.run {
                    HapticService.notification(.success)
                    onCompletion()
                }
            } catch {
                await MainActor.run {
                    let errorMessage: String
                    if error.localizedDescription.lowercased().contains("unauthorized") || 
                       error.localizedDescription.lowercased().contains("401") {
                        errorMessage = "Invalid API key - authentication failed"
                    } else if error.localizedDescription.lowercased().contains("network") {
                        errorMessage = "Network error - please check your connection"
                    } else {
                        errorMessage = "Validation failed: \(error.localizedDescription)"
                    }
                    validationError = errorMessage
                    HapticService.notification(.error)
                    isValidating = false
                }
            }
        }
    }

    private func isValidAPIKeyFormat(_ key: String, for provider: AIProvider) -> Bool {
        switch provider {
        case .anthropic:
            return key.hasPrefix("sk-ant-") && key.count > 40
        case .openAI:
            return key.hasPrefix("sk-") && key.count > 40
        case .gemini:
            return key.count > 30 // Gemini keys are less structured
        }
    }

    private func skipAndUseDemoMode() {
        // Enable demo mode
        AppConstants.Configuration.isUsingDemoMode = true
        AppLogger.info("Demo mode enabled from initial setup", category: .app)

        // Complete setup
        HapticService.notification(.success)
        onCompletion()
    }
}

// MARK: - Supporting Views

private struct ProviderOption: View {
    let provider: AIProvider
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(providerDescription)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
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
            }
            .padding(AppSpacing.md)
            .background(
                GlassCard {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
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
    }

    private var providerDescription: String {
        switch provider {
        case .anthropic:
            return "Claude - Best for conversational AI"
        case .openAI:
            return "GPT-4 - Versatile and powerful"
        case .gemini:
            return "Gemini 2.5 Flash - Fast & free tier available"
        }
    }
}

private struct APIKeyInfoSheet: View {
    let provider: AIProvider
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            BaseScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        CascadeText("How to get your API key")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top)

                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                ForEach(instructions, id: \.self) { instruction in
                                    HStack(alignment: .top, spacing: AppSpacing.md) {
                                        Text("•")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        Text(instruction)
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                        }

                        Link(destination: providerURL) {
                            HStack {
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Get API Key")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(AppSpacing.md)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("\(provider.displayName) API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticService.impact(.light)
                        dismiss()
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var instructions: [String] {
        switch provider {
        case .anthropic:
            return [
                "Visit console.anthropic.com",
                "Sign in or create an account",
                "Navigate to API Keys section",
                "Click 'Create Key'",
                "Copy the key (starts with sk-ant-)",
                "Keep it secure - you won't see it again!"
            ]
        case .openAI:
            return [
                "Visit platform.openai.com",
                "Sign in or create an account",
                "Go to API Keys in your account",
                "Click 'Create new secret key'",
                "Copy the key (starts with sk-)",
                "Save it securely"
            ]
        case .gemini:
            return [
                "Visit makersuite.google.com",
                "Sign in with your Google account",
                "Click 'Get API Key'",
                "Create a new project if needed",
                "Copy your API key",
                "Keep it private"
            ]
        }
    }

    private var providerURL: URL {
        switch provider {
        case .anthropic:
            return URL(string: "https://console.anthropic.com/account/keys")!
        case .openAI:
            return URL(string: "https://platform.openai.com/api-keys")!
        case .gemini:
            return URL(string: "https://makersuite.google.com/app/apikey")!
        }
    }
}

// MARK: - Preview

#Preview {
    InitialAPISetupView {
        print("Setup completed")
    }
}
