import SwiftUI
import Observation

// MARK: - GeneratingCoachView
struct GeneratingCoachView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var gradientRotation: Double = 0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private let steps: [(String, String)] = [
        ("Analyzing your unique preferences…", "brain.head.profile"),
        ("Defining your coach's core communication style…", "text.bubble.fill"),
        ("Aligning with your daily rhythm and schedule…", "clock.fill"),
        ("Calibrating motivational approach…", "star.fill"),
        ("Finalizing your personalized AirFit Coach profile…", "checkmark.seal.fill")
    ]

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title with cascade animation
                if animateIn {
                    CascadeText("Crafting Your AirFit Coach")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.xl)
                        .padding(.horizontal, AppSpacing.screenPadding)
                }
                
                Spacer()

                // Animated gradient circle
                ZStack {
                    // Background rotating gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    gradientManager.active == .peachRose ? Color.pink : Color.blue,
                                    gradientManager.active == .peachRose ? Color.orange : Color.purple,
                                    gradientManager.active == .peachRose ? Color.pink : Color.blue
                                ]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(gradientRotation))
                        .opacity(0.8)
                    
                    // Progress circle
                    CircularProgress(progress: Double(currentStep) / Double(steps.count))
                        .frame(width: 100, height: 100)
                    
                    // Center icon
                    if currentStep > 0 && currentStep <= steps.count {
                        Image(systemName: steps[currentStep - 1].1)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)
                .padding(.vertical, AppSpacing.xl)

                // Steps list with glass cards
                VStack(spacing: AppSpacing.sm) {
                    ForEach(steps.indices, id: \.self) { index in
                        StepRow(
                            text: steps[index].0,
                            icon: steps[index].1,
                            isActive: index < currentStep,
                            isCurrent: index == currentStep - 1
                        )
                        .opacity(animateIn ? 1 : 0)
                        .offset(x: animateIn ? 0 : -50)
                        .animation(
                            MotionToken.standardSpring.delay(Double(index) * 0.1),
                            value: animateIn
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
            startGeneration()
            startGradientRotation()
        }
        .accessibilityIdentifier("onboarding.generatingCoach")
    }

    private func startGeneration() {
        Task {
            // Initial delay for entrance animation
            try? await Task.sleep(for: .milliseconds(800))
            
            for step in 1...steps.count {
                await MainActor.run {
                    withAnimation(MotionToken.standardSpring) {
                        currentStep = step
                    }
                    HapticService.impact(.light)
                }
                
                // Varying delays for more natural feel
                let delay = step == steps.count ? 1200 : Int.random(in: 800...1400)
                try? await Task.sleep(for: .milliseconds(delay))
            }

            // Final celebration haptic
            await MainActor.run {
                HapticService.notification(.success)
            }
            
            // Small delay before navigation
            try? await Task.sleep(for: .milliseconds(500))
            
            // Navigate to the next screen
            viewModel.navigateToNext()
        }
    }
    
    private func startGradientRotation() {
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            gradientRotation = 360
        }
    }
}

// MARK: - CircularProgress
private struct CircularProgress: View {
    let progress: Double
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradientManager.currentGradient(for: colorScheme),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(MotionToken.standardSpring, value: progress)
    }
}

// MARK: - StepRow
private struct StepRow: View {
    let text: String
    let icon: String
    let isActive: Bool
    let isCurrent: Bool
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Icon with gradient when active
            Image(systemName: isActive ? "checkmark.circle.fill" : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    isActive ? AnyShapeStyle(gradientManager.currentGradient(for: colorScheme)) : AnyShapeStyle(Color.secondary.opacity(0.5))
                )
                .frame(width: 24, height: 24)
                .scaleEffect(isCurrent ? 1.2 : 1.0)
                .animation(MotionToken.standardSpring, value: isCurrent)
            
            Text(text)
                .font(.system(size: 16, weight: isCurrent ? .medium : .light))
                .foregroundColor(isActive ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.sm)
        .background(
            Group {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                }
            }
        )
        .scaleEffect(isCurrent ? 1.02 : 1.0)
        .animation(MotionToken.standardSpring, value: isCurrent)
    }
}
