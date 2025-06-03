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
                    .buttonStyle(.bordered)
                }
                
                if retryAction != nil {
                    retryButton
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.medium)
        }
        .frame(maxWidth: 350)
        .background(style.backgroundColor)
        .cornerRadius(AppSpacing.medium)
        .shadow(radius: AppSpacing.small)
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
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
                
                if let dismissAction = dismissAction {
                    Button("Go Back") {
                        dismissAction()
                    }
                    .buttonStyle(.bordered)
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
        .shadow(radius: 2)
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
        if let appError = error as? AppError {
            switch appError {
            case .networkError:
                return "wifi.exclamationmark"
            case .unauthorized:
                return "person.crop.circle.badge.exclamationmark"
            case .decodingError:
                return "externaldrive.badge.exclamationmark"
            case .validationError:
                return "exclamationmark.triangle"
            case .serverError:
                return "server.rack"
            case .unknown:
                return "exclamationmark.circle"
            case .healthKitNotAuthorized:
                return "heart.text.square"
            case .cameraNotAuthorized:
                return "camera.badge.exclamationmark"
            case .userNotFound:
                return "person.crop.circle.badge.questionmark"
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
                if let errorValue = error.wrappedValue {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            error.wrappedValue = nil
                        }
                    
                    ErrorPresentationView(
                        error: errorValue,
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
                if let errorValue = error.wrappedValue {
                    ErrorPresentationView(
                        error: errorValue,
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
    var icon: String {
        switch self {
        case .networkError:
            return "wifi.exclamationmark"
        case .unauthorized:
            return "lock.circle"
        case .validationError:
            return "exclamationmark.triangle"
        case .serverError:
            return "exclamationmark.icloud"
        default:
            return "exclamationmark.circle"
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
                error: NetworkError.networkError(NSError(domain: "Network", code: -1)),
                style: .inline,
                retryAction: { }
            )
            
            // Card style
            ErrorPresentationView(
                error: AppError.networkError(underlying: NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to connect to server"])),
                style: .card,
                retryAction: { },
                dismissAction: { }
            )
            
            // Toast style
            ErrorPresentationView(
                error: AppError.validationError(message: "Invalid email format"),
                style: .toast,
                dismissAction: { }
            )
        }
        .padding()
        .background(Color("BackgroundPrimary"))
        
        // Full screen style
        ErrorPresentationView(
            error: AppError.serverError(code: 500, message: "Internal server error"),
            style: .fullScreen,
            retryAction: { },
            dismissAction: { }
        )
    }
}
#endif