import SwiftUI

struct APIKeyEntryView: View {
    let provider: AIProvider
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showKey = false
    @FocusState private var isKeyFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: 0) {
                        // Title header
                        HStack {
                            CascadeText("Add API Key")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.lg)
                        
                        VStack(spacing: AppSpacing.xl) {
                            providerInfo
                            keyInput
                            instructions
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticService.impact(.light)
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticService.impact(.medium)
                        saveKey()
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    .foregroundStyle(apiKey.isEmpty || isValidating ? .secondary : Color.accentColor)
                }
            }
            .interactiveDismissDisabled(isValidating)
        }
    }
    
    private var providerInfo: some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: provider.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(provider.displayName)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("API Key Required")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
        }
    }
    
    private var keyInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "key.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("API Key")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        if showKey {
                            TextField("Enter your API key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                                .focused($isKeyFieldFocused)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Enter your API key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                                .focused($isKeyFieldFocused)
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
                    
                    if isValidating {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.accentColor)
                            Text("Validating key...")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .onAppear {
                isKeyFieldFocused = true
            }
        }
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Instructions")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(provider.keyInstructions, id: \.self) { instruction in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Text("•")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(instruction)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    if let url = provider.apiKeyURL {
                        Link(destination: url) {
                            HStack(spacing: AppSpacing.sm) {
                                Label("Get API Key", systemImage: "arrow.up.forward.square")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
        }
    }
    
    private func saveKey() {
        isValidating = true
        
        Task {
            do {
                try await viewModel.saveAPIKey(apiKey, for: provider)
                await MainActor.run {
                    HapticService.notification(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    HapticService.notification(.error)
                    viewModel.showAlert(.apiKeyInvalid)
                }
            }
        }
    }
}