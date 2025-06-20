import Foundation

// MARK: - Onboarding Error Messages
enum OnboardingErrorMessages {
    
    // MARK: - HealthKit Errors
    static let healthKitDenied = "No worries! I can still help you without the health data. We'll just need a few extra details from you."
    static let healthKitRestricted = "Looks like health access is restricted on this device. No problem - we'll work around it!"
    static let healthKitUnavailable = "Can't access health data right now, but that's totally fine. Let's keep moving!"
    
    // MARK: - Network Errors
    static let networkTimeout = "Connection's being a bit slow... Let's give it another shot?"
    static let networkOffline = "Looks like we're offline. I'll save everything and sync up when you're back online!"
    static let apiKeyInvalid = "Hmm, that key doesn't seem to be working. Double-check it's copied correctly?"
    static let apiRateLimit = "We're hitting some limits - let's take a quick breather and try again in a moment."
    
    // MARK: - Voice Input Errors
    static let microphonePermissionDenied = "I need microphone access to hear you. You can enable it in Settings, or just type instead!"
    static let voiceRecognitionFailed = "Didn't quite catch that - mind trying again? Or you can always type it out."
    static let voiceInputTooLong = "That was a lot! Mind breaking it down a bit? I want to make sure I get everything right."
    
    // MARK: - LLM Synthesis Errors
    static let synthesisTimeout = "This is taking longer than usual... Hang tight, or we can try a simpler approach?"
    static let synthesisFailedGeneric = "Hit a small snag creating your coach. Let's try once more?"
    static let synthesisPartialSuccess = "Got most of it figured out! We can refine things as we go."
    
    // MARK: - Data Validation Errors
    static let weightOutOfRange = "That doesn't look quite right - mind double-checking?"
    static let goalsEmpty = "Tell me at least one thing you'd like to work on - even something small!"
    static let contextTooShort = "Give me a bit more to work with - what's your day really like?"
    
    // MARK: - Encouraging Recovery Messages
    static let retryEncouragement = "No biggie - these things happen. Ready to give it another go?"
    static let skipEncouragement = "We can always come back to this later. Let's keep the momentum going!"
    static let defaultFallback = "I'll work with what we've got and we can always adjust things later."
    
    // MARK: - Helper Functions
    static func getErrorMessage(for error: Error) -> String {
        // Generic fallback for now - can be enhanced based on actual AppError structure
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") || errorDescription.contains("connection") {
            return networkTimeout
        } else if errorDescription.contains("healthkit") || errorDescription.contains("health") {
            return healthKitUnavailable
        } else if errorDescription.contains("api") || errorDescription.contains("key") {
            return apiKeyInvalid
        } else if errorDescription.contains("synthesis") || errorDescription.contains("llm") {
            return synthesisFailedGeneric
        }
        
        // Check for specific error domains
        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return networkOffline
            } else if nsError.code == NSURLErrorTimedOut {
                return networkTimeout
            }
        default:
            break
        }
        
        // Generic fallback
        return "Something went sideways, but it's no big deal. Let's try again?"
    }
}