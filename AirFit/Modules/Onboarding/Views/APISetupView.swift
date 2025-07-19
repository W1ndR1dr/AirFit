import SwiftUI

struct APISetupView: View {
    @StateObject private var viewModel: APISetupViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var diContainer
    @State private var selectedProvider: AIProvider = .anthropic
    @State private var isSaving = false
    @State private var saveError: Error?
    private let onComplete: (() -> Void)?

    init(apiKeyManager: APIKeyManagementProtocol? = nil, onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
        if let manager = apiKeyManager {
            _viewModel = StateObject(wrappedValue: APISetupViewModel(apiKeyManager: manager))
        } else {
            // For preview - create a mock
            let mockManager = MockAPIKeyManager()
            _viewModel = StateObject(wrappedValue: APISetupViewModel(apiKeyManager: mockManager))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.90, blue: 1.0),
                        Color(red: 0.85, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple.gradient)

                            Text("Power Your AI Coach")
                                .font(.system(size: 28, weight: .bold, design: .rounded))

                            Text("Add API keys to unlock AI-powered coaching")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Provider selection
                        ProviderSelector(selectedProvider: $selectedProvider)
                            .padding(.horizontal)

                        // API Key input for selected provider
                        APIKeyInputCard(
                            provider: selectedProvider,
                            viewModel: viewModel
                        )
                        .padding(.horizontal)

                        // Configured providers list
                        if !viewModel.configuredProviders.isEmpty {
                            ConfiguredProvidersList(viewModel: viewModel)
                                .padding(.horizontal)

                            // Active provider selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Active Provider")
                                    .font(.headline)
                                    .padding(.horizontal)

                                Text("Choose which AI model to use for your coaching experience:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)

                                ForEach(viewModel.configuredProviders, id: \.provider) { config in
                                    Button(action: {
                                        viewModel.selectedActiveProvider = config
                                    }) {
                                        HStack {
                                            Image(systemName: config.provider == .anthropic ? "a.circle.fill" :
                                                    config.provider == .openAI ? "o.circle.fill" : "g.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(config.provider == .anthropic ? .purple :
                                                                    config.provider == .openAI ? .green : .orange)

                                            VStack(alignment: .leading) {
                                                Text(config.provider.displayName)
                                                    .font(.headline)
                                                Text(config.model)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            if viewModel.selectedActiveProvider?.provider == config.provider {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(viewModel.selectedActiveProvider?.provider == config.provider ?
                                                            Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(viewModel.selectedActiveProvider?.provider == config.provider ?
                                                                Color.blue.opacity(0.05) : Color.clear)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }

                        // Continue button
                        if !viewModel.configuredProviders.isEmpty && viewModel.selectedActiveProvider != nil {
                            Button(action: {
                                isSaving = true
                                saveError = nil
                                
                                Task {
                                    do {
                                        try await viewModel.saveAndContinue()
                                        await MainActor.run {
                                            if let onComplete = onComplete {
                                                onComplete()
                                            } else {
                                                dismiss()
                                            }
                                        }
                                    } catch {
                                        await MainActor.run {
                                            saveError = error
                                            isSaving = false
                                        }
                                    }
                                }
                            }) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Label("Continue to Onboarding", systemImage: "arrow.right.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.purple.gradient)
                            )
                            .disabled(isSaving)
                            .padding(.horizontal)
                        } else if !viewModel.configuredProviders.isEmpty {
                            // Show disabled state when no provider selected
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                Text("Please select an active AI provider to continue")
                            }
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(saveError != nil), presenting: saveError) { _ in
            Button("OK") {
                saveError = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

struct ProviderSelector: View {
    @Binding var selectedProvider: AIProvider

    let providers: [(AIProvider, String, String)] = [
        (.anthropic, "Anthropic", "Claude 4 Series"),
        (.openAI, "OpenAI", "o3 & o4 Series"),
        (.gemini, "Google", "Gemini 2.5 Series")
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(providers, id: \.0) { provider, name, models in
                ProviderButton(
                    provider: provider,
                    name: name,
                    models: models,
                    isSelected: selectedProvider == provider,
                    action: { selectedProvider = provider }
                )
            }
        }
    }
}

struct ProviderButton: View {
    let provider: AIProvider
    let name: String
    let models: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .purple)

                Text(name)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : .primary)

                Text(models)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var iconName: String {
        switch provider {
        case .anthropic: return "brain"
        case .openAI: return "cpu"
        case .gemini: return "sparkle"
        }
    }
}

struct APIKeyInputCard: View {
    let provider: AIProvider
    @ObservedObject var viewModel: APISetupViewModel
    @State private var apiKey = ""
    @State private var selectedModel = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?

    var availableModels: [(id: String, display: String)] {
        switch provider {
        case .anthropic:
            return [
                ("claude-4-opus", "Claude 4 Opus"),
                ("claude-4-sonnet", "Claude 4 Sonnet")
            ]
        case .openAI:
            return [
                ("o3", "o3"),
                ("o3-mini", "o3-mini"),
                ("o4-mini", "o4-mini"),
                ("gpt-4o", "GPT-4o")
            ]
        case .gemini:
            return [
                ("gemini-2.5-flash", "Gemini 2.5 Flash"),
                ("gemini-2.5-pro", "Gemini 2.5 Pro")
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Provider header
            HStack {
                Image(systemName: providerIcon)
                    .font(.title3)
                    .foregroundColor(.purple)

                Text("\(provider.displayName) Configuration")
                    .font(.headline)

                Spacer()

                if let result = validationResult {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isValid ? .green : .red)
                }
            }

            // Model selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Model")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableModels, id: \.id) { model in
                            APIModelChip(
                                model: model.display,
                                isSelected: selectedModel == model.id,
                                action: { selectedModel = model.id }
                            )
                        }
                    }
                }
            }

            // API Key input
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    SecureField("Paste your API key here", text: $apiKey)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                    // Voice transcription available via WhisperVoiceButton if needed

                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )

                if let error = validationResult?.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: validateKey) {
                    Label("Validate", systemImage: "checkmark.shield")
                        .font(.subheadline)
                }
                .buttonStyle(APISetupSecondaryButtonStyle())
                .disabled(apiKey.isEmpty || selectedModel.isEmpty || isValidating)

                Button(action: saveKey) {
                    Label("Save", systemImage: "lock.fill")
                        .font(.subheadline)
                }
                .buttonStyle(APISetupPrimaryButtonStyle())
                .disabled(validationResult?.isValid != true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
        .onAppear {
            selectedModel = availableModels.first?.id ?? ""
        }
    }

    var providerIcon: String {
        switch provider {
        case .anthropic: return "brain"
        case .openAI: return "cpu"
        case .gemini: return "sparkle"
        }
    }

    func validateKey() {
        isValidating = true
        validationResult = nil

        Task {
            do {
                let isValid = try await viewModel.validateAPIKey(apiKey, for: provider, model: selectedModel)
                await MainActor.run {
                    validationResult = ValidationResult(
                        isValid: isValid,
                        error: isValid ? nil : "Invalid API key"
                    )
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationResult = ValidationResult(
                        isValid: false,
                        error: error.localizedDescription
                    )
                    isValidating = false
                }
            }
        }
    }

    func saveKey() {
        guard validationResult?.isValid == true else { return }

        isValidating = true
        Task {
            do {
                try await viewModel.saveAPIKey(apiKey, for: provider, model: selectedModel)
                await MainActor.run {
                    // Clear the form on success
                    apiKey = ""
                    validationResult = nil
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationResult = ValidationResult(
                        isValid: false,
                        error: "Failed to save: \(error.localizedDescription)"
                    )
                    isValidating = false
                }
            }
        }
    }
}

struct APIModelChip: View {
    let model: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(model)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConfiguredProvidersList: View {
    @ObservedObject var viewModel: APISetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configured Providers")
                .font(.headline)

            ForEach(viewModel.configuredProviders, id: \.provider) { config in
                HStack {
                    Image(systemName: config.provider.iconName)
                        .foregroundColor(.green)

                    VStack(alignment: .leading) {
                        Text(config.provider.displayName)
                            .font(.subheadline.bold())

                        Text(config.model)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.removeConfiguration(for: config.provider)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
    }
}

// Button Styles
struct APISetupPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct APISetupSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.purple)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// Supporting types
struct ValidationResult {
    let isValid: Bool
    let error: String?
}


#Preview {
    APISetupView()
}
