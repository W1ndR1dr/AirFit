import SwiftUI

struct AirFitSplashView: View {
    // MARK: - Configuration
    /// Set to 'true' for Onboarding (longer, more cinematic)
    /// Set to 'false' for Daily Launch (fast, snappy)
    let useLongAnimation: Bool

    init(useLongAnimation: Bool = false) {
        self.useLongAnimation = useLongAnimation
    }

    // MARK: - Animation States
    @State private var logoOpacity: Double = 0.0
    @State private var blurIntensity: CGFloat = 15.0
    @State private var flameScale: CGFloat = 0.88
    @State private var shimmerOffset: CGFloat = -0.8
    @State private var glowIntensity: Double = 0.0

    // Timing based on animation mode
    private var duration: Double { useLongAnimation ? 2.2 : 0.7 }
    private var startDelay: Double { useLongAnimation ? 0.15 : 0.0 }

    var body: some View {
        ZStack {
            // 1. Deep Void Background
            // Matches the icon's background exactly for seamless blending
            Color(red: 10/255, green: 10/255, blue: 15/255)
                .ignoresSafeArea()

            // 2. The Main Logo (with its beautiful built-in glow)
            Image("AirFitLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 260, height: 260) // Slightly larger to push corners out
                // A. SOFT EDGE MASK - hides the rounded corners
                .mask(
                    RadialGradient(
                        colors: [
                            .white,
                            .white,
                            .white.opacity(0.95),
                            .white.opacity(0.7),
                            .clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 130
                    )
                )
                // B. FOCUS PULL - starts blurry, snaps sharp
                .blur(radius: blurIntensity)
                // C. SCALE - subtle grow into place
                .scaleEffect(flameScale)
                // D. FADE IN
                .opacity(logoOpacity)
                // E. PREMIUM SHIMMER - light sweep across the surface
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.03),
                                    .white.opacity(0.12),
                                    .white.opacity(0.03),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80)
                        .rotationEffect(.degrees(-20))
                        .offset(x: 260 * shimmerOffset)
                        .opacity(logoOpacity)
                )
        }
        .onAppear {
            igniteEngine()
        }
    }

    private func igniteEngine() {
        // 1. The Emergence (Fade + Scale + Focus)
        withAnimation(.interpolatingSpring(stiffness: 50, damping: 12).delay(startDelay)) {
            flameScale = 1.0
        }

        withAnimation(.easeOut(duration: duration).delay(startDelay)) {
            logoOpacity = 1.0
            blurIntensity = 0
        }

        // 2. The Shimmer (Luxury finishing touch)
        let shimmerDelay = useLongAnimation ? duration * 0.6 : duration * 0.5
        let shimmerDuration = useLongAnimation ? 1.0 : 0.45

        withAnimation(.easeOut(duration: shimmerDuration).delay(shimmerDelay)) {
            shimmerOffset = 1.0
        }
    }
}

#Preview("Daily Launch") {
    AirFitSplashView(useLongAnimation: false)
}

#Preview("Onboarding") {
    AirFitSplashView(useLongAnimation: true)
}
