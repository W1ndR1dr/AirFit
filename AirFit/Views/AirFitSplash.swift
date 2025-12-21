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
    // Logo: reveal mask + blur (opacity stays at 1)
    @State private var flameReveal: CGFloat = 0.0
    @State private var flameBlur: CGFloat = 20
    // Wordmark: opacity + blur (simple fade)
    @State private var wordmarkOpacity: Double = 0.0
    @State private var wordmarkBlur: CGFloat = 12
    // Glow: opacity only
    @State private var glowOpacity: Double = 0.0

    private var duration: Double { useLongAnimation ? 2.2 : 0.5 }

    // FIXED positions - these NEVER change
    private let logoSize: CGFloat = 360
    private let logoY: CGFloat = -50
    private let wordmarkY: CGFloat = 155

    // Appearance-adaptive colors
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 10/255, green: 10/255, blue: 15/255)  // Dark: near black
            : Color(red: 255/255, green: 248/255, blue: 240/255)  // Light: honeyed cream #FFF8F0
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
                Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.35),  // Purple glow for light mode
                Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.2),
                Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.08),
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
        // SINGLE animation block - everything moves together
        withAnimation(.easeOut(duration: duration)) {
            // Logo: reveal from bottom + deblur
            flameReveal = 1.0
            flameBlur = 0
            // Wordmark: fade in + deblur
            wordmarkOpacity = 1.0
            wordmarkBlur = 0
            // Glow: fade in
            glowOpacity = 0.9
        }

        // Glow settles down after main animation
        withAnimation(.easeOut(duration: 1.0).delay(duration * 0.7)) {
            glowOpacity = 0.4
        }
    }
}

#Preview("Daily Launch") {
    AirFitSplashView(useLongAnimation: false)
}

#Preview("Onboarding") {
    AirFitSplashView(useLongAnimation: true)
}
