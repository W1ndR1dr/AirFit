import SwiftUI

struct AirFitSplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    let useLongAnimation: Bool
    let showWordmark: Bool

    init(useLongAnimation: Bool = false, showWordmark: Bool = false) {
        self.useLongAnimation = useLongAnimation
        self.showWordmark = showWordmark
    }

    // Animation states - separate concerns
    // For seamless native launch → SwiftUI transition, start SHARP (matching launch screen)
    // Logo: reveal mask + blur (opacity stays at 1)
    @State private var flameReveal: CGFloat = 1.0  // Start revealed (matches native launch)
    @State private var flameBlur: CGFloat = 0      // Start sharp (matches native launch)
    // Wordmark: opacity + blur (simple fade)
    @State private var wordmarkOpacity: Double = 0.0
    @State private var wordmarkBlur: CGFloat = 12
    // Glow: opacity only
    @State private var glowOpacity: Double = 0.4   // Start with subtle glow
    // Track if we should animate
    @State private var hasAnimated: Bool = false

    private var duration: Double { useLongAnimation ? 2.2 : 0.5 }

    // FIXED positions - these NEVER change
    private let logoSize: CGFloat = 360
    private let logoY: CGFloat = -50
    private let wordmarkY: CGFloat = 155

    // Appearance-adaptive colors - MUST match LaunchBackground.colorset exactly for seamless transition
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.110, green: 0.098, blue: 0.090)  // Dark: matches LaunchBackground dark
            : Color(red: 1.000, green: 0.973, blue: 0.941)  // Light: matches LaunchBackground light (#FFF8F0)
    }

    private var glowColors: [Color] {
        colorScheme == .dark
            ? [
                Color.orange.opacity(0.55),
                Color(red: 1.0, green: 0.45, blue: 0.2).opacity(0.25),
                Color.red.opacity(0.08),
                .clear
            ]
            : [
                Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.45),  // Purple glow for light mode (boosted)
                Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.3),   // Pink (boosted)
                Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.12),  // Peach (subtle boost)
                .clear
            ]
    }

    var body: some View {
        ZStack {
            // Adaptive background
            backgroundColor
                .ignoresSafeArea()

            // Warm glow - FIXED position, appears with logo (scaled with logo size)
            RadialGradient(
                colors: glowColors,
                center: .center,
                startRadius: 50,
                endRadius: 320
            )
            .opacity(glowOpacity)
            .offset(y: logoY)

            // Logo - FIXED position, always opacity=1, animated via mask+blur
            // Uses LaunchLogo which has light/dark variants
            Image("LaunchLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: logoSize, height: logoSize)
                // Soft radial edge fade
                .mask(
                    RadialGradient(
                        colors: [.white, .white, .white.opacity(0.95), .white.opacity(0.4), .clear],
                        center: .center,
                        startRadius: logoSize * 0.22,
                        endRadius: logoSize * 0.48
                    )
                )
                // Bottom-to-top reveal (flame rising) - THIS is the animation
                .mask(
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: logoSize * (1 - flameReveal))
                        Color.white
                    }
                    .frame(width: logoSize, height: logoSize)
                )
                .blur(radius: flameBlur)
                .offset(y: logoY)

            // Wordmark - FIXED position, simple opacity+blur fade
            if showWordmark {
                Text("AirFit")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [
                                    Color(red: 255/255, green: 150/255, blue: 110/255),  // Peachy orange
                                    Color(red: 230/255, green: 105/255, blue: 155/255)   // Pink
                                ]
                                : [
                                    Color(red: 0.5, green: 0.3, blue: 0.8),  // Purple to match light icon
                                    Color(red: 0.85, green: 0.4, blue: 0.55)  // Magenta pink
                                ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blur(radius: wordmarkBlur)
                    .opacity(wordmarkOpacity)
                    .offset(y: wordmarkY)
            }
        }
        .onAppear {
            animate()
        }
    }

    private func animate() {
        guard !hasAnimated else { return }
        hasAnimated = true

        if useLongAnimation {
            // Onboarding: dramatic reveal animation
            // First reset to hidden state, then animate
            flameReveal = 0.0
            flameBlur = 20
            glowOpacity = 0.0

            // Small delay to ensure reset takes effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: duration)) {
                    flameReveal = 1.0
                    flameBlur = 0
                    wordmarkOpacity = 1.0
                    wordmarkBlur = 0
                    glowOpacity = 0.9
                }

                // Glow settles down after main animation
                withAnimation(.easeOut(duration: 1.0).delay(duration * 0.7)) {
                    glowOpacity = 0.4
                }
            }
        } else {
            // Daily launch: already sharp (seamless from native launch)
            // Just fade in wordmark if shown
            withAnimation(.easeOut(duration: 0.3)) {
                wordmarkOpacity = 1.0
                wordmarkBlur = 0
            }
        }
    }
}

#Preview("Daily Launch") {
    AirFitSplashView(useLongAnimation: false)
}

#Preview("Onboarding") {
    AirFitSplashView(useLongAnimation: true)
}
