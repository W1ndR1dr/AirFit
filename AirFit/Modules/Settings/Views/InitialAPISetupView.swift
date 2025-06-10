import SwiftUI

struct InitialAPISetupView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var selectedProvider: AIProvider = .gemini
    @State private var apiKey: String = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showingInfo = false
    
    let onCompletion: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accentColor)
                    .padding(.top, AppSpacing.xLarge)
                
                Text("Welcome to AirFit")
                    .font(AppFonts.largeTitle)
                    .fontWeight(.bold)
                
                Text("To use AI features, you'll need an API key")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, AppSpacing.xLarge)
            
            // Provider Selection
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Select AI Provider")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    ProviderOption(
                        provider: provider,
                        isSelected: selectedProvider == provider,
                        onTap: { selectedProvider = provider }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, AppSpacing.large)
            
            // API Key Input
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("API Key")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Button(action: { showingInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                SecureField("Enter your \(selectedProvider.displayName) API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isValidating)
                
                if let error = validationError {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.errorColor)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: AppSpacing.medium) {
                Button(action: validateAndSave) {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Configure AI")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(apiKey.isEmpty ? Color.gray : AppColors.accentColor)
                .foregroundColor(.white)
                .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                .disabled(apiKey.isEmpty || isValidating)
                
                Text("An API key is required to use AirFit")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColors.backgroundPrimary)
        .sheet(isPresented: $showingInfo) {
            APIKeyInfoSheet(provider: selectedProvider)
        }
    }
    
    private func validateAndSave() {
        isValidating = true
        validationError = nil
        
        Task {
            do {
                // Get API key manager from DI
                let apiKeyManager = try await diContainer.resolve(APIKeyManagementProtocol.self)
                
                // Validate format
                guard isValidAPIKeyFormat(apiKey, for: selectedProvider) else {
                    validationError = "Invalid API key format"
                    isValidating = false
                    return
                }
                
                // Save the key
                try await apiKeyManager.saveAPIKey(apiKey, for: selectedProvider)
                
                // Configure AI service
                let aiService = try await diContainer.resolve(AIServiceProtocol.self)
                try await aiService.configure()
                
                // Success
                await MainActor.run {
                    // TODO: Add haptic feedback via DI when needed
                    onCompletion()
                }
            } catch {
                await MainActor.run {
                    validationError = error.localizedDescription
                    // TODO: Add haptic feedback via DI when needed
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
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(providerDescription)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.accentColor : AppColors.textTertiary)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .fill(isSelected ? AppColors.accentColor.opacity(0.1) : AppColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .stroke(isSelected ? AppColors.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text("How to get your API key")
                        .font(AppFonts.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    ForEach(instructions, id: \.self) { instruction in
                        HStack(alignment: .top, spacing: AppSpacing.medium) {
                            Text("•")
                                .font(AppFonts.body)
                            Text(instruction)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Link("Get API Key", destination: providerURL)
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentColor)
                        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                        .padding(.top)
                }
                .padding(.horizontal)
            }
            .navigationTitle("\(provider.displayName) API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
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