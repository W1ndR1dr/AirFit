import Foundation

// MARK: - Error Handling Protocol

/// Standard protocol for ViewModels and Services that handle errors
@MainActor
protocol ErrorHandling: AnyObject {
    var error: AppError? { get set }
    var isShowingError: Bool { get set }

    /// Handles an error with proper conversion to AppError
    func handleError(_ error: Error)

    /// Clears the current error state
    func clearError()
}

// MARK: - Default Implementation

extension ErrorHandling {
    func handleError(_ error: Error) {
        // Convert to AppError using the centralized conversion
        if let appError = error as? AppError {
            self.error = appError
        } else if let aiError = error as? AIError {
            self.error = AppError.from(aiError)
        } else if let networkError = error as? NetworkError {
            self.error = AppError.from(networkError)
        } else if let serviceError = error as? ServiceError {
            self.error = AppError.from(serviceError)
        // WORKOUT TRACKING REMOVED
        // } else if let workoutError = error as? WorkoutError {
        //     self.error = AppError.from(workoutError)
        } else if let keychainError = error as? KeychainError {
            self.error = AppError.from(keychainError)
        } else if let coachError = error as? CoachEngineError {
            self.error = AppError.from(coachError)
        } else if let directAIError = error as? DirectAIError {
            self.error = AppError.from(directAIError)
        } else if let foodError = error as? FoodTrackingError {
            self.error = AppError.from(foodError)
        } else if let voiceError = error as? FoodVoiceError {
            self.error = AppError.from(voiceError)
        } else if let chatError = error as? ChatError {
            self.error = AppError.from(chatError)
        } else if let settingsError = error as? SettingsError {
            self.error = AppError.from(settingsError)
        } else if let conversationError = error as? ConversationManagerError {
            self.error = AppError.from(conversationError)
        } else if let personaEngineError = error as? PersonaEngineError {
            self.error = AppError.from(personaEngineError)
        } else if let personaError = error as? PersonaError {
            self.error = AppError.from(personaError)
        } else if let liveActivityError = error as? LiveActivityError {
            self.error = AppError.from(liveActivityError)
        } else {
            self.error = AppError.networkError(underlying: error)
        }

        self.isShowingError = true

        // Log the error
        AppLogger.error("Error handled", error: error, category: .app)
    }

    func clearError() {
        self.error = nil
        self.isShowingError = false
    }
}

// MARK: - Error Handling for Async Operations

extension ErrorHandling {
    /// Executes an async operation with automatic error handling
    func withErrorHandling<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            await MainActor.run {
                handleError(error)
            }
            return nil
        }
    }

    /// Executes an async operation with error handling and loading state
    func withErrorHandling<T: Sendable>(
        setLoading: @MainActor @escaping (Bool) -> Void,
        _ operation: @Sendable () async throws -> T
    ) async -> T? {
        await MainActor.run { setLoading(true) }
        defer { Task { @MainActor in setLoading(false) } }

        do {
            return try await operation()
        } catch {
            await MainActor.run {
                handleError(error)
            }
            return nil
        }
    }
}

// MARK: - Error Alert Modifier

import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $isPresented,
                presenting: error
            ) { error in
                if error.isRecoverable {
                    Button("Retry") {
                        onDismiss?()
                    }
                    Button("Cancel", role: .cancel) {
                        self.error = nil
                    }
                } else {
                    Button("OK", role: .cancel) {
                        self.error = nil
                    }
                }
            } message: { error in
                VStack {
                    Text(error.errorDescription ?? "An unknown error occurred")
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    /// Presents standardized error alerts
    func errorAlert(
        error: Binding<AppError?>,
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(
            error: error,
            isPresented: isPresented,
            onDismiss: onDismiss
        ))
    }
}

// MARK: - Service Error Handling

/// Standard error handling for services
protocol ServiceErrorHandling {
    /// Logs and rethrows errors as AppError
    func handleServiceError<T>(
        _ operation: () async throws -> T,
        context: String
    ) async throws -> T
}

extension ServiceErrorHandling {
    func handleServiceError<T>(
        _ operation: () async throws -> T,
        context: String
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.error("\(context) failed", error: error, category: .services)

            // Convert to AppError if needed
            if let appError = error as? AppError {
                throw appError
            } else {
                throw AppError.unknown(message: "\(context): \(error.localizedDescription)")
            }
        }
    }
}
