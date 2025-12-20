import SwiftUI

// MARK: - Splash View (Onboarding)

struct SplashView: View {
    @State private var textOpacity: CGFloat = 0
    @State private var textOffset: CGFloat = 10
    @State private var showContinue = false
    @State private var continuePulse = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Use the new AirFitSplashView with long animation for onboarding
            AirFitSplashView(useLongAnimation: true)

            // App name and continue hint
            VStack {
                Spacer()

                Text("AirFit")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 255/255, green: 130/255, blue: 100/255),
                                Color(red: 200/255, green: 80/255, blue: 180/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(textOpacity)
                    .offset(y: textOffset)

                Spacer()
                    .frame(height: 60)

                // Tap to continue hint
                HStack(spacing: 6) {
                    Text("Tap to continue")
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.5))
                .opacity(showContinue ? (continuePulse ? 0.7 : 0.4) : 0)
                .padding(.bottom, 60)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showContinue {
                onComplete()
            }
        }
        .onAppear {
            // Fade in app name after flame has risen
            withAnimation(.easeOut(duration: 0.8).delay(1.8)) {
                textOpacity = 1.0
                textOffset = 0
            }

            // Show continue hint after animation settles
            withAnimation(.easeOut(duration: 0.6).delay(3.0)) {
                showContinue = true
            }

            // Gentle pulse on continue hint
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(3.5)) {
                continuePulse = true
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
