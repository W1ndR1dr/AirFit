import SwiftUI

struct APIConfigurationView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: AIProvider
    @State private var selectedModel: String
    @State private var showAPIKeyEntry = false
    @State private var providerToAddKey: AIProvider?
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _selectedProvider = State(initialValue: viewModel.selectedProvider)
        _selectedModel = State(initialValue: viewModel.selectedModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                currentConfiguration
                providerSelection
                apiKeyManagement
                saveButton
            }
            .padding()
        }
        .navigationTitle("AI Provider")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAPIKeyEntry) {
            if let provider = providerToAddKey {
                APIKeyEntryView(provider: provider, viewModel: viewModel)
            }
        }
    }
    
    private var currentConfiguration: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Current Configuration", icon: "cpu")
            
            Card {
                VStack(spacing: AppSpacing.md) {
                    ConfigRow(
                        title: "Provider",
                        value: viewModel.selectedProvider.displayName,
                        icon: viewModel.selectedProvider.icon
                    )
                    
                    ConfigRow(
                        title: "Model",
                        value: viewModel.selectedModel,
                        icon: "brain"
                    )
                    
                    ConfigRow(
                        title: "Status",
                        value: viewModel.installedAPIKeys.contains(viewModel.selectedProvider) ? "Active" : "No API Key",
                        icon: "checkmark.seal.fill",
                        valueColor: viewModel.installedAPIKeys.contains(viewModel.selectedProvider) ? .green : .orange
                    )
                }
            }
        }
    }
    
    private var providerSelection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Select Provider", icon: "rectangle.stack")
            
            Card {
                VStack(spacing: 0) {
                    ForEach(AIProvider.allCases) { provider in
                        ProviderRow(
                            provider: provider,
                            isSelected: selectedProvider == provider,
                            hasAPIKey: viewModel.installedAPIKeys.contains(provider),
                            models: provider.availableModels,
                            selectedModel: $selectedModel
                        ) {
                            withAnimation {
                                selectedProvider = provider
                                selectedModel = provider.defaultModel
                            }
                            HapticManager.selection()
                        }
                        
                        if provider != AIProvider.allCases.last {
                            Divider()
                                .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
            }
        }
    }
    
    private var apiKeyManagement: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "API Keys", icon: "key.fill")
            
            Card {
                VStack(spacing: AppSpacing.md) {
                    ForEach(AIProvider.allCases) { provider in
                        APIKeyRow(
                            provider: provider,
                            hasKey: viewModel.installedAPIKeys.contains(provider),
                            onAdd: {
                                providerToAddKey = provider
                                showAPIKeyEntry = true
                            },
                            onDelete: {
                                Task {
                                    try await viewModel.deleteAPIKey(for: provider)
                                }
                            }
                        )
                        
                        if provider != AIProvider.allCases.last {
                            Divider()
                        }
                    }
                }
            }
            
            Text("API keys are stored securely in your device's keychain")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveConfiguration) {
            Label("Save Configuration", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryProminent)
        .disabled(!viewModel.installedAPIKeys.contains(selectedProvider))
    }
    
    private func saveConfiguration() {
        Task {
            do {
                try await viewModel.updateAIProvider(selectedProvider, model: selectedModel)
                dismiss()
            } catch {
                // Handle error
                viewModel.coordinator.showAlert(.error(message: error.localizedDescription))
            }
        }
    }
}

// MARK: - Supporting Views
struct ProviderRow: View {
    let provider: AIProvider
    let isSelected: Bool
    let hasAPIKey: Bool
    let models: [String]
    @Binding var selectedModel: String
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: provider.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(provider.displayName)
                        .font(.headline)
                    
                    Text("\(models.count) models available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if hasAPIKey {
                    Image(systemName: "key.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.accentColor)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
        
        // Model selection (shown when selected)
        if isSelected {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(models, id: \.self) { model in
                            ModelChip(
                                model: model,
                                isSelected: selectedModel == model,
                                onSelect: {
                                    selectedModel = model
                                    HapticManager.selection()
                                }
                            )
                        }
                    }
                }
            }
            .padding(.top, AppSpacing.sm)
        }
    }
}

struct ModelChip: View {
    let model: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text(model)
                .font(.caption)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? Color.accentColor : Color.secondaryBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct APIKeyRow: View {
    let provider: AIProvider
    let hasKey: Bool
    let onAdd: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Label(provider.displayName, systemImage: provider.icon)
            
            Spacer()
            
            if hasKey {
                Button(action: onDelete) {
                    Label("Remove", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onAdd) {
                    Label("Add Key", systemImage: "plus.circle")
                        .font(.footnote)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}

struct ConfigRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .fontWeight(.medium)
        }
    }
}
