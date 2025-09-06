import SwiftUI

/// Error recovery view for onboarding failures
struct ErrorRecoveryView: View {
    let error: AppError
    let isRetrying: Bool
    let onRetry: () -> Void
    let onSkip: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundStyle(errorColor)
                .padding(.bottom, AppSpacing.sm)
            
            // Error title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Error message
            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xs)
            }
            
            // Action buttons
            VStack(spacing: AppSpacing.sm) {
                Button(action: onRetry) {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isRetrying)
                
                Button(action: onSkip) {
                    Text("Skip & Continue")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Material.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isRetrying)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
        }
        .padding(.vertical, AppSpacing.xl)
    }
    
    private var errorIcon: String {
        switch error {
        case .networkError:
            return "wifi.exclamationmark"
        case .unauthorized:
            return "lock.shield"
        case .serverError:
            return "exclamationmark.icloud"
        case .validationError:
            return "exclamationmark.triangle"
        default:
            return "exclamationmark.circle"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .networkError:
            return .orange
        case .unauthorized:
            return .red
        case .serverError:
            return .orange
        default:
            return .red
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .networkError:
            return "Connection Issue"
        case .unauthorized:
            return "Authentication Failed"
        case .serverError:
            return "Server Error"
        case .validationError:
            return "Invalid Input"
        case .llm:
            return "AI Service Error"
        default:
            return "Something Went Wrong"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ErrorRecoveryView(
            error: .networkError(underlying: URLError(.notConnectedToInternet)),
            isRetrying: false,
            onRetry: { print("Retry") },
            onSkip: { print("Skip") }
        )
        
        Divider()
        
        ErrorRecoveryView(
            error: .unauthorized,
            isRetrying: true,
            onRetry: { print("Retry") },
            onSkip: { print("Skip") }
        )
    }
}