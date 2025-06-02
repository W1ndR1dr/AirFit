import SwiftUI

/// A reusable view for presenting errors to users with recovery options
struct ErrorPresentationView: View {
    // MARK: - Properties
    let error: Error
    let style: ErrorStyle
    let retryAction: (() async -> Void)?
    let dismissAction: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isRetrying = false
    
    // MARK: - Error Style
    enum ErrorStyle {
        case inline
        case card
        case fullScreen
        case toast
        
        var backgroundColor: Color {
            switch self {
            case .inline:
                return Color("ErrorColor").opacity(0.1)
            case .card:
                return Color("CardBackground")
            case .fullScreen:
                return Color("BackgroundPrimary")
            case .toast:
                return Color("BackgroundTertiary")
            }
        }
    }
    
    // MARK: - Initialization
    init(
        error: Error,
        style: ErrorStyle = .card,
        retryAction: (() async -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.error = error
        self.style = style
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch style {
            case .inline:
                inlineView
            case .card:
                cardView
            case .fullScreen:
                fullScreenView
            case .toast:
                toastView
            }
        }
    }
    
    // MARK: - View Styles
    
    private var inlineView: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: errorIcon)
                .foregroundColor(Color("ErrorColor"))
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(errorTitle)
                    .font(AppFonts.caption)
                    .foregroundColor(Color("TextPrimary"))
                
                if let suggestion = recoverySuggestion {
                    Text(suggestion)
                        .font(AppFonts.footnote)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            
            Spacer()
            
            if retryAction != nil {
                retryButton
            }
        }
        .padding(AppSpacing.medium)
        .background(style.backgroundColor)
        .cornerRadius(AppSpacing.small)
    }
    
    private var cardView: some View {
        VStack(spacing: AppSpacing.medium) {
            // Icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(Color("ErrorColor"))
                .padding(.top, AppSpacing.medium)
            
            // Title
            Text(errorTitle)
                .font(AppFonts.title3)
                .foregroundColor(Color("TextPrimary"))
                .multilineTextAlignment(.center)
            
            // Message
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(AppFonts.body)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.medium)
            }
            
            // Actions
            HStack(spacing: AppSpacing.medium) {
                if let dismissAction = dismissAction {
                    Button("Dismiss") {
                        dismissAction()
                    }
                    .buttonStyle(.secondary)
                }
                
                if retryAction != nil {
                    retryButton
                        .buttonStyle(.primary)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.medium)
        }
        .frame(maxWidth: 350)
        .background(style.backgroundColor)
        .cornerRadius(AppSpacing.medium)
        .shadow(style: .elevated)
    }
    
    private var fullScreenView: some View {
        VStack(spacing: AppSpacing.xLarge) {
            Spacer()
            
            // Icon
            Image(systemName: errorIcon)
                .font(.system(size: 80))
                .foregroundColor(Color("ErrorColor"))
                .padding(.bottom, AppSpacing.medium)
            
            // Title
            Text(errorTitle)
                .font(AppFonts.largeTitle)
                .foregroundColor(Color("TextPrimary"))
                .multilineTextAlignment(.center)
            
            // Message
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(AppFonts.title3)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xLarge)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: AppSpacing.medium) {
                if retryAction != nil {
                    retryButton
                        .buttonStyle(.primary)
                        .controlSize(.large)
                }
                
                if let dismissAction = dismissAction {
                    Button("Go Back") {
                        dismissAction()
                    }
                    .buttonStyle(.secondary)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(style.backgroundColor)
    }
    
    private var toastView: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: errorIcon)
                .foregroundColor(Color("ErrorColor"))
                .font(.system(size: 20))
            
            Text(errorTitle)
                .font(AppFonts.callout)
                .foregroundColor(Color("TextPrimary"))
                .lineLimit(2)
            
            Spacer()
            
            if dismissAction != nil {
                Button {
                    dismissAction?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(style.backgroundColor)
        .cornerRadius(AppSpacing.medium)
        .shadow(style: .subtle)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Components
    
    private var retryButton: some View {
        Button {
            Task {
                isRetrying = true
                await retryAction?()
                isRetrying = false
            }
        } label: {
            if isRetrying {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            } else {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .disabled(isRetrying)
    }
    
    // MARK: - Computed Properties
    
    private var errorTitle: String {
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription ?? "Something went wrong"
        } else if let appError = error as? AppError {
            return appError.userFriendlyMessage
        } else {
            return "An error occurred"
        }
    }
    
    private var recoverySuggestion: String? {
        if let localizedError = error as? LocalizedError {
            return localizedError.recoverySuggestion
        } else if let appError = error as? AppError {
            return appError.recoverySuggestion
        } else {
            return "Please try again or contact support if the issue persists."
        }
    }
    
    private var errorIcon: String {
        if error is NetworkError {
            return "wifi.exclamationmark"
        } else if let appError = error as? AppError {
            switch appError {
            case .networkError:
                return "wifi.exclamationmark"
            case .authenticationError:
                return "person.crop.circle.badge.exclamationmark"
            case .dataError:
                return "externaldrive.badge.exclamationmark"
            case .validationError:
                return "exclamationmark.triangle"
            case .serverError:
                return "server.rack"
            case .unknown:
                return "exclamationmark.circle"
            }
        } else {
            return "exclamationmark.circle"
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Presents an error as an overlay
    func errorOverlay(
        error: Binding<Error?>,
        style: ErrorPresentationView.ErrorStyle = .card,
        retryAction: (() async -> Void)? = nil
    ) -> some View {
        self.overlay(
            Group {
                if let error = error.wrappedValue {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            error.wrappedValue = nil
                        }
                    
                    ErrorPresentationView(
                        error: error,
                        style: style,
                        retryAction: retryAction,
                        dismissAction: {
                            error.wrappedValue = nil
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: error.wrappedValue != nil)
        )
    }
    
    /// Presents an error as a toast
    func errorToast(
        error: Binding<Error?>,
        duration: TimeInterval = 4.0
    ) -> some View {
        self.overlay(
            VStack {
                if let error = error.wrappedValue {
                    ErrorPresentationView(
                        error: error,
                        style: .toast,
                        dismissAction: {
                            error.wrappedValue = nil
                        }
                    )
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.top, AppSpacing.large)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            error.wrappedValue = nil
                        }
                    }
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: error.wrappedValue != nil)
        )
    }
}

// MARK: - AppError Extension

extension AppError {
    var userFriendlyMessage: String {
        switch self {
        case .networkError(let message):
            return message ?? "Network connection error"
        case .authenticationError(let message):
            return message ?? "Authentication failed"
        case .dataError(let message):
            return message ?? "Data error occurred"
        case .validationError(let message):
            return message ?? "Invalid input"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .unknown(let message):
            return message ?? "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please sign in again to continue."
        case .dataError:
            return "There was an issue with your data. Please try again."
        case .validationError:
            return "Please check your input and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .unknown:
            return "Please try again. If the issue persists, contact support."
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ErrorPresentationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Inline style
            ErrorPresentationView(
                error: NetworkError.noConnection,
                style: .inline,
                retryAction: { }
            )
            
            // Card style
            ErrorPresentationView(
                error: AppError.networkError("Unable to connect to server"),
                style: .card,
                retryAction: { },
                dismissAction: { }
            )
            
            // Toast style
            ErrorPresentationView(
                error: AppError.validationError("Invalid email format"),
                style: .toast,
                dismissAction: { }
            )
        }
        .padding()
        .background(Color("BackgroundPrimary"))
        
        // Full screen style
        ErrorPresentationView(
            error: AppError.serverError(500, "Internal server error"),
            style: .fullScreen,
            retryAction: { },
            dismissAction: { }
        )
    }
}
#endif