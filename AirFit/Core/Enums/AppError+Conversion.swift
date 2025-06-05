import Foundation

// MARK: - AppError Extensions for Error Type Consolidation

extension AppError {
    
    // MARK: - AI Errors
    
    /// Creates AppError from AIError
    static func from(_ aiError: AIError) -> AppError {
        switch aiError {
        case .networkError(let message):
            return .networkError(underlying: NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        case .rateLimitExceeded(let retryAfter):
            let message = retryAfter.map { "Rate limit exceeded. Try again in \(Int($0)) seconds." } 
                ?? "Rate limit exceeded. Please try again later."
            return .serverError(code: 429, message: message)
        case .invalidResponse(let message):
            return .decodingError(underlying: NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        case .modelOverloaded:
            return .serverError(code: 503, message: "AI service temporarily unavailable")
        case .contextLengthExceeded:
            return .validationError(message: "Message too long for AI processing")
        case .unauthorized:
            return .unauthorized
        }
    }
    
    /// Creates AppError from DirectAIError
    static func from(_ directAIError: DirectAIError) -> AppError {
        switch directAIError {
        case .nutritionParsingFailed(let reason):
            return .validationError(message: "Failed to parse nutrition: \(reason)")
        case .nutritionValidationFailed:
            return .validationError(message: "Invalid nutrition data")
        case .educationalContentFailed(let reason):
            return .unknown(message: "Failed to generate content: \(reason)")
        case .invalidResponse, .emptyResponse:
            return .decodingError(underlying: NSError(domain: "DirectAI", code: 0))
        case .timeout:
            return .networkError(underlying: NSError(domain: "DirectAI", code: -1001))
        case .invalidJSONResponse(let response):
            return .decodingError(underlying: NSError(domain: "DirectAI", code: 0, userInfo: [NSLocalizedDescriptionKey: response]))
        case .invalidNutritionValues(let details):
            return .validationError(message: "Invalid nutrition values: \(details)")
        }
    }
    
    // MARK: - Network Errors
    
    /// Creates AppError from NetworkError
    static func from(_ networkError: NetworkError) -> AppError {
        switch networkError {
        case .invalidURL:
            return .validationError(message: "Invalid URL")
        case .invalidResponse:
            return .networkError(underlying: NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"]))
        case .noData:
            return .networkError(underlying: NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
        case .decodingError(let error):
            return .decodingError(underlying: error)
        case .httpError(let statusCode, let data):
            return .serverError(code: statusCode, message: String(data: data ?? Data(), encoding: .utf8))
        case .networkError(let error):
            return .networkError(underlying: error)
        case .timeout:
            return .networkError(underlying: NSError(domain: "Network", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"]))
        }
    }
    
    // MARK: - Service Errors
    
    /// Creates AppError from ServiceError
    static func from(_ serviceError: ServiceError) -> AppError {
        switch serviceError {
        case .notConfigured:
            return .unknown(message: "Service not configured")
        case .invalidConfiguration(let detail):
            return .unknown(message: "Invalid configuration: \(detail)")
        case .networkUnavailable:
            return .networkError(underlying: NSError(domain: "Service", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"]))
        case .authenticationFailed(let reason):
            return .unauthorized
        case .rateLimitExceeded(let retryAfter):
            let message = retryAfter.map { "Rate limit exceeded. Retry after \(Int($0)) seconds" } 
                ?? "Rate limit exceeded"
            return .serverError(code: 429, message: message)
        case .invalidResponse(let detail):
            return .decodingError(underlying: NSError(domain: "Service", code: 0, userInfo: [NSLocalizedDescriptionKey: detail]))
        case .streamingError(let detail):
            return .unknown(message: "Streaming error: \(detail)")
        case .timeout:
            return .networkError(underlying: NSError(domain: "Service", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"]))
        case .cancelled:
            return .unknown(message: "Request was cancelled")
        case .providerError(let code, let message):
            return .unknown(message: "Provider error [\(code)]: \(message)")
        case .unknown(let error):
            return .unknown(message: error.localizedDescription)
        }
    }
    
    // MARK: - Workout Errors
    
    /// Creates AppError from WorkoutError
    static func from(_ workoutError: WorkoutError) -> AppError {
        switch workoutError {
        case .saveFailed:
            return .unknown(message: "Failed to save workout")
        case .syncFailed:
            return .networkError(underlying: NSError(domain: "WorkoutSync", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sync workout data"]))
        }
    }
    
    // MARK: - Keychain Errors
    
    /// Creates AppError from KeychainError
    static func from(_ keychainError: KeychainError) -> AppError {
        switch keychainError {
        case .itemNotFound:
            return .unknown(message: "Keychain item not found")
        case .duplicateItem:
            return .unknown(message: "Keychain item already exists")
        case .invalidData:
            return .decodingError(underlying: NSError(domain: "Keychain", code: 0))
        case .unhandledError(let status):
            return .unknown(message: "Keychain error: \(status)")
        }
    }
    
    // MARK: - Onboarding Errors
    
    /// Creates AppError from OnboardingError  
    static func from(_ onboardingError: OnboardingError) -> AppError {
        switch onboardingError {
        case .noSession:
            return .unknown(message: "No onboarding session found")
        case .noPersona:
            return .unknown(message: "No persona generated")
        case .personaGenerationFailed(let details):
            return .unknown(message: "Persona generation failed: \(details)")
        case .saveFailed(let details):
            return .unknown(message: "Failed to save profile: \(details)")
        case .networkError(let error):
            return .networkError(underlying: error)
        case .recoveryFailed(let details):
            return .unknown(message: "Recovery failed: \(details)")
        case .noUserFound:
            return .userNotFound
        case .invalidProfileData:
            return .validationError(message: "Invalid profile data")
        case .missingRequiredField(let field):
            return .validationError(message: "Missing required field: \(field)")
        case .conversationStartFailed(let error):
            return .unknown(message: "Failed to start conversation: \(error.localizedDescription)")
        }
    }
    
    /// Creates AppError from OnboardingOrchestratorError
    static func from(_ orchestratorError: OnboardingOrchestratorError) -> AppError {
        switch orchestratorError {
        case .conversationStartFailed(let error):
            return .unknown(message: "Failed to start conversation: \(error.localizedDescription)")
        case .responseProcessingFailed(let error):
            return .unknown(message: "Failed to process response: \(error.localizedDescription)")
        case .synthesisFailed(let error):
            return .unknown(message: "Failed to generate coach persona: \(error.localizedDescription)")
        case .saveFailed(let error):
            return .unknown(message: "Failed to save profile: \(error.localizedDescription)")
        case .adjustmentFailed(let error):
            return .unknown(message: "Failed to adjust persona: \(error.localizedDescription)")
        case .invalidStateTransition:
            return .unknown(message: "Invalid onboarding state")
        case .timeout:
            return .networkError(underlying: NSError(domain: "Onboarding", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Onboarding timed out"]))
        case .networkError:
            return .networkError(underlying: NSError(domain: "Onboarding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network error during onboarding"]))
        case .userCancelled:
            return .unknown(message: "Onboarding cancelled")
        }
    }
    
    // MARK: - Food Tracking Errors
    
    /// Creates AppError from FoodTrackingError
    static func from(_ foodError: FoodTrackingError) -> AppError {
        switch foodError {
        case .transcriptionFailed:
            return .unknown(message: "Failed to transcribe voice input")
        case .aiParsingFailed:
            return .unknown(message: "Failed to parse food information")
        case .noFoodFound:
            return .validationError(message: "No food items detected")
        case .networkError:
            return .networkError(underlying: NSError(domain: "FoodTracking", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
        case .invalidInput:
            return .validationError(message: "Invalid input provided")
        case .permissionDenied:
            return .unauthorized
        case .aiProcessingTimeout:
            return .networkError(underlying: NSError(domain: "FoodTracking", code: -1001, userInfo: [NSLocalizedDescriptionKey: "AI processing timed out"]))
        case .invalidNutritionResponse:
            return .decodingError(underlying: NSError(domain: "FoodTracking", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid nutrition data from AI"]))
        case .invalidNutritionData:
            return .validationError(message: "Malformed nutrition information")
        }
    }
    
    /// Creates AppError from FoodVoiceError
    static func from(_ voiceError: FoodVoiceError) -> AppError {
        switch voiceError {
        case .voiceInputManagerUnavailable:
            return .unknown(message: "Voice input manager is not available")
        case .transcriptionFailed:
            return .unknown(message: "Failed to transcribe voice input")
        case .permissionDenied:
            return .cameraNotAuthorized // Using similar auth error type
        }
    }
    
    // MARK: - Chat Errors
    
    /// Creates AppError from ChatError
    static func from(_ chatError: ChatError) -> AppError {
        switch chatError {
        case .noActiveSession:
            return .unknown(message: "No active chat session")
        case .exportFailed(let reason):
            return .unknown(message: "Export failed: \(reason)")
        case .voiceRecognitionUnavailable:
            return .unknown(message: "Voice recognition is not available")
        }
    }
    
    // MARK: - Settings Errors
    
    /// Creates AppError from SettingsError
    static func from(_ settingsError: SettingsError) -> AppError {
        switch settingsError {
        case .missingAPIKey(let provider):
            return .validationError(message: "Please add an API key for \(provider.displayName)")
        case .invalidAPIKey:
            return .validationError(message: "Invalid API key format")
        case .apiKeyTestFailed:
            return .validationError(message: "API key validation failed. Please check your key.")
        case .biometricsNotAvailable:
            return .unknown(message: "Biometric authentication is not available on this device")
        case .exportFailed(let reason):
            return .unknown(message: "Export failed: \(reason)")
        case .personaNotConfigured:
            return .unknown(message: "Coach persona is not configured")
        case .personaAdjustmentFailed(let reason):
            return .unknown(message: "Failed to adjust persona: \(reason)")
        }
    }
    
    // MARK: - AI Module Errors
    
    /// Creates AppError from ConversationManagerError
    static func from(_ conversationError: ConversationManagerError) -> AppError {
        switch conversationError {
        case .userNotFound:
            return .userNotFound
        case .conversationNotFound:
            return .unknown(message: "Conversation not found")
        case .invalidMessageRole:
            return .validationError(message: "Invalid message role")
        case .encodingFailed:
            return .decodingError(underlying: NSError(domain: "ConversationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message data"]))
        case .saveFailed(let error):
            return .unknown(message: "Failed to save message: \(error.localizedDescription)")
        }
    }
    
    /// Creates AppError from FunctionError
    static func from(_ functionError: FunctionError) -> AppError {
        switch functionError {
        case .unknownFunction(let name):
            return .unknown(message: "Unknown function: \(name)")
        case .invalidArguments:
            return .validationError(message: "Invalid function arguments")
        case .serviceUnavailable:
            return .unknown(message: "Service temporarily unavailable")
        case .dataNotFound:
            return .unknown(message: "Required data not found")
        case .processingTimeout:
            return .networkError(underlying: NSError(domain: "Function", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Function processing timed out"]))
        }
    }
    
    /// Creates AppError from PersonaEngineError
    static func from(_ personaEngineError: PersonaEngineError) -> AppError {
        switch personaEngineError {
        case .promptTooLong(let tokens):
            return .validationError(message: "System prompt too long: ~\(tokens) tokens")
        case .invalidProfile:
            return .validationError(message: "Invalid user profile data")
        case .encodingFailed:
            return .decodingError(underlying: NSError(domain: "PersonaEngine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode profile data"]))
        }
    }
    
    /// Creates AppError from PersonaError
    static func from(_ personaError: PersonaError) -> AppError {
        switch personaError {
        case .invalidResponse(let message):
            return .decodingError(underlying: NSError(domain: "Persona", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid AI response: \(message)"]))
        case .missingField(let field):
            return .validationError(message: "Missing required field: \(field)")
        case .invalidFormat(let field, let expected):
            return .validationError(message: "Invalid format for \(field). Expected: \(expected)")
        }
    }
    
    // MARK: - Notifications Errors
    
    /// Creates AppError from LiveActivityError
    static func from(_ liveActivityError: LiveActivityError) -> AppError {
        switch liveActivityError {
        case .notEnabled:
            return .unknown(message: "Live Activities are not enabled")
        case .failedToStart(let error):
            return .unknown(message: "Failed to start activity: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Coach Engine Errors
    
    /// Creates AppError from CoachEngineError
    static func from(_ coachError: CoachEngineError) -> AppError {
        switch coachError {
        case .noActiveConversation:
            return .unknown(message: "No active conversation")
        case .noMessageToRegenerate:
            return .validationError(message: "No message to regenerate")
        case .aiServiceUnavailable:
            return .unknown(message: "AI service unavailable")
        case .streamingTimeout:
            return .networkError(underlying: NSError(domain: "Streaming", code: -1001))
        case .functionExecutionFailed(let details):
            return .unknown(message: "Function execution failed: \(details)")
        case .contextAssemblyFailed:
            return .unknown(message: "Failed to assemble context")
        case .invalidUserProfile:
            return .validationError(message: "Invalid user profile")
        case .nutritionParsingFailed(let details):
            return .validationError(message: "Nutrition parsing failed: \(details)")
        case .educationalContentFailed(let details):
            return .unknown(message: "Educational content failed: \(details)")
        }
    }
}

// MARK: - Error Handling Utilities

extension AppError {
    /// Determines if the error is recoverable by the user
    var isRecoverable: Bool {
        switch self {
        case .networkError, .unauthorized, .healthKitNotAuthorized, .cameraNotAuthorized:
            return true
        case .serverError(let code, _):
            return code >= 500 // Server errors might resolve
        default:
            return false
        }
    }
    
    /// Determines if the error should trigger a retry
    var shouldRetry: Bool {
        switch self {
        case .networkError:
            return true
        case let .serverError(code, _) where code >= 500:
            return true
        default:
            return false
        }
    }
    
    /// Suggested retry delay in seconds
    var retryDelay: TimeInterval? {
        switch self {
        case .serverError(429, _): // Rate limited
            return 60.0
        case let .serverError(code, _) where code >= 500:
            return 5.0
        case .networkError:
            return 2.0
        default:
            return nil
        }
    }
}

// MARK: - Error Context

/// Provides additional context for errors
struct ErrorContext: Sendable {
    let error: AppError
    let file: String
    let function: String
    let line: Int
    let additionalInfo: [String: String]? // Changed to Sendable type
    
    init(
        error: AppError,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        additionalInfo: [String: String]? = nil
    ) {
        self.error = error
        self.file = URL(fileURLWithPath: file).lastPathComponent
        self.function = function
        self.line = line
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Result Extensions

extension Result where Failure == Error {
    /// Maps any error to AppError
    func mapToAppError() -> Result<Success, AppError> {
        mapError { error in
            if let appError = error as? AppError {
                return appError
            } else if let aiError = error as? AIError {
                return AppError.from(aiError)
            } else if let networkError = error as? NetworkError {
                return AppError.from(networkError)
            } else if let serviceError = error as? ServiceError {
                return AppError.from(serviceError)
            } else if let workoutError = error as? WorkoutError {
                return AppError.from(workoutError)
            } else if let keychainError = error as? KeychainError {
                return AppError.from(keychainError)
            } else if let coachError = error as? CoachEngineError {
                return AppError.from(coachError)
            } else if let directAIError = error as? DirectAIError {
                return AppError.from(directAIError)
            } else if let onboardingError = error as? OnboardingError {
                return AppError.from(onboardingError)
            } else if let orchestratorError = error as? OnboardingOrchestratorError {
                return AppError.from(orchestratorError)
            } else if let foodError = error as? FoodTrackingError {
                return AppError.from(foodError)
            } else if let voiceError = error as? FoodVoiceError {
                return AppError.from(voiceError)
            } else if let chatError = error as? ChatError {
                return AppError.from(chatError)
            } else if let settingsError = error as? SettingsError {
                return AppError.from(settingsError)
            } else if let conversationError = error as? ConversationManagerError {
                return AppError.from(conversationError)
            } else if let functionError = error as? FunctionError {
                return AppError.from(functionError)
            } else if let personaEngineError = error as? PersonaEngineError {
                return AppError.from(personaEngineError)
            } else if let personaError = error as? PersonaError {
                return AppError.from(personaError)
            } else if let liveActivityError = error as? LiveActivityError {
                return AppError.from(liveActivityError)
            } else {
                return AppError.networkError(underlying: error)
            }
        }
    }
}