import SwiftUI

// MARK: - Permission Flow View

struct PermissionFlowView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots - respects safe area
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Theme.accent : Theme.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
                .animation(.easeInOut(duration: 0.2), value: currentPage)

                TabView(selection: $currentPage) {
                    HealthKitPermissionPage(
                        onComplete: { withAnimation { currentPage = 1 } },
                        onSkip: { withAnimation { currentPage = 1 } }
                    )
                    .tag(0)

                    NetworkPermissionPage(
                        onComplete: onComplete,
                        onSkip: onComplete
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}

// MARK: - HealthKit Permission Page

struct HealthKitPermissionPage: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
            }
            .opacity(isAnimating ? 1 : 0)
            .scaleEffect(isAnimating ? 1 : 0.8)

            Spacer()
                .frame(height: 40)

            // Title & Description
            VStack(spacing: 16) {
                Text("Connect Your Health Data")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("AirFit reads your workouts, steps, and body metrics to give personalized advice.\n\nWe never write to or modify your health data.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)

            Spacer()

            // CTAs
            VStack(spacing: 16) {
                Button(action: requestHealthKit) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "heart.fill")
                            Text("Allow HealthKit Access")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())
                .disabled(isRequesting)

                Button(action: onSkip) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 24)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 20)
            }
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    private func requestHealthKit() {
        isRequesting = true
        Task {
            let healthKit = HealthKitManager()
            let _ = await healthKit.requestAuthorization()
            await MainActor.run {
                isRequesting = false
                onComplete()
            }
        }
    }
}

// MARK: - Network Permission Page

struct NetworkPermissionPage: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.protein.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "network")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.protein)
            }
            .opacity(isAnimating ? 1 : 0)
            .scaleEffect(isAnimating ? 1 : 0.8)

            Spacer()
                .frame(height: 40)

            // Title & Description
            VStack(spacing: 16) {
                Text("Connect to Your Coach")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("AirFit runs on your local network for privacy. When prompted, allow local network access to connect to your AI coach.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)

            Spacer()

            // CTAs
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 24)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 20)
            }
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    PermissionFlowView(onComplete: {})
}
