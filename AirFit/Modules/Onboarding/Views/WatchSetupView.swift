import SwiftUI
import WatchConnectivity

/// Beautiful Watch setup view for onboarding
struct WatchSetupView: View {
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    let onSetupWatch: () -> Void
    let onSkip: () -> Void
    
    @State private var watchIconScale: CGFloat = 1.0
    @State private var watchIconRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showFeatures = false
    @State private var showingWatchAppStore = false
    
    private let features = [
        (icon: "figure.run", title: "Start Workouts", description: "Begin and track workouts directly from your wrist"),
        (icon: "chart.line.uptrend.xyaxis", title: "Live Metrics", description: "See real-time heart rate and calories burned"),
        (icon: "checkmark.circle", title: "Quick Logging", description: "Log exercises with just a few taps"),
        (icon: "bell", title: "Smart Reminders", description: "Get timely notifications for rest and hydration")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Watch Icon Animation
            ZStack {
                // Pulse effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradientManager.active.colors(for: colorScheme)[0].opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .animation(
                        reduceMotion ? nil :
                        Animation.easeOut(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: pulseScale
                    )
                
                // Watch icon
                Image(systemName: "applewatch")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(watchIconScale)
                    .rotationEffect(.degrees(watchIconRotation))
                    .animation(
                        reduceMotion ? nil :
                        Animation.spring(response: 0.8, dampingFraction: 0.6),
                        value: watchIconScale
                    )
            }
            .frame(height: 240)
            .onAppear {
                if !reduceMotion {
                    pulseScale = 1.5
                    watchIconScale = 1.1
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        watchIconRotation = 10
                    }
                }
            }
            
            VStack(spacing: AppSpacing.lg) {
                // Title with cascade animation
                CascadeText("Track from\nyour wrist")
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppSpacing.xs)
                
                // Subtitle
                Text("Get the full AirFit experience with Apple Watch")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0)
                    .cascadeIn(delay: 0.3)
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            // Features list (animated)
            if showFeatures {
                VStack(spacing: AppSpacing.md) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text(feature.description)
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                        .opacity(0)
                        .cascadeIn(delay: 0.5 + Double(index) * 0.1)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: AppSpacing.md) {
                if watchManager.isCheckingStatus {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking Watch status...")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 56)
                } else if watchManager.isPaired && watchManager.isAppInstalled {
                    // Watch app is already installed
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Apple Watch app installed")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        
                        Button(action: onSetupWatch) {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                } else if watchManager.isPaired && !watchManager.isAppInstalled {
                    // Watch is paired but app not installed
                    Button(action: {
                        showingWatchAppStore = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.app")
                            Text("Install Watch App")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else {
                    // No Watch paired
                    VStack(spacing: AppSpacing.sm) {
                        Text("No Apple Watch detected")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.secondary)
                        
                        Button(action: onSkip) {
                            Text("Set up later")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(Material.regular)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                
                // Skip option (always available)
                if !watchManager.isCheckingStatus && !(watchManager.isPaired && watchManager.isAppInstalled) {
                    Button(action: onSkip) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .onAppear {
            watchManager.checkWatchStatus()
            
            // Show features after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showFeatures = true
                }
            }
        }
        .sheet(isPresented: $showingWatchAppStore) {
            WatchAppStoreView(
                onDismiss: {
                    showingWatchAppStore = false
                    // Recheck status after dismissal
                    watchManager.checkWatchStatus()
                }
            )
        }
    }
}

// MARK: - Watch App Store View
private struct WatchAppStoreView: View {
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "applewatch.and.arrow.forward")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Text("Install from Apple Watch")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Open the Apple Watch app on your iPhone, then:\n\n1. Go to the \"Available Apps\" section\n2. Find AirFit\n3. Tap \"Install\"")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Watch App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    WatchSetupView(
        onSetupWatch: {
            print("Watch setup completed")
        },
        onSkip: {
            print("Watch setup skipped")
        }
    )
    .environmentObject(GradientManager())
}