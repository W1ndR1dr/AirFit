import SwiftUI

/// A glass morphism card with blur effect and spring entrance animation
/// Creates depth without weight, allowing gradients to show through beautifully
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false
    
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let strokeOpacity: Double
    let blurRadius: CGFloat
    let enableHaptic: Bool
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        strokeOpacity: Double = 0.3,
        blurRadius: CGFloat = 12,
        enableHaptic: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
        self.blurRadius = blurRadius
        self.enableHaptic = enableHaptic
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(glassBackground)
            .scaleEffect(isVisible ? 1.0 : MotionToken.cardEntranceScale)
            .opacity(isVisible ? 1.0 : MotionToken.cardEntranceOpacity)
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    isVisible = true
                }
            }
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Ultra thin material for glass effect
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(strokeOpacity),
                            lineWidth: 1
                        )
                )
            
            // Subtle inner glow for depth
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.plusLighter)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Interactive Glass Card

/// Glass card with tap interaction and haptic feedback
struct InteractiveGlassCard<Content: View>: View {
    @State private var isPressed = false
    
    let content: Content
    let action: () -> Void
    
    init(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        GlassCard {
            content
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            // Haptic feedback
            HapticService.impact(.soft)
            
            // Visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Execute action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }
    }
}

// MARK: - Floating Glass Card

/// Glass card with parallax float effect (optional advanced component)
struct FloatingGlassCard<Content: View>: View {
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    
    let content: Content
    let floatAmplitude: CGFloat
    
    init(
        floatAmplitude: CGFloat = 4,
        @ViewBuilder content: () -> Content
    ) {
        self.floatAmplitude = floatAmplitude
        self.content = content()
    }
    
    var body: some View {
        GlassCard {
            content
        }
        .offset(offset)
        .onAppear {
            if !isDragging {
                withAnimation(
                    Animation.easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: floatAmplitude * 0.5,
                        height: floatAmplitude
                    )
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Wraps any view in a glass card
    func glassCard(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20
    ) -> some View {
        GlassCard(
            padding: padding,
            cornerRadius: cornerRadius
        ) {
            self
        }
    }
    
    /// Wraps any view in an interactive glass card
    func interactiveGlassCard(
        action: @escaping () -> Void
    ) -> some View {
        InteractiveGlassCard(action: action) {
            self
        }
    }
}