import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    let onContinue: () -> Void
    let onReturningUser: () -> Void

    @State private var showHero = false
    @State private var showFeatures = [false, false, false]
    @State private var showCTAs = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero section with editorial typography
                VStack(spacing: 20) {
                    // Headline with warm glow behind
                    ZStack {
                        // Soft glow behind headline
                        Text("Stop tracking.")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.accent.opacity(0.4))
                            .blur(radius: 20)
                            .scaleEffect(glowPulse ? 1.05 : 1.0)

                        VStack(spacing: 4) {
                            Text("Stop tracking.")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                                .foregroundStyle(Theme.textPrimary)

                            Text("Start talking.")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.warmPeach],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .multilineTextAlignment(.center)

                    Text("A fitness coach that learns from how you naturally speak.")
                        .font(.bodyLarge)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)
                .opacity(showHero ? 1 : 0)
                .offset(y: showHero ? 0 : 30)

                Spacer()
                    .frame(height: 56)

                // Feature rows with elevated design
                VStack(spacing: 20) {
                    WelcomeFeatureRow(
                        icon: "text.bubble.fill",
                        iconColors: [Theme.accent, Theme.warmPeach],
                        title: "Just Talk to It",
                        description: "Log food by typing 'eggs and toast.' It figures out the rest."
                    )
                    .opacity(showFeatures[0] ? 1 : 0)
                    .offset(x: showFeatures[0] ? 0 : -20)

                    WelcomeFeatureRow(
                        icon: "brain.head.profile",
                        iconColors: [Theme.tertiary, Theme.accent],
                        title: "Remembers Everything",
                        description: "90 days of context in every response. No repeating yourself."
                    )
                    .opacity(showFeatures[1] ? 1 : 0)
                    .offset(x: showFeatures[1] ? 0 : -20)

                    WelcomeFeatureRow(
                        icon: "scope",
                        iconColors: [Theme.secondary, Theme.tertiary],
                        title: "Finds What You Miss",
                        description: "Spots patterns across sleep, food, and training automatically."
                    )
                    .opacity(showFeatures[2] ? 1 : 0)
                    .offset(x: showFeatures[2] ? 0 : -20)
                }
                .padding(.horizontal, 24)

                Spacer()

                // CTAs with premium styling
                VStack(spacing: 16) {
                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                // Gradient background
                                Theme.accentGradient

                                // Subtle inner glow at top
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            }
                        )
                        .clipShape(Capsule())
                        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 6)
                    }
                    .buttonStyle(AirFitButtonStyle())

                    Button(action: onReturningUser) {
                        Text("I've used this before")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 16)
                }
                .opacity(showCTAs ? 1 : 0)
                .offset(y: showCTAs ? 0 : 20)
            }
        }
        .onAppear {
            // Staggered animations with Bloom timing
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                showHero = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showFeatures[0] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.42)) {
                showFeatures[1] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.54)) {
                showFeatures[2] = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.66)) {
                showCTAs = true
            }

            // Subtle glow pulse
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Welcome Feature Row (Elevated Design)

struct WelcomeFeatureRow: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                // Soft outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [iconColors[0].opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)

                // Main icon container
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColors[0].opacity(0.15), iconColors[1].opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    WelcomeView(onContinue: {}, onReturningUser: {})
}
