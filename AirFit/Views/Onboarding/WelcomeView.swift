import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    let onContinue: () -> Void
    let onReturningUser: () -> Void

    @State private var showHero = false
    @State private var showFeatures = [false, false, false]
    @State private var showCTAs = false

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero section
                VStack(spacing: 12) {
                    Text("Your AI Fitness Coach")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Personalized guidance that learns and adapts to you")
                        .font(.bodyLarge)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .opacity(showHero ? 1 : 0)
                .offset(y: showHero ? 0 : 20)

                Spacer()
                    .frame(height: 48)

                // Feature rows with staggered animation
                VStack(spacing: 24) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Learns Your Style",
                        description: "Adapts to your goals and preferences"
                    )
                    .opacity(showFeatures[0] ? 1 : 0)
                    .offset(y: showFeatures[0] ? 0 : 20)

                    FeatureRow(
                        icon: "fork.knife",
                        title: "Effortless Tracking",
                        description: "Natural language nutrition logging"
                    )
                    .opacity(showFeatures[1] ? 1 : 0)
                    .offset(y: showFeatures[1] ? 0 : 20)

                    FeatureRow(
                        icon: "sparkles",
                        title: "Smart Insights",
                        description: "AI-powered analysis of your progress"
                    )
                    .opacity(showFeatures[2] ? 1 : 0)
                    .offset(y: showFeatures[2] ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer()

                // CTAs
                VStack(spacing: 16) {
                    Button(action: onContinue) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(AirFitButtonStyle())

                    Button(action: onReturningUser) {
                        Text("I've used this before")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 20)
                }
                .opacity(showCTAs ? 1 : 0)
                .offset(y: showCTAs ? 0 : 20)
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                showHero = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                showFeatures[0] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                showFeatures[1] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                showFeatures[2] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
                showCTAs = true
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onContinue: {}, onReturningUser: {})
}
