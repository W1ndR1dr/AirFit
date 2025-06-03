import SwiftUI

/// Error boundary view for onboarding flow - handles all error states gracefully
struct OnboardingErrorBoundary<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var showingFullError = false
    
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
                .foregroundColor(AppColors.accentColor)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Recovering...")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.textPrimary)
            
            if let message = message {
                Text(message)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxLarge)
            }
        }
        .padding(AppSpacing.xxLarge)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
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
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Error message
                Text(error.localizedDescription)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, AppSpacing.medium)
                
                // Recovery suggestion
                if let suggestion = recoverySuggestion {
                    Text(suggestion)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.medium)
                }
                
                // Actions
                HStack(spacing: AppSpacing.medium) {
                    if !isRecovering {
                        Button(action: onRetry) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(AppFonts.bodyBold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(AppFonts.body)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onShowDetails) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.top, AppSpacing.small)
            }
            .padding(AppSpacing.xxLarge)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.cardBackground)
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
            HapticManager.notification(.error)
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
            return AppColors.warningColor
        case is OnboardingError:
            return AppColors.infoColor
        default:
            return AppColors.errorColor
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
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(debugDescription)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(AppColors.textTertiary)
                                .padding(AppSpacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppColors.backgroundTertiary)
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
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
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