import Foundation

// MARK: - Completion & Error Handling
extension OnboardingViewModel {
    
    func completeOnboarding() async {
        guard let persona = generatedPersona,
              let userId = await userService.getCurrentUserId() else {
            error = .validationError(message: "Missing persona or user")
            isShowingError = true
            return
        }
        
        isLoading = true
        
        do {
            // Save persona
            try await personaService.savePersona(persona, for: userId)
            
            // Update user with coach persona
            let coachPersona = CoachPersona(from: persona)
            try await userService.setCoachPersona(coachPersona)
            
            // Complete onboarding
            try await userService.completeOnboarding()
            
            // Track completion
            // await analytics.trackEvent(.onboardingCompleted)
            
            // Notify completion
            onCompletionCallback?()
            
        } catch {
            self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
            isShowingError = true
        }
        
        isLoading = false
    }
    
    func handleError(_ error: Error) {
        self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
        isShowingError = true
        HapticService.play(.error)
    }
    
    func clearError() {
        error = nil
        isShowingError = false
    }
}