import SwiftUI

/// Shows progress while loading HealthKit data
struct HealthDataLoadingView: View {
    @ObservedObject var intelligence: OnboardingIntelligence
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var iconScale: CGFloat = 1.0
    @State private var gradientRotation: Double = 0
    @State private var animationTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var gradientManager: GradientManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated health icon
            ZStack {
                // Rotating gradient circle
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                gradientManager.accent,
                                gradientManager.accent.opacity(0.5),
                                gradientManager.accent
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(gradientRotation))
                    .blur(radius: 20)
                    .opacity(0.6)
                
                // Health icon
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                gradientManager.accent,
                                gradientManager.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
                    .shadow(color: gradientManager.accent.opacity(0.3), radius: 20)
            }
            
            VStack(spacing: 16) {
                Text("Analyzing your health data")
                    .font(.system(size: 28, weight: .thin, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(intelligence.healthDataStatus)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(intelligence.healthDataStatus)
                    .frame(height: 20)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: intelligence.healthDataProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(gradientManager.accent)
                    .scaleEffect(y: 2)
                    .padding(.horizontal, 60)
                
                Text("\(Int(intelligence.healthDataProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                if intelligence.healthDataProgress >= 1.0 {
                    Button(action: onContinue) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: onSkip) {
                    Text("Skip for now")
                        .foregroundStyle(.secondary)
                }
                .opacity(intelligence.healthDataProgress < 1.0 ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            if !reduceMotion {
                // Start animations in a cancellable task
                animationTask = Task { @MainActor in
                    // Icon pulsing animation
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        iconScale = 1.1
                    }
                    
                    // Gradient rotation animation
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        gradientRotation = 360
                    }
                }
            }
        }
        .onDisappear {
            // Cancel animations when view disappears
            animationTask?.cancel()
            animationTask = nil
            
            // Reset animation states
            iconScale = 1.0
            gradientRotation = 0
        }
    }
}