import SwiftUI

struct SoftPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(gradientManager.active.accentColor(for: colorScheme))
                    .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(SoftMotion.emphasize, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SoftPrimaryButtonStyle {
    static var softPrimary: SoftPrimaryButtonStyle { SoftPrimaryButtonStyle() }
}

struct SoftChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SoftMotion.standard, value: configuration.isPressed)
    }
}

struct SoftSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .stroke(gradientManager.active.accentColor(for: colorScheme).opacity(0.35), lineWidth: 1)
                    .background(
                        Capsule().fill(Color.black.opacity(colorScheme == .dark ? 0.06 : 0.04))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(SoftMotion.standard, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SoftSecondaryButtonStyle {
    static var softSecondary: SoftSecondaryButtonStyle { SoftSecondaryButtonStyle() }
}
