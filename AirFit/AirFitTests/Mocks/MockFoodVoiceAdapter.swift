import Foundation
@testable import AirFit

/// Mock implementation of FoodVoiceAdapterProtocol for testing
@MainActor
final class MockFoodVoiceAdapter: FoodVoiceAdapterProtocol, @preconcurrency MockProtocol {
    // MARK: - MockProtocol
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Mock State
    
    private var _isListening = false
    var mockTranscription = "one apple and a glass of milk"
    var shouldThrowError = false
    var throwError: Error?
    
    // MARK: - Call Tracking
    
    var startListeningCallCount = 0
    var stopListeningCallCount = 0
    var isListeningCallCount = 0
    
    // MARK: - Configuration
    
    var simulatedDelay: TimeInterval = 0
    var transcriptionSequence: [String] = []
    private var transcriptionIndex = 0
    
    // MARK: - FoodVoiceAdapterProtocol
    
    func startListening() async throws {
        startListeningCallCount += 1
        
        if shouldThrowError, let error = throwError {
            throw error
        }
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        _isListening = true
    }
    
    func stopListening() async throws -> String {
        stopListeningCallCount += 1
        
        if shouldThrowError, let error = throwError {
            throw error
        }
        
        _isListening = false
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Return from sequence if available
        if !transcriptionSequence.isEmpty {
            let transcription = transcriptionSequence[transcriptionIndex % transcriptionSequence.count]
            transcriptionIndex += 1
            return transcription
        }
        
        return mockTranscription
    }
    
    func isListening() -> Bool {
        isListeningCallCount += 1
        return _isListening
    }
    
    // MARK: - MockProtocol
    
    func reset() {
        _isListening = false
        mockTranscription = "one apple and a glass of milk"
        shouldThrowError = false
        throwError = nil
        
        startListeningCallCount = 0
        stopListeningCallCount = 0
        isListeningCallCount = 0
        
        simulatedDelay = 0
        transcriptionSequence = []
        transcriptionIndex = 0
    }
    
    // MARK: - Helper Methods
    
    func configureTranscription(_ text: String) {
        mockTranscription = text
    }
    
    func configureTranscriptionSequence(_ texts: [String]) {
        transcriptionSequence = texts
        transcriptionIndex = 0
    }
    
    func configureError(_ error: Error) {
        shouldThrowError = true
        throwError = error
    }
    
    func verifyListeningState(expected: Bool) -> Bool {
        return _isListening == expected
    }
}