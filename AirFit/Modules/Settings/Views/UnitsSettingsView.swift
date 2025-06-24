import SwiftUI

struct UnitsSettingsView: View {
    var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUnits: MeasurementSystem
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _selectedUnits = State(initialValue: viewModel.preferredUnits)
    }
    
    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("Units")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)
                    
                    VStack(spacing: AppSpacing.xl) {
                        unitSelection
                        examples
                        saveButton
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var unitSelection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Measurement System")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: 0) {
                    ForEach(MeasurementSystem.allCases) { system in
                        UnitSystemRow(
                            system: system,
                            isSelected: selectedUnits == system
                        ) {
                            withAnimation {
                                selectedUnits = system
                            }
                            HapticService.impact(.light)
                        }
                        
                        if system != MeasurementSystem.allCases.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var examples: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Examples")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    ExampleRow(
                        label: "Weight",
                        imperial: "150 lbs",
                        metric: "68 kg",
                        selectedSystem: selectedUnits
                    )
                    
                    Divider()
                    
                    ExampleRow(
                        label: "Height",
                        imperial: "5'10\"",
                        metric: "178 cm",
                        selectedSystem: selectedUnits
                    )
                    
                    Divider()
                    
                    ExampleRow(
                        label: "Distance",
                        imperial: "3 miles",
                        metric: "5 km",
                        selectedSystem: selectedUnits
                    )
                    
                    Divider()
                    
                    ExampleRow(
                        label: "Temperature",
                        imperial: "72°F",
                        metric: "22°C",
                        selectedSystem: selectedUnits
                    )
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            saveUnits()
        } label: {
            Label("Save Units", systemImage: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: selectedUnits != viewModel.preferredUnits
                            ? [Color.accentColor, Color.accentColor.opacity(0.8)]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedUnits == viewModel.preferredUnits)
    }
    
    private func saveUnits() {
        Task {
            try await viewModel.updateUnits(selectedUnits)
            HapticService.impact(.medium)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
struct UnitSystemRow: View {
    let system: MeasurementSystem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(system.displayName)
                        .font(.headline)
                    
                    Text(system.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

struct ExampleRow: View {
    let label: String
    let imperial: String
    let metric: String
    let selectedSystem: MeasurementSystem
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(selectedSystem == .imperial ? imperial : metric)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
                .animation(.easeInOut(duration: 0.2), value: selectedSystem)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
