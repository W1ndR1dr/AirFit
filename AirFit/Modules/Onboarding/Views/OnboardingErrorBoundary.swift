import SwiftUI

/// Error boundary view for onboarding flow - handles all error states gracefully
struct OnboardingErrorBoundary<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var showingFullError = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Main content
            content()
                .disabled(coordinator.isRecovering)
                .blur(radius: coordinator.isRecovering ? 3 : 0)
            
            // Recovery overlay
            if coordinator.isRecovering {
                RecoveryOverlay(message: coordinator.recoveryMessage)
            }
            
            // Error presentation
            if coordinator.error != nil {
                ErrorOverlay(
                    error: coordinator.error!,
                    isRecovering: coordinator.isRecovering,
                    onRetry: {
                        Task {
                            await coordinator.retryLastAction()
                        }
                    },
                    onDismiss: {
                        coordinator.clearError()
                    },
                    onShowDetails: {
                        showingFullError = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingFullError) {
            ErrorDetailsView(
                error: coordinator.error,
                onDismiss: {
                    showingFullError = false
                }
            )
        }
    }
}

// MARK: - Recovery Overlay

private struct RecoveryOverlay: View {
    let message: String?
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            // Animated recovery indicator
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Recovering...")
                .font(AppFonts.title3)
                .foregroundColor(.primary)
            
            if let message = message {
                Text(message)
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxLarge)
            }
        }
        .padding(AppSpacing.xxLarge)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
        )
    }
}

// MARK: - Error Overlay

private struct ErrorOverlay: View {
    let error: Error
    let isRecovering: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void
    let onShowDetails: () -> Void
    
    @State private var showingAnimation = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: AppSpacing.large) {
                // Error icon
                errorIcon
                    .font(.system(size: 48))
                    .foregroundColor(errorColor)
                    .scaleEffect(showingAnimation ? 1.0 : 0.8)
                    .opacity(showingAnimation ? 1.0 : 0.0)
                
                // Error title
                Text(errorTitle)
                    .font(AppFonts.title3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Error message
                Text(error.localizedDescription)
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, AppSpacing.medium)
                
                // Recovery suggestion
                if let suggestion = recoverySuggestion {
                    Text(suggestion)
                        .font(AppFonts.caption)
                        .foregroundColor(Color.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.medium)
                }
                
                // Actions
                HStack(spacing: AppSpacing.medium) {
                    if !isRecovering {
                        Button(action: {
                            HapticService.impact(.medium)
                            onRetry()
                        }) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Retry")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.2), radius: 8, y: 2)
                        }
                    }
                    
                    Button(action: {
                        HapticService.impact(.light)
                        onDismiss()
                    }) {
                        Text("Dismiss")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.05),
                                        Color.primary.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(action: onShowDetails) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.top, AppSpacing.small)
            }
            .padding(AppSpacing.xxLarge)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, AppSpacing.large)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring()) {
                showingAnimation = true
            }
            HapticService.play(.error)
        }
    }
    
    private var errorIcon: Image {
        switch error {
        case is NetworkError:
            return Image(systemName: "wifi.exclamationmark")
        case is PersonaError:
            return Image(systemName: "person.crop.circle.badge.exclamationmark")
        case is OnboardingError:
            return Image(systemName: "exclamationmark.triangle")
        default:
            return Image(systemName: "exclamationmark.circle")
        }
    }
    
    private var errorColor: Color {
        switch error {
        case is NetworkError:
            return Color.orange
        case is OnboardingError:
            return Color.blue
        default:
            return Color.red
        }
    }
    
    private var errorTitle: String {
        switch error {
        case is NetworkError:
            return "Connection Issue"
        case is PersonaError:
            return "Generation Failed"
        case is OnboardingError:
            return "Input Required"
        case is OnboardingError:
            return "Onboarding Error"
        default:
            return "Something Went Wrong"
        }
    }
    
    private var recoverySuggestion: String? {
        if let recoverableError = error as? RecoverableError {
            return recoverableError.recoverySuggestion
        }
        return nil
    }
}

// MARK: - Error Details View

private struct ErrorDetailsView: View {
    let error: Error?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    // Error type
                    ErrorDetailRow(
                        title: "Error Type",
                        value: String(describing: type(of: error ?? NSError()))
                    )
                    
                    // Description
                    ErrorDetailRow(
                        title: "Description",
                        value: error?.localizedDescription ?? "Unknown error"
                    )
                    
                    // Recovery suggestion
                    if let suggestion = (error as? RecoverableError)?.recoverySuggestion {
                        ErrorDetailRow(
                            title: "Recovery Suggestion",
                            value: suggestion
                        )
                    }
                    
                    // Debug info
                    if let debugDescription = (error as? CustomDebugStringConvertible)?.debugDescription {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Debug Information")
                                .font(AppFonts.caption)
                                .foregroundColor(.secondary)
                            
                            Text(debugDescription)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.7))
                                .padding(AppSpacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                    }
                }
                .padding(AppSpacing.large)
            }
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

private struct ErrorDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Protocol for recoverable errors

protocol RecoverableError: LocalizedError {
    // LocalizedError already provides recoverySuggestion
}

// Make our error types conform to RecoverableError
extension NetworkError: RecoverableError { }
extension PersonaError: RecoverableError { }
extension OnboardingError: RecoverableError { }