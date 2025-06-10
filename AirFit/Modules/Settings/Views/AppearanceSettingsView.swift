import SwiftUI

struct AppearanceSettingsView: View {
    var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAppearance: AppearanceMode
    @State private var accentColor: Color = .accentColor
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _selectedAppearance = State(initialValue: viewModel.appearanceMode)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                appearanceModeSection
                themePreview
                colorAccentSection
                textSizeSection
                saveButton
            }
            .padding()
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Theme", icon: "paintbrush")
            
            Card {
                VStack(spacing: 0) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        AppearanceModeRow(
                            mode: mode,
                            isSelected: selectedAppearance == mode
                        ) {
                            withAnimation {
                                selectedAppearance = mode
                            }
                            // TODO: Add haptic feedback via DI when needed
                        }
                        
                        if mode != AppearanceMode.allCases.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var themePreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Preview", icon: "eye")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    // Mini preview of app appearance
                    HStack(spacing: AppSpacing.medium) {
                        PreviewCard(
                            title: "Dashboard",
                            icon: "house.fill",
                            appearance: selectedAppearance
                        )
                        
                        PreviewCard(
                            title: "Workouts",
                            icon: "figure.run",
                            appearance: selectedAppearance
                        )
                    }
                    
                    HStack(spacing: AppSpacing.medium) {
                        PreviewCard(
                            title: "Nutrition",
                            icon: "fork.knife",
                            appearance: selectedAppearance
                        )
                        
                        PreviewCard(
                            title: "Chat",
                            icon: "bubble.left.and.bubble.right.fill",
                            appearance: selectedAppearance
                        )
                    }
                }
            }
        }
    }
    
    private var colorAccentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Accent Color", icon: "paintpalette")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    HStack {
                        Text("Choose your accent color")
                            .font(.subheadline)
                        Spacer()
                        Circle()
                            .fill(accentColor)
                            .frame(width: 24, height: 24)
                    }
                    
                    HStack(spacing: AppSpacing.small) {
                        ForEach(AccentColorOption.allCases, id: \.self) { option in
                            AccentColorButton(
                                color: option.color,
                                isSelected: accentColor == option.color
                            ) {
                                withAnimation {
                                    accentColor = option.color
                                }
                                // TODO: Add haptic feedback via DI when needed
                            }
                        }
                    }
                    
                    Text("Note: Custom accent colors will be available in a future update")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var textSizeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Text Size", icon: "textformat.size")
            
            Card {
                VStack(spacing: AppSpacing.medium) {
                    Text("Adjust text size in Settings → Display & Brightness")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Button(action: openDisplaySettings) {
                        Label("Open Display Settings", systemImage: "arrow.up.forward.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveAppearance) {
            Label("Save Appearance", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryProminent)
        .disabled(selectedAppearance == viewModel.appearanceMode)
    }
    
    private func saveAppearance() {
        Task {
            try await viewModel.updateAppearance(selectedAppearance)
            // TODO: Add haptic feedback via DI when needed
            dismiss()
        }
    }
    
    private func openDisplaySettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views
struct AppearanceModeRow: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(mode.displayName)
                        .font(.headline)
                    
                    Text(mode.description)
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

struct PreviewCard: View {
    let title: String
    let icon: String
    let appearance: AppearanceMode
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColorForAppearance)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColorForAppearance, lineWidth: 1)
        }
    }
    
    private var backgroundColorForAppearance: Color {
        switch appearance {
        case .light:
            return Color(uiColor: .systemBackground)
        case .dark:
            return Color(uiColor: .secondarySystemBackground)
        case .system:
            return Color(uiColor: .systemBackground)
        }
    }
    
    private var borderColorForAppearance: Color {
        switch appearance {
        case .light:
            return Color(uiColor: .separator).opacity(0.5)
        case .dark:
            return Color(uiColor: .separator)
        case .system:
            return Color(uiColor: .separator).opacity(0.5)
        }
    }
}

struct AccentColorButton: View {
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: 3)
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions
extension AppearanceMode {
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        case .system: return "Match system appearance"
        }
    }
}

enum AccentColorOption: String, CaseIterable {
    case blue
    case purple
    case green
    case orange
    case red
    case pink
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        }
    }
}