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
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                unitSelection
                examples
                saveButton
            }
            .padding()
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var unitSelection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Measurement System", icon: "ruler")
            
            Card {
                VStack(spacing: 0) {
                    ForEach(MeasurementSystem.allCases) { system in
                        UnitSystemRow(
                            system: system,
                            isSelected: selectedUnits == system
                        ) {
                            withAnimation {
                                selectedUnits = system
                            }
                            HapticManager.selection()
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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Examples", icon: "info.circle")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
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
        Button(action: saveUnits) {
            Label("Save Units", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryProminent)
        .disabled(selectedUnits == viewModel.preferredUnits)
    }
    
    private func saveUnits() {
        Task {
            try await viewModel.updateUnits(selectedUnits)
            HapticManager.notification(.success)
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
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
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
            .padding(.vertical, AppSpacing.small)
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
                .animation(.easeInOut(duration: 0.2), value: selectedSystem)
        }
    }
}
