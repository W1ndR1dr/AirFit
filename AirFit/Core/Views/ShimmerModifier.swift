import SwiftUI

/// Adds a shimmering effect to views for skeleton loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 400 - 200)
                .mask(content)
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies a shimmering effect for loading states
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}