import SwiftUI
import HealthKit

struct HealthKitAuthorizationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false
    @State private var showDataPreview = false
    @State private var isAuthorizing = false
    
    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        viewModel.navigateToPrevious()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.primary.opacity(0.3))
                    }
                    .padding(.leading, AppSpacing.screenPadding)
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Main content
                VStack(spacing: AppSpacing.lg) {
                    // Icon
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
                    
                    // Title with cascade animation
                    if animateIn {
                        CascadeText("Now, let's sync your health data")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Subtitle
                    Text("This helps me understand your baseline")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(.primary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).delay(0.5), value: animateIn)
                }
                
                Spacer()
                
                // Data preview or action button
                VStack(spacing: AppSpacing.md) {
                    if showDataPreview {
                        // Data preview card
                        VStack(spacing: AppSpacing.sm) {
                            Text("Great! Here's what I found:")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if let healthData = viewModel.healthKitData {
                                HealthDataPreviewView(data: healthData)
                                    .padding(.vertical, AppSpacing.xs)
                            } else {
                                Text("Let's start with the basics")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(.secondary)
                                
                                if let weight = viewModel.currentWeight {
                                    Text("Weight: \(Int(weight)) lbs")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .transition(.scale.combined(with: .opacity))
                    } else if viewModel.healthKitAuthorizationStatus == .denied {
                        // No HealthKit access
                        VStack(spacing: AppSpacing.xs) {
                            Text("No problem, we'll figure it out together")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .transition(.opacity)
                    }
                    
                    // Action button
                    Button {
                        if viewModel.healthKitAuthorizationStatus == .notDetermined {
                            requestHealthKitAccess()
                        } else {
                            viewModel.navigateToNext()
                        }
                    } label: {
                        HStack {
                            if isAuthorizing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(buttonTitle)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear,
                                radius: 8, x: 0, y: 4)
                    }
                    .disabled(isAuthorizing)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Skip option
                    if viewModel.healthKitAuthorizationStatus == .notDetermined {
                        Button {
                            viewModel.navigateToNext()
                        } label: {
                            Text("Skip for now")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 60)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
            }
        }
        .onAppear {
            animateIn = true
            
            // Check if we already have authorization
            if viewModel.healthKitAuthorizationStatus == .authorized {
                showDataPreview = true
            }
        }
    }
    
    private var buttonTitle: String {
        switch viewModel.healthKitAuthorizationStatus {
        case .notDetermined:
            return "Connect Apple Health"
        case .authorized:
            return showDataPreview ? "Continue" : "View My Data"
        case .denied:
            return "Continue without Health data"
        }
    }
    
    private func requestHealthKitAccess() {
        isAuthorizing = true
        HapticService.impact(.light)
        
        Task {
            await viewModel.requestHealthKitAuthorization()
            
            await MainActor.run {
                isAuthorizing = false
                
                if viewModel.healthKitAuthorizationStatus == .authorized {
                    withAnimation(.spring()) {
                        showDataPreview = true
                    }
                    HapticService.notification(.success)
                } else if viewModel.healthKitAuthorizationStatus == .denied {
                    HapticService.notification(.warning)
                }
            }
        }
    }
}

// MARK: - Health Data Preview
struct HealthDataPreviewView: View {
    let data: HealthKitSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let weight = data.weight {
                DataRow(label: "Weight", value: "\(Int(weight)) lbs")
            }
            
            if let height = data.height {
                let feet = Int(height) / 12
                let inches = Int(height) % 12
                DataRow(label: "Height", value: "\(feet)' \(inches)\"")
            }
            
            if let age = data.age {
                DataRow(label: "Age", value: "\(age) years")
            }
            
            // Additional data could be shown here
            if let sleep = data.sleepSchedule {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                DataRow(label: "Sleep", value: "\(formatter.string(from: sleep.bedtime)) - \(formatter.string(from: sleep.waketime))")
            }
        }
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}