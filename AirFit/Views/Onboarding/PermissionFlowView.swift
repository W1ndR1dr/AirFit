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
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Theme.accent : Theme.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == currentPage ? 1.0 : 0.8)
                    }
                }
                .padding(.top, 16)
                .animation(.bloom, value: currentPage)

                TabView(selection: $currentPage) {
                    HealthKitPermissionPage(
                        onComplete: { withAnimation(.bloom) { currentPage = 1 } },
                        onSkip: { withAnimation(.bloom) { currentPage = 1 } }
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

    @State private var showIcon = false
    @State private var showContent = false
    @State private var showCTAs = false
    @State private var iconPulse = false
    @State private var isRequesting = false
    @State private var isAuthorized = false
    @State private var loadingPhase = 0
    @State private var loadingTimer: Timer?

    // Keep a strong reference to prevent deallocation during async authorization
    @State private var healthKitManager: HealthKitManager?

    private let loadingPhases = [
        "Opening HealthKit...",
        "Requesting access...",
        "Syncing data types...",
        "Almost there..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon with glow effect
            ZStack {
                // Outer glow - pulses during loading, settles when authorized
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isAuthorized ? Color.green : Theme.accent).opacity(isRequesting ? 0.6 : (isAuthorized ? 0.5 : 0.4)),
                                (isAuthorized ? Color.green : Theme.accent).opacity(isRequesting ? 0.2 : 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: isRequesting ? 100 : 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAuthorized ? 1.0 : (iconPulse ? 1.1 : 1.0))

                // Spinning ring when loading
                if isRequesting {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(iconPulse ? 360 : 0))
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: iconPulse)
                }

                // Success ring when authorized
                if isAuthorized {
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .transition(.scale.combined(with: .opacity))
                }

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isAuthorized
                                ? [Color.green.opacity(0.15), Color.green.opacity(0.08)]
                                : [Theme.accent.opacity(0.15), Theme.warmPeach.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Icon - shows checkmark when authorized
                if isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent, Theme.warmPeach],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating, isActive: isRequesting)
                }
            }
            .opacity(showIcon ? 1 : 0)
            .scaleEffect(showIcon ? 1 : 0.7)
            .animation(.spring(response: 0.5), value: isAuthorized)

            Spacer()
                .frame(height: 44)

            // Title & Description
            VStack(spacing: 18) {
                Text("Coaching That\nActually Knows You")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("AirFit reads your workouts, recovery, and body composition to tailor your training. Food you log gets saved to HealthKit too—keeping everything in Apple's secure health ecosystem.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            // CTAs
            VStack(spacing: 16) {
                PermissionButton(
                    icon: "heart.fill",
                    title: "Connect HealthKit",
                    isLoading: isRequesting,
                    loadingText: loadingPhases[loadingPhase],
                    action: requestHealthKit
                )

                Button(action: onSkip) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }
                .opacity(isRequesting ? 0.3 : 1.0)
                .disabled(isRequesting)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 16)
            }
            .opacity(showCTAs ? 1 : 0)
            .offset(y: showCTAs ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showCTAs = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.8)) {
                iconPulse = true
            }
        }
        .onDisappear {
            loadingTimer?.invalidate()
        }
    }

    private func requestHealthKit() {
        isRequesting = true
        loadingPhase = 0

        // Create and store a strong reference to prevent deallocation during async authorization
        let manager = HealthKitManager()
        healthKitManager = manager

        // Start cycling through loading phases
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [self] _ in
            Task { @MainActor in
                withAnimation(.spring(response: 0.3)) {
                    loadingPhase = (loadingPhase + 1) % loadingPhases.count
                }
            }
        }

        Task {
            // Use the stored reference (not a new instance)
            let _ = await manager.requestAuthorization()

            await MainActor.run {
                loadingTimer?.invalidate()
                isRequesting = false

                // Show success state with animated checkmark
                withAnimation(.spring(response: 0.5)) {
                    isAuthorized = true
                }
            }

            // Brief pause to show success, then advance
            try? await Task.sleep(for: .milliseconds(800))

            await MainActor.run {
                onComplete()
            }
        }
    }
}

// MARK: - Network Permission Page

struct NetworkPermissionPage: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var showIcon = false
    @State private var showContent = false
    @State private var showCTAs = false
    @State private var iconPulse = false
    @State private var isConnecting = false

    private let apiClient = APIClient()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon with glow effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.protein.opacity(0.4), Theme.protein.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(iconPulse ? 1.1 : 1.0)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.protein.opacity(0.15), Theme.tertiary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.protein, Theme.tertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(showIcon ? 1 : 0)
            .scaleEffect(showIcon ? 1 : 0.7)

            Spacer()
                .frame(height: 44)

            // Title & Description
            VStack(spacing: 18) {
                Text("Connect to\nYour Coach")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("Allow network access so your AI coach can provide personalized guidance and help you reach your goals.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            // CTAs
            VStack(spacing: 16) {
                PermissionButton(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Connect",
                    isLoading: isConnecting,
                    action: triggerNetworkPermission
                )

                Button(action: onSkip) {
                    Text("Skip")
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showCTAs = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.8)) {
                iconPulse = true
            }
        }
    }

    private func triggerNetworkPermission() {
        isConnecting = true
        Task {
            let _ = await apiClient.checkHealth()
            try? await Task.sleep(for: .seconds(1.5))
            let _ = await apiClient.checkHealth()

            await MainActor.run {
                isConnecting = false
                onComplete()
            }
        }
    }
}

// MARK: - Permission Button (Reusable)

struct PermissionButton: View {
    let icon: String
    let title: String
    let isLoading: Bool
    var loadingText: String = "Connecting..."
    let action: () -> Void

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    // Animated icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .symbolEffect(.pulse.byLayer, options: .repeating)

                    Text(loadingText)
                        .contentTransition(.numericText())
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    Theme.accentGradient

                    // Shimmer overlay when loading
                    if isLoading {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .white.opacity(0.5),
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
                            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0.5)
                        )
                    } else {
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(color: Theme.accent.opacity(isLoading ? 0.5 : 0.3), radius: isLoading ? 16 : 12, y: 6)
            .scaleEffect(isLoading ? 1.02 : 1.0)
        }
        .buttonStyle(AirFitButtonStyle())
        .disabled(isLoading)
        .animation(.spring(response: 0.4), value: isLoading)
        .onChange(of: isLoading) { _, loading in
            if loading {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
            } else {
                shimmerOffset = -1
            }
        }
    }
}

// MARK: - Animated Loading Button (Enhanced)

struct HealthKitLoadingView: View {
    @State private var currentPhase = 0
    @State private var pulseScale: CGFloat = 1.0

    private let phases = [
        "Opening HealthKit...",
        "Preparing permissions...",
        "Almost there..."
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Animated heart with rings
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Theme.accent.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(i * 20), height: 80 + CGFloat(i * 20))
                        .scaleEffect(pulseScale + CGFloat(i) * 0.1)
                }

                // Heart icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }

            // Phase text
            Text(phases[currentPhase])
                .font(.bodyLarge)
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText())
                .animation(.spring, value: currentPhase)
        }
        .onAppear {
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }

            // Cycle through phases
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [self] timer in
                Task { @MainActor in
                    withAnimation {
                        currentPhase = (currentPhase + 1) % phases.count
                    }
                }
            }
        }
    }
}

#Preview {
    PermissionFlowView(onComplete: {})
}
