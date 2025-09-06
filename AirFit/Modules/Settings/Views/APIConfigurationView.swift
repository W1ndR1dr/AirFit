import SwiftUI

struct APIConfigurationView: View {
    @Bindable var viewModel: SettingsViewModel
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
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("AI Provider")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                    VStack(spacing: AppSpacing.xl) {
                        currentConfiguration
                        providerSelection
                        apiKeyManagement
                        saveButton
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAPIKeyEntry) {
            if let provider = providerToAddKey {
                APIKeyEntryView(provider: provider, viewModel: viewModel)
            }
        }
    }

    private var currentConfiguration: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Current Configuration")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Select Provider")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
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
                            HapticService.play(.listSelection)
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("API Keys")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
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
        }
        .buttonStyle(.softPrimary)
        .disabled(!viewModel.installedAPIKeys.contains(selectedProvider))
    }

    private func saveConfiguration() {
        Task {
            do {
                try await viewModel.updateAIProvider(selectedProvider, model: selectedModel)
                dismiss()
            } catch {
                // Handle error
                viewModel.showAlert(.error(message: error.localizedDescription))
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
                    .background(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

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
                        .foregroundStyle(Color.accentColor)
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
                                    HapticService.play(.listSelection)
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
        LLMModel(rawValue: model)
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
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
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

    private var displayName: String { LLMModel(rawValue: model)?.displayName ?? model }

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
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(.red.opacity(0.1))
                        )
                }
            } else {
                Button(action: onAdd) {
                    Label("Add Key", systemImage: "plus.circle")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .frame(height: 30)
                }
                .buttonStyle(.softPrimary)
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
