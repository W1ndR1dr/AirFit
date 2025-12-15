import SwiftUI

// MARK: - Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App icon with glow effect
                ZStack {
                    // Glow
                    Circle()
                        .fill(Theme.accent.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)

                    // Icon container
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Theme.accentGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 20, y: 10)

                    Image(systemName: "figure.run")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("AirFit")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            // Animate logo
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Animate text with delay
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }

            // Auto-advance
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
