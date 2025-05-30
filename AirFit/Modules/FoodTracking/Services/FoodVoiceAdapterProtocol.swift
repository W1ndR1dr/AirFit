import Foundation

/// Protocol for voice input adapter specifically for food tracking
@MainActor
protocol FoodVoiceAdapterProtocol: Sendable {
    /// Start listening for voice input
    func startListening() async throws
    
    /// Stop listening and return the transcribed text
    func stopListening() async throws -> String
    
    /// Check if currently listening
    func isListening() -> Bool
} 