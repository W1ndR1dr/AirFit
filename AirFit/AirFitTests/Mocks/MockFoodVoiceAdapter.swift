import Foundation
@testable import AirFit

// Simple mock error for testing
enum MockError: Error {
    case generic
    case custom(String)
}

/// Mock implementation of FoodVoiceAdapterProtocol for testing
@MainActor
final class MockFoodVoiceAdapter: FoodVoiceAdapterProtocol, @preconcurrency MockProtocol {
    // MARK: - MockProtocol
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - FoodVoiceAdapterProtocol Properties
    var onFoodTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    
    private(set) var isRecording = false
    private(set) var transcribedText = ""
    private(set) var voiceWaveform: [Float] = []
    private(set) var currentState: VoiceInputState = .idle
    
    // MARK: - Mock State
    var stopRecordingText = "one apple and a glass of milk"
    var requestPermissionShouldSucceed = true
    var startRecordingShouldSucceed = true
    var shouldThrowError = false
    var throwError: Error?
    
    // MARK: - Configuration
    
    var simulatedDelay: TimeInterval = 0
    var transcriptionSequence: [String] = []
    private var transcriptionIndex = 0
    
    // MARK: - FoodVoiceAdapterProtocol
    
    func initialize() async {
        recordInvocation("initialize")
        // Simulate initialization - could trigger state changes if needed
        currentState = .ready
        onStateChange?(.ready)
    }
    
    func requestPermission() async throws -> Bool {
        recordInvocation("requestPermission")
        
        if shouldThrowError, let error = throwError {
            throw error
        }
        
        return requestPermissionShouldSucceed
    }
    
    func startRecording() async throws {
        recordInvocation("startRecording")
        
        if !startRecordingShouldSucceed {
            throw MockError.generic
        }
        
        if shouldThrowError, let error = throwError {
            throw error
        }
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        isRecording = true
        transcribedText = ""
        voiceWaveform = []
    }
    
    func stopRecording() async -> String? {
        recordInvocation("stopRecording")
        
        isRecording = false
        
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Return from sequence if available
        if !transcriptionSequence.isEmpty {
            let transcription = transcriptionSequence[transcriptionIndex % transcriptionSequence.count]
            transcriptionIndex += 1
            transcribedText = transcription
            return transcription
        }
        
        transcribedText = stopRecordingText
        return stopRecordingText
    }
    
    // MARK: - MockProtocol
    
    func reset() {
        isRecording = false
        transcribedText = ""
        voiceWaveform = []
        currentState = .idle
        stopRecordingText = "one apple and a glass of milk"
        requestPermissionShouldSucceed = true
        startRecordingShouldSucceed = true
        shouldThrowError = false
        throwError = nil
        
        simulatedDelay = 0
        transcriptionSequence = []
        transcriptionIndex = 0
        
        onFoodTranscription = nil
        onError = nil
        onStateChange = nil
        onWaveformUpdate = nil
        
        invocations.removeAll()
    }
    
    // MARK: - Helper Methods
    
    func simulateTranscription(_ text: String) {
        transcribedText = text
        onFoodTranscription?(text)
    }
    
    func simulateError(_ error: Error) {
        onError?(error)
    }
    
    func configureTranscription(_ text: String) {
        stopRecordingText = text
    }
    
    func configureTranscriptionSequence(_ texts: [String]) {
        transcriptionSequence = texts
        transcriptionIndex = 0
    }
    
    func configureError(_ error: Error) {
        shouldThrowError = true
        throwError = error
    }
    
    func verifyRecordingState(expected: Bool) -> Bool {
        return isRecording == expected
    }
    
    func simulateStateChange(_ state: VoiceInputState) {
        currentState = state
        onStateChange?(state)
    }
    
    func simulateWaveformUpdate(_ waveform: [Float]) {
        voiceWaveform = waveform
        onWaveformUpdate?(waveform)
    }
}