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
    // For seamless native launch → SwiftUI transition, start matching iOS launch screen exactly
    // Logo: reveal mask + blur (opacity stays at 1)
    @State private var flameReveal: CGFloat = 1.0  // Start revealed (matches native launch)
    @State private var flameBlur: CGFloat = 0      // Start sharp (matches native launch)
    // Scale: for daily launch, subtle "settle" animation picking up from iOS icon scaling
    @State private var logoScale: CGFloat = 1.0    // Start at 1.0, animate for settle effect
    // Wordmark: opacity + blur (simple fade)
    @State private var wordmarkOpacity: Double = 0.0
    @State private var wordmarkBlur: CGFloat = 12
    // Glow: opacity only - starts at 0 for daily launch to create "bloom" effect
    @State private var glowOpacity: Double = 0.0
    // Track if we should animate
    @State private var hasAnimated: Bool = false

    private var duration: Double { useLongAnimation ? 2.2 : 0.4 }

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

    // Glow colors - warm tones for both modes to complement the flame icon
    // Light mode uses rose/coral/peach to harmonize with cream background
    // Dark mode uses orange/amber to create that perfect warm ambiance
    private var glowColors: [Color] {
        colorScheme == .dark
            ? [
                Color.orange.opacity(0.55),
                Color(red: 1.0, green: 0.45, blue: 0.2).opacity(0.25),
                Color.red.opacity(0.08),
                .clear
            ]
            : [
                // Warm rose-coral gradient for light mode (harmonizes with cream background)
                Color(red: 1.0, green: 0.55, blue: 0.45).opacity(0.40),   // Coral center
                Color(red: 0.95, green: 0.45, blue: 0.50).opacity(0.25),  // Rose mid
                Color(red: 0.85, green: 0.50, blue: 0.55).opacity(0.10),  // Dusty rose outer
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

            // Logo - FIXED position, always opacity=1, animated via mask+blur+scale
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
                .scaleEffect(logoScale)  // Subtle settle animation for daily launch
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
                                    // Warm coral-to-rose gradient for light mode
                                    // Harmonizes with the warm glow colors
                                    Color(red: 0.95, green: 0.45, blue: 0.40),  // Coral
                                    Color(red: 0.85, green: 0.35, blue: 0.50)   // Deep rose
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
            // FIRST LAUNCH (Onboarding): Dramatic theatrical reveal
            // Reset to hidden state for the flame-rise animation
            flameReveal = 0.0
            flameBlur = 20
            glowOpacity = 0.0
            logoScale = 1.0  // No scale animation for onboarding

            // Small delay to ensure reset takes effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // Main reveal animation - flame rises from bottom with blur clearing
                withAnimation(.easeOut(duration: duration)) {
                    flameReveal = 1.0
                    flameBlur = 0
                    wordmarkOpacity = 1.0
                    wordmarkBlur = 0
                    glowOpacity = 0.85  // Peak glow during reveal
                }

                // Glow settles to ambient level after main animation
                withAnimation(.easeOut(duration: 1.2).delay(duration * 0.6)) {
                    glowOpacity = 0.5
                }
            }
        } else {
            // DAILY LAUNCH: Snappy "bloom" effect that harmonizes with iOS icon scaling
            // iOS scales the app icon up into the launch screen over ~0.3s
            // We pick up from there with a subtle settle + glow bloom

            // Start state: matches native launch screen exactly (no glow)
            // but with imperceptible scale that we'll animate
            logoScale = 0.985  // Slightly smaller - picks up from iOS scale animation
            glowOpacity = 0.0   // No glow initially (matches native launch screen)

            // Settle animation: logo gently scales to final size, glow blooms in
            // Uses spring for organic feel, matching Apple's animation curves
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                logoScale = 1.0
                glowOpacity = 0.45  // Glow blooms as app "comes alive"
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
