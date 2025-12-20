import SwiftUI

/// Compact appearance mode selector (System / Light / Dark).
/// Three circular options in a single row.
struct AppearanceControl: View {
    @Binding var selectedMode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 0) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    AppearanceOption(
                        mode: mode,
                        isSelected: selectedMode == mode.rawValue,
                        onSelect: {
                            withAnimation(.bloomSubtle) {
                                selectedMode = mode.rawValue
                            }
                        }
                    )
                }
            }
            .padding(4)
            .background(Theme.background.opacity(0.5))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Appearance Option

struct AppearanceOption: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14))

                Text(mode.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.accent : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var mode = "System"

        var body: some View {
            AppearanceControl(selectedMode: $mode)
                .padding()
                .background(Theme.background)
        }
    }

    return PreviewWrapper()
}
