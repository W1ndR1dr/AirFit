import SwiftUI

/// Base wrapper for all screens in AirFit
/// Provides gradient background and consistent screen-level styling
struct BaseScreen<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var fallbackGradientManager = GradientManager()
    
    let content: Content
    let safeAreaIgnored: Bool
    let screenPadding: CGFloat
    
    init(
        safeAreaIgnored: Bool = true,
        screenPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.safeAreaIgnored = safeAreaIgnored
        self.screenPadding = screenPadding
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Gradient background layer - always use fallback manager
            fallbackGradientManager.currentGradient(for: colorScheme)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Subtle animated particles (optional polish - can be added later)
            // ParticleOverlay()
            
            // Content layer
            if screenPadding > 0 {
                content
                    .padding(screenPadding)
            } else {
                content
            }
        }
        .animation(.easeInOut(duration: 0.6), value: fallbackGradientManager.active)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Wraps any view in the BaseScreen container
    func baseScreen(
        safeAreaIgnored: Bool = true,
        screenPadding: CGFloat = 0
    ) -> some View {
        BaseScreen(
            safeAreaIgnored: safeAreaIgnored,
            screenPadding: screenPadding
        ) {
            self
        }
    }
}

// MARK: - Navigation Extensions

extension View {
    /// Advances gradient when navigating to a new screen
    func advanceGradientOnAppear() -> some View {
        self.modifier(AdvanceGradientModifier())
    }
}

private struct AdvanceGradientModifier: ViewModifier {
    @EnvironmentObject private var gradientManager: GradientManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                gradientManager.advance()
            }
    }
}