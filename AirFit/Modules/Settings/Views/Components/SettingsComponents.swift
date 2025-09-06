import SwiftUI

// MARK: - Settings Card Component (DEPRECATED - Use GlassCard instead)
// This is kept for backward compatibility during migration
struct SettingsCard<Content: View>: View {
    let content: Content
    let style: CardStyle

    init(style: CardStyle = .normal, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        // Now uses GlassCard internally
        GlassCard {
            content
        }
        .overlay {
            if style == .destructive {
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
            }
        }
    }

    enum CardStyle {
        case normal
        case destructive
    }
}

// MARK: - Button Styles
extension ButtonStyle where Self == PrimaryProminentButtonStyle {
    static var primaryProminent: PrimaryProminentButtonStyle {
        PrimaryProminentButtonStyle()
    }
}

struct PrimaryProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.accentColor : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.accentColor)
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var destructive: DestructiveButtonStyle {
        DestructiveButtonStyle()
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote)
            .foregroundColor(.red)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Color Extensions for Settings
extension Color {
    static var secondaryBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
}

// MARK: - Convenience Initializers
extension Label where Title == Text, Icon == Image {
    init(_ title: String, systemImage: String) {
        self.init {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
        }
    }
}
