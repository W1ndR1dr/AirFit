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
    // For seamless native launch → SwiftUI transition, start EXACTLY matching launch screen
    // Logo: reveal mask + blur (opacity stays at 1)
    @State private var flameReveal: CGFloat = 1.0  // Start revealed (matches native launch)
    @State private var flameBlur: CGFloat = 0      // Start sharp (matches native launch)
    // Wordmark: opacity + blur (simple fade)
    @State private var wordmarkOpacity: Double = 0.0
    @State private var wordmarkBlur: CGFloat = 12
    // Glow: starts at 0 for seamless handoff (native launch screen has no glow)
    @State private var glowOpacity: Double = 0.0
    // Track if we should animate
    @State private var hasAnimated: Bool = false

    private var duration: Double { useLongAnimation ? 2.2 : 0.4 }

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
                Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.45),  // Purple glow for light mode
                Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.3),   // Pink
                Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.12),  // Peach (subtle)
                .clear
            ]
    }

    var body: some View {
        GeometryReader { geometry in
            // Screen-relative sizing for consistent visual proportions across devices
            // Base: iPhone 16 Pro (393 x 852), scale proportionally for other sizes
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            // Logo: ~92% of screen width on base device (360/393)
            let logoSize = screenWidth * 0.916
            // Y offset: ~5.9% of screen height above center (50/852)
            let logoY = -screenHeight * 0.059
            // Wordmark: ~18.2% of screen height below center (155/852)
            let wordmarkY = screenHeight * 0.182
            // Glow scales with logo
            let glowEndRadius = logoSize * 0.89  // 320/360
            // Font scales with screen width
            let wordmarkFontSize = screenWidth * 0.097  // 38/393

            ZStack {
                // Adaptive background
                backgroundColor
                    .ignoresSafeArea()

                // Warm glow - scales with logo
                RadialGradient(
                    colors: glowColors,
                    center: .center,
                    startRadius: logoSize * 0.14,  // 50/360
                    endRadius: glowEndRadius
                )
                .opacity(glowOpacity)
                .offset(y: logoY)

                // Logo - proportionally sized and positioned
                // NO scale animation - must match native launch screen exactly for seamless handoff
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
                    // Bottom-to-top reveal (flame rising) - for onboarding animation
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

                // Wordmark - proportionally sized and positioned
                if showWordmark {
                    Text("AirFit")
                        .font(.system(size: wordmarkFontSize, weight: .bold, design: .rounded))
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
            .frame(width: screenWidth, height: screenHeight)
        }
        .ignoresSafeArea()
        .onAppear {
            animate()
        }
    }

    private func animate() {
        guard !hasAnimated else { return }
        hasAnimated = true

        if useLongAnimation {
            // FIRST LAUNCH (Onboarding): Dramatic theatrical reveal
            // Reset to hidden state for the flame-rise animation
            flameReveal = 0.0
            flameBlur = 20
            glowOpacity = 0.0

            // Small delay to ensure reset takes effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // Main reveal animation - flame rises from bottom with blur clearing
                withAnimation(.easeOut(duration: duration)) {
                    flameReveal = 1.0
                    flameBlur = 0
                    wordmarkOpacity = 1.0
                    wordmarkBlur = 0
                    glowOpacity = 0.9
                }

                // Glow settles to ambient level after main animation
                withAnimation(.easeOut(duration: 1.0).delay(duration * 0.7)) {
                    glowOpacity = 0.4
                }
            }
        } else {
            // DAILY LAUNCH: Seamless handoff from native launch screen
            // Logo position/size matches exactly - only animate ambient glow bloom
            // This creates subtle "app coming alive" without any jarring movement
            withAnimation(.easeOut(duration: 0.35)) {
                glowOpacity = 0.4  // Glow blooms as app "comes alive"
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
