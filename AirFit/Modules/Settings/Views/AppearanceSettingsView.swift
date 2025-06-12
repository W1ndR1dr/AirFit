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
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("Appearance")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)
                    
                    VStack(spacing: AppSpacing.xl) {
                        appearanceModeSection
                        themePreview
                        colorAccentSection
                        textSizeSection
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
    
    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Theme")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }
            
            GlassCard {
                VStack(spacing: 0) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        AppearanceModeRow(
                            mode: mode,
                            isSelected: selectedAppearance == mode
                        ) {
                            withAnimation {
                                selectedAppearance = mode
                            }
                            HapticService.impact(.light)
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // SectionHeader(title: "Preview", icon: "eye")
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    // Mini preview of app appearance
                    HStack(spacing: AppSpacing.md) {
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
                    
                    HStack(spacing: AppSpacing.md) {
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // SectionHeader(title: "Accent Color", icon: "paintpalette")
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    HStack {
                        Text("Choose your accent color")
                            .font(.subheadline)
                        Spacer()
                        Circle()
                            .fill(accentColor)
                            .frame(width: 24, height: 24)
                    }
                    
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(AccentColorOption.allCases, id: \.self) { option in
                            AccentColorButton(
                                color: option.color,
                                isSelected: accentColor == option.color
                            ) {
                                withAnimation {
                                    accentColor = option.color
                                }
                                HapticService.impact(.light)
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // SectionHeader(title: "Text Size", icon: "textformat.size")
            
            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    Text("Adjust text size in Settings → Display & Brightness")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        openDisplaySettings()
                    } label: {
                        Label("Open Display Settings", systemImage: "arrow.up.forward.square")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            saveAppearance()
        } label: {
            Label("Save Appearance", systemImage: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: selectedAppearance != viewModel.appearanceMode 
                            ? [Color.accentColor, Color.accentColor.opacity(0.8)]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedAppearance != viewModel.appearanceMode)
    }
    
    private func saveAppearance() {
        Task {
            try await viewModel.updateAppearance(selectedAppearance)
            HapticService.impact(.medium)
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
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
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
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

struct PreviewCard: View {
    let title: String
    let icon: String
    let appearance: AppearanceMode
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderColorForAppearance, lineWidth: 1)
                )
        )
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