import SwiftUI

// MARK: - Onboarding Completion View

struct OnboardingCompletionView: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showButton = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent tap-through

            // Content card
            VStack(spacing: 32) {
                Spacer()

                // Success icon with glow
                ZStack {
                    Circle()
                        .fill(Theme.success.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Circle()
                        .fill(Theme.success.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("I've learned about your goals and style.\nLet's crush it together.")
                        .font(.bodyLarge)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // CTA
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Let's Go")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())
                .padding(.horizontal, 24)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
            }
            .padding(.horizontal, 24)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 30)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(duration: 0.6)) {
                showContent = true
            }

            withAnimation(.spring(duration: 0.5).delay(0.4)) {
                showButton = true
            }

            // Show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }
}

#Preview {
    OnboardingCompletionView(onContinue: {})
}
