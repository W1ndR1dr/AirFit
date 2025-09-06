import SwiftUI

/// Extensions for accessibility support
extension View {
    /// Apply animation only if reduce motion is not enabled
    @ViewBuilder
    func adaptiveAnimation<V: Equatable>(
        _ animation: Animation? = .default,
        value: V
    ) -> some View {
        self.animation(animation, value: value)
    }

    /// Apply transition only if reduce motion is not enabled
    @ViewBuilder
    func adaptiveTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }

    /// Cascade in effect that respects reduce motion
    @ViewBuilder
    func accessibleCascadeIn(delay: Double = 0) -> some View {
        self.modifier(AccessibleCascadeInModifier(delay: delay))
    }
}

struct AccessibleCascadeInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: (isVisible || reduceMotion) ? 0 : 20)
            .onAppear {
                if reduceMotion {
                    // Simple fade without motion
                    withAnimation(.smooth(duration: 0.2).delay(delay)) {
                        isVisible = true
                    }
                } else {
                    // Full cascade effect
                    withAnimation(
                        .bouncy(extraBounce: 0.2)
                            .delay(delay)
                    ) {
                        isVisible = true
                    }
                }
            }
    }
}

/// Reduced motion alternatives for complex animations
struct ReducedMotionAlternative<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: () -> Content
    let reducedContent: () -> Content

    var body: some View {
        if reduceMotion {
            reducedContent()
        } else {
            content()
        }
    }
}
