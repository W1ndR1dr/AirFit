import Foundation

// MARK: - Voice Input
extension OnboardingViewModel {
    enum VoiceInputField {
        case lifeContext
        case goals
        case additionalContext
    }
    
    func startVoiceCapture(for field: VoiceInputField) {
        // Voice capture would integrate with real speech service
        print("[OnboardingViewModel] Starting voice capture for \(field)")
        
        // For now, we'll simulate with some example text after a delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                switch field {
                case .lifeContext:
                    if lifeContext.isEmpty {
                        lifeContext = "I work from home and have two young kids. Usually exercise in the mornings."
                    }
                case .goals:
                    if functionalGoalsText.isEmpty {
                        functionalGoalsText = "I want to lose 15 pounds and have more energy throughout the day"
                    }
                case .additionalContext:
                    // Additional context if needed
                    break
                }
            }
        }
    }
    
    func stopVoiceCapture() {
        // Stop any ongoing voice capture
        print("[OnboardingViewModel] Stopping voice capture")
    }
}