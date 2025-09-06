import SwiftUI

/// SurfaceSystem centralizes materials, blur, tint, and shadow tokens
/// so glass/blur usage is consistent across the app.
enum SurfaceSystem {
    enum Glass: Sendable {
        case ultraThin
        case thin
        case regular
        case thick

        @available(iOS 15.0, *)
        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            }
        }
    }

    enum TabBarStyle: Sendable {
        case glassLight
        case glassDark

        var backgroundAlpha: CGFloat { 0.85 }
        var blurStyle: UIBlurEffect.Style {
            switch self {
            case .glassLight: return .systemThinMaterial
            case .glassDark: return .systemMaterial
            }
        }
    }

    /// Configure global Tab Bar appearance using tokens
    static func configureTabBarAppearance(for colorScheme: ColorScheme) {
        let style: TabBarStyle = (colorScheme == .dark) ? .glassDark : .glassLight

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(style.backgroundAlpha)
        appearance.backgroundEffect = UIBlurEffect(style: style.blurStyle)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Modifiers

struct SurfaceCapsuleModifier: ViewModifier {
    let glass: SurfaceSystem.Glass

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if #available(iOS 15.0, *) {
                        glass.material
                    } else {
                        Color.secondary.opacity(0.12)
                    }
                }
            )
            .clipShape(Capsule())
    }
}

extension View {
    /// Capsule chip with glass material background
    func surfaceCapsule(_ glass: SurfaceSystem.Glass = .thin) -> some View {
        modifier(SurfaceCapsuleModifier(glass: glass))
    }
}

