import SwiftUI

// MARK: - Splash View (Onboarding)

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var hintOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var hasCompleted = false

    let onComplete: () -> Void

    // Appearance-adaptive colors for swipe hint
    // Uses warm tones that harmonize with the splash glow
    private var baseTextColor: Color {
        colorScheme == .dark
            ? .white.opacity(0.5)
            : Color(red: 0.75, green: 0.45, blue: 0.45).opacity(0.65)  // Warm dusty rose
    }

    private var shimmerColors: [Color] {
        colorScheme == .dark
            ? [.clear, .white.opacity(0.4), .clear]
            : [
                // Warm coral shimmer for light mode
                .clear,
                Color(red: 0.95, green: 0.50, blue: 0.45).opacity(0.85),  // Coral shimmer
                Color(red: 0.85, green: 0.40, blue: 0.50).opacity(0.6),   // Rose shimmer
                .clear
            ]
    }

    var body: some View {
        ZStack {
            // Splash with flame animation + wordmark
            AirFitSplashView(useLongAnimation: true, showWordmark: true)

            // Swipe hint at bottom with shimmer
            VStack {
                Spacer()

                Text("Swipe to begin")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(baseTextColor)
                    .overlay(
                        // Subtle shimmer sweep - adaptive colors
                        LinearGradient(
                            colors: shimmerColors,
                            startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
                            endPoint: UnitPoint(x: shimmerOffset + 0.4, y: 0.5)
                        )
                        .mask(
                            Text("Swipe to begin")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        )
                    )
                    .opacity(hintOpacity)
                    .padding(.bottom, 70)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if abs(value.translation.width) > 50 && hintOpacity > 0 && !hasCompleted {
                        hasCompleted = true
                        onComplete()
                    }
                }
        )
        .onTapGesture {
            if hintOpacity > 0 && !hasCompleted {
                hasCompleted = true
                onComplete()
            }
        }
        .onAppear {
            // Fade in hint
            withAnimation(.easeOut(duration: 0.8).delay(2.0)) {
                hintOpacity = 1.0
            }

            // Start shimmer loop
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false).delay(2.5)) {
                shimmerOffset = 1.2
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
