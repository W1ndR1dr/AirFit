import Foundation

/// Shared retry handler for LLM providers
enum LLMRetryHandler {
    static let defaultMaxRetries = 3
    static let defaultBaseDelay: TimeInterval = 1.0
    static let maxDelay: TimeInterval = 60.0

    /// Execute an async operation with exponential backoff retry
    static func withRetry<T>(
        maxAttempts: Int = defaultMaxRetries,
        baseDelay: TimeInterval = defaultBaseDelay,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if error is retryable
                guard isRetryableError(error) else {
                    throw error
                }

                // Don't retry on the last attempt
                guard attempt < maxAttempts - 1 else {
                    break
                }

                // Calculate delay with exponential backoff
                let delay = calculateDelay(attempt: attempt, baseDelay: baseDelay, error: error)

                // Log retry attempt
                AppLogger.info(
                    "Retrying after \(String(format: "%.1f", delay))s (attempt \(attempt + 1)/\(maxAttempts))",
                    category: .ai
                )

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? AppError.from(LLMError.networkError(URLError(.unknown)))
    }

    /// Determine if an error should trigger a retry
    private static func isRetryableError(_ error: Error) -> Bool {
        // Check if it's already an AppError
        if let appError = error as? AppError {
            // Check for retryable app errors
            switch appError {
            case .networkError:
                return true
            case .serverError(let code, _):
                // Retry on 5xx errors or rate limit
                return code >= 500 && code < 600 || code == 429
            default:
                return false
            }
        }

        // Check for retryable LLM errors
        if let llmError = error as? LLMError {
            switch llmError {
            case .rateLimitExceeded, .timeout:
                return true
            case .networkError(let networkError):
                return isRetryableNetworkError(networkError)
            case .serverError(let statusCode, _):
                // Retry on 5xx errors
                return statusCode >= 500 && statusCode < 600
            default:
                return false
            }
        }

        // Check for retryable network errors
        if let urlError = error as? URLError {
            return isRetryableNetworkError(urlError)
        }

        return false
    }

    /// Check if a network error is retryable
    private static func isRetryableNetworkError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }

        switch urlError.code {
        case .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    /// Calculate delay with exponential backoff
    private static func calculateDelay(
        attempt: Int,
        baseDelay: TimeInterval,
        error: Error
    ) -> TimeInterval {
        // Check if error provides a retry-after hint from AppError
        if let appError = error as? AppError,
           case .serverError(429, _) = appError {
            // For rate limit errors, use a longer delay
            return min(30.0, maxDelay)
        }

        // Check if error provides a retry-after hint from LLMError
        if let llmError = error as? LLMError,
           case .rateLimitExceeded(let retryAfter) = llmError,
           let suggestedDelay = retryAfter {
            return min(suggestedDelay, maxDelay)
        }

        // Exponential backoff with jitter
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        let totalDelay = exponentialDelay + jitter

        return min(totalDelay, maxDelay)
    }
}
