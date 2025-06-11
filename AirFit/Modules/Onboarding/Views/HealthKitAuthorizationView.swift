import SwiftUI
import SwiftData
import Observation

/// Placeholder view for HealthKit authorization during onboarding.
struct HealthKitAuthorizationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var heartBeat: CGFloat = 1.0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                // Glass card with health data preview
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        // Animated heart icon
                        ZStack {
                            Circle()
                                .fill(gradientManager.currentGradient(for: colorScheme))
                                .frame(width: 100, height: 100)
                                .opacity(0.2)
                                .scaleEffect(heartBeat * 1.2)
                                .blur(radius: 10)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                                .scaleEffect(heartBeat)
                        }
                        .frame(height: 120)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        
                        // Title with cascade
                        if animateIn {
                            CascadeText("Connect HealthKit")
                                .font(.system(size: 28, weight: .light, design: .rounded))
                        }
                        
                        Text("Allow AirFit to sync with your health data for personalized insights")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
                        
                        // Data types with icons
                        VStack(spacing: AppSpacing.sm) {
                            HealthDataRow(icon: "figure.walk", text: "Activity & Steps", delay: 0.3)
                            HealthDataRow(icon: "figure.run", text: "Workouts", delay: 0.4)
                            HealthDataRow(icon: "bed.double.fill", text: "Sleep Analysis", delay: 0.5)
                            HealthDataRow(icon: "heart.text.square", text: "Health Metrics", delay: 0.6)
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                // Authorization button
                StandardButton(
                    "Authorize HealthKit",
                    icon: "heart.circle.fill",
                    style: .primary,
                    isFullWidth: true
                ) {
                    Task { await viewModel.requestHealthKitAuthorization() }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.7), value: animateIn)
                .accessibilityIdentifier("onboarding.healthkit.authorize")
                
                // Skip option
                Button("Skip for now") {
                    HapticService.selection()
                    viewModel.navigateToNextScreen()
                }
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(0.8), value: animateIn)

                Spacer()

                // Error state
                if viewModel.healthKitAuthorizationStatus == .denied {
                    GlassCard {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text("Permission denied. You can enable access in Settings.")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
            startHeartBeatAnimation()
        }
    }
    
    private func startHeartBeatAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            heartBeat = 1.1
        }
    }
}

// MARK: - HealthDataRow
private struct HealthDataRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(.green.opacity(0.8))
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .opacity(animateIn ? 1 : 0)
        .offset(x: animateIn ? 0 : -20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(delay)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    // Simple preview without complex dependencies
    VStack(spacing: AppSpacing.lg) {
        Spacer()
        
        // Glass card with health data preview
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .opacity(0.2)
                    .blur(radius: 10)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .frame(height: 120)
            
            Text("Connect HealthKit")
                .font(.system(size: 28, weight: .light, design: .rounded))
            
            Text("Allow AirFit to sync with your health data for personalized insights")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        
        Button("Authorize HealthKit") {}
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .padding(.horizontal)
        
        Spacer()
    }
    .background(
        LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    )
}
