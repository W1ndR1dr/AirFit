import Foundation
@testable import AirFit

actor MockConversationAnalytics {
    // MARK: - Mock State
    var trackedEvents: [ConversationAnalyticsEvent] = []
    
    // MARK: - Mock Configuration
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock analytics error")
    
    // MARK: - Mock Methods
    func track(_ event: ConversationAnalyticsEvent) {
        if shouldThrowError {
            return // Can't throw from non-async
        }
        
        trackedEvents.append(event)
    }
    
    // MARK: - Test Helpers
    func reset() async {
        trackedEvents.removeAll()
        shouldThrowError = false
    }
}
