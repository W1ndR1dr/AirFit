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
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    providerInfo
                    keyInput
                    instructions
                }
                .padding()
            }
            .navigationTitle("Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveKey() }
                        .disabled(apiKey.isEmpty || isValidating)
                }
            }
            .interactiveDismissDisabled(isValidating)
        }
    }
    
    private var providerInfo: some View {
        Card {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: provider.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(provider.displayName)
                        .font(.headline)
                    
                    Text("API Key Required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var keyInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "API Key", icon: "key.fill")
            
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        if showKey {
                            TextField("Enter your API key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .focused($isKeyFieldFocused)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Enter your API key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .focused($isKeyFieldFocused)
                        }
                        
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if isValidating {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Validating key...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)
            }
            .onAppear {
                isKeyFieldFocused = true
            }
        }
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Instructions", icon: "info.circle")
            
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(provider.keyInstructions, id: \.self) { instruction in
                        Label {
                            Text(instruction)
                                .font(.callout)
                        } icon: {
                            Text("•")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let url = provider.apiKeyURL {
                        Link(destination: url) {
                            Label("Get API Key", systemImage: "arrow.up.forward.square")
                                .font(.callout)
                        }
                    }
                }
            }
        }
    }
    
    private func saveKey() {
        isValidating = true
        
        Task {
            do {
                try await viewModel.saveAPIKey(apiKey, for: provider)
                await MainActor.run {
                    // TODO: Add haptic feedback via DI when needed
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    viewModel.showAlert(.apiKeyInvalid)
                }
            }
        }
    }
}
