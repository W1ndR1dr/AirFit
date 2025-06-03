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
                    
                    if let pricing = viewModel.selectedProvider.pricing(for: viewModel.selectedModel) {
                        ConfigRow(
                            title: "Pricing (per 1M tokens)",
                            value: pricing.input == 0 && pricing.output == 0 ? "Free" : String(format: "$%.2f in / $%.2f out", pricing.input, pricing.output),
                            icon: "dollarsign.circle",
                            valueColor: pricing.input == 0 ? .green : .primary
                        )
                    }
                    
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
                                provider: provider,
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
            
            // Show model details when selected
            if let selectedModelDetails = models.first(where: { $0 == selectedModel }) {
                ModelDetailsCard(model: selectedModelDetails, provider: provider)
                    .padding(.top, AppSpacing.sm)
            }
        }
    }
}

struct ModelDetailsCard: View {
    let model: String
    let provider: AIProvider
    
    private var modelEnum: LLMModel? {
        LLMModel.allCases.first { $0.identifier == model }
    }
    
    var body: some View {
        if let modelEnum = modelEnum {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Model Details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    DetailRow(label: "Context Window", value: formatTokenCount(modelEnum.contextWindow))
                    DetailRow(label: "Description", value: modelEnum.description)
                    
                    if !modelEnum.specialFeatures.isEmpty {
                        DetailRow(label: "Features", value: modelEnum.specialFeatures.joined(separator: ", "))
                    }
                }
                .font(.caption)
                .padding(AppSpacing.sm)
                .background(Color.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusXs))
            }
        }
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return "\(count / 1_000_000)M tokens"
        } else if count >= 1_000 {
            return "\(count / 1_000)K tokens"
        } else {
            return "\(count) tokens"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

struct ModelChip: View {
    let model: String
    let isSelected: Bool
    let provider: AIProvider
    let onSelect: () -> Void
    
    private var pricing: (input: Double, output: Double)? {
        provider.pricing(for: model)
    }
    
    private var displayName: String {
        // Extract display name from model identifier
        switch model {
        case "gpt-4o": return "GPT-4o"
        case "gpt-4o-mini": return "GPT-4o Mini"
        case "gpt-4-turbo-2024-04-09": return "GPT-4 Turbo"
        case "gpt-4": return "GPT-4"
        case "gpt-3.5-turbo": return "GPT-3.5 Turbo"
        case "claude-3-5-sonnet-20241022": return "Claude 3.5 Sonnet"
        case "claude-3-opus-20240229": return "Claude 3 Opus"
        case "claude-3-sonnet-20240229": return "Claude 3 Sonnet"
        case "claude-3-5-haiku-20241022": return "Claude 3.5 Haiku"
        case "claude-3-haiku-20240307": return "Claude 3 Haiku"
        case "gemini-2.0-flash-thinking-exp": return "Gemini 2.0 Flash Thinking"
        case "gemini-2.0-flash-exp": return "Gemini 2.0 Flash"
        case "gemini-1.5-pro-002": return "Gemini 1.5 Pro"
        case "gemini-1.5-flash-002": return "Gemini 1.5 Flash"
        case "gemini-1.0-pro": return "Gemini 1.0 Pro"
        default: return model
        }
    }
    
    private var priceString: String? {
        guard let pricing = pricing else { return nil }
        if pricing.input == 0 && pricing.output == 0 {
            return "Free"
        }
        return String(format: "$%.2f/$%.2f", pricing.input, pricing.output)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                
                if let priceString = priceString {
                    Text(priceString)
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? Color.accentColor : Color.secondaryBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
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
