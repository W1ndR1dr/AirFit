import SwiftUI

/// Shared animation presets and lightweight view helpers for a cohesive, soft feel
enum SoftMotion {
    static let background: Animation = .smooth(duration: 0.8)
    static let standard: Animation = .snappy(duration: 0.25)
    static let emphasize: Animation = .bouncy(extraBounce: 0.15)
}

struct SoftAppear: ViewModifier {
    let delay: Double
    func body(content: Content) -> some View {
        content
            .transition(.opacity.combined(with: .scale(scale: 0.995)))
            .animation(SoftMotion.standard.delay(delay), value: UUID())
    }
}

extension View {
    func softAppear(delay: Double = 0) -> some View { modifier(SoftAppear(delay: delay)) }
}

