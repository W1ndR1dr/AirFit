import SwiftUI

/// A reusable view for presenting errors to users with recovery options
struct ErrorPresentationView: View {
    // MARK: - Properties
    let error: Error
    let style: ErrorStyle
    let retryAction: (() async -> Void)?
    let dismissAction: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @State private var isRetrying = false
    @State private var animateIn = false
    
    // MARK: - Error Style
    enum ErrorStyle {
        case inline
        case card
        case fullScreen
        case toast
        
        var needsGlassEffect: Bool {
            switch self {
            case .inline, .toast:
                return true
            case .card, .fullScreen:
                return false
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
                BaseScreen {
                    fullScreenView
                }
            case .toast:
                toastView
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
    
    // MARK: - View Styles
    
    private var inlineView: some View {
        GlassCard {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: errorIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(errorTitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    if let suggestion = recoverySuggestion {
                        Text(suggestion)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if retryAction != nil {
                    retryButton
                }
            }
        }
        .scaleEffect(animateIn ? 1 : 0.95)
        .opacity(animateIn ? 1 : 0)
    }
    
    private var cardView: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                // Icon with gradient
                Image(systemName: errorIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, AppSpacing.md)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
                
                // Title with cascade effect
                CascadeText(errorTitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                // Message
                if let suggestion = recoverySuggestion {
                    Text(suggestion)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
                }
                
                // Actions
                HStack(spacing: AppSpacing.md) {
                    if let dismissAction = dismissAction {
                        Button(action: {
                            HapticService.impact(.light)
                            dismissAction()
                        }, label: {
                            Text("Dismiss")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(minWidth: 100)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        })
                    }
                    
                    if retryAction != nil {
                        retryButtonStyled
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
            }
        }
        .frame(maxWidth: 350)
    }
    
    private var fullScreenView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Icon with animated gradient
            Image(systemName: errorIcon)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, AppSpacing.md)
                .scaleEffect(animateIn ? 1 : 0.5)
                .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
            
            // Title with cascade
            CascadeText(errorTitle)
                .font(.system(size: 34, weight: .thin, design: .rounded))
                .multilineTextAlignment(.center)
            
            // Message
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .opacity(animateIn ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: AppSpacing.md) {
                if retryAction != nil {
                    retryButtonLarge
                }
                
                if let dismissAction = dismissAction {
                    Button(action: {
                        HapticService.impact(.light)
                        dismissAction()
                    }, label: {
                        Text("Go Back")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    })
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
            .opacity(animateIn ? 1 : 0)
            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var toastView: some View {
        GlassCard {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: errorIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                
                Text(errorTitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                if dismissAction != nil {
                    Button(action: {
                        HapticService.impact(.soft)
                        dismissAction?()
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    })
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
    }
    
    // MARK: - Components
    
    private var retryButton: some View {
        Button(action: {
            HapticService.impact(.light)
            Task {
                isRetrying = true
                await retryAction?()
                isRetrying = false
            }
        }, label: {
            if isRetrying {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
        })
        .disabled(isRetrying)
    }
    
    private var retryButtonStyled: some View {
        Button(action: {
            HapticService.impact(.medium)
            Task {
                isRetrying = true
                await retryAction?()
                isRetrying = false
            }
        }, label: {
            HStack(spacing: AppSpacing.xs) {
                if isRetrying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Retry")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(.white)
            .frame(minWidth: 100)
            .padding(.vertical, AppSpacing.sm)
            .background(
                LinearGradient(
                    colors: gradientManager.active.colors(for: colorScheme),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 8, y: 4)
        })
        .disabled(isRetrying)
    }
    
    private var retryButtonLarge: some View {
        Button(action: {
            HapticService.impact(.medium)
            Task {
                isRetrying = true
                await retryAction?()
                isRetrying = false
            }
        }, label: {
            HStack(spacing: AppSpacing.sm) {
                if isRetrying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.0)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .medium))
                    Text("Try Again")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
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
            .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
        })
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
            case .unsupportedProvider:
                return "cpu.badge.exclamationmark"
            case .serviceUnavailable:
                return "network.badge.shield.half.filled"
            case .invalidInput:
                return "pencil.circle.badge.exclamationmark"
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
                            HapticService.impact(.soft)
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