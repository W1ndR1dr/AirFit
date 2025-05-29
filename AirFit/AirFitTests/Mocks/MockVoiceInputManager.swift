@testable import AirFit
import Foundation
import AVFoundation

@MainActor
final class MockVoiceInputManager: @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Published State
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""
    
    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Mock Configuration
    var shouldGrantPermission = true
    var shouldFailRecording = false
    var shouldFailTranscription = false
    var mockTranscriptionResult = "Mock transcription result"
    var mockWaveformData: [Float] = [0.1, 0.3, 0.5, 0.7, 0.5, 0.3, 0.1]
    var transcriptionDelay: TimeInterval = 0.1
    
    // MARK: - Call Tracking
    private(set) var requestPermissionCalled = false
    private(set) var startRecordingCalled = false
    private(set) var stopRecordingCalled = false
    private(set) var startStreamingCalled = false
    private(set) var stopStreamingCalled = false
    
    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        recordInvocation(#function)
        requestPermissionCalled = true
        
        if !shouldGrantPermission {
            throw VoiceInputError.notAuthorized
        }
        return true
    }
    
    // MARK: - Recording Control
    func startRecording() async throws {
        recordInvocation(#function)
        startRecordingCalled = true
        
        if shouldFailRecording {
            throw VoiceInputError.recordingFailed
        }
        
        isRecording = true
        
        // Simulate waveform updates
        Task {
            for level in mockWaveformData {
                guard isRecording else { break }
                waveformBuffer.append(level)
                onWaveformUpdate?(waveformBuffer)
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }
    
    func stopRecording() async -> String? {
        recordInvocation(#function)
        stopRecordingCalled = true
        
        isRecording = false
        waveformBuffer.removeAll()
        onWaveformUpdate?([])
        
        if shouldFailTranscription {
            onError?(VoiceInputError.transcriptionFailed)
            return nil
        }
        
        // Simulate transcription delay
        try? await Task.sleep(nanoseconds: UInt64(transcriptionDelay * 1_000_000_000))
        
        currentTranscription = mockTranscriptionResult
        onTranscription?(mockTranscriptionResult)
        return mockTranscriptionResult
    }
    
    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        recordInvocation(#function)
        startStreamingCalled = true
        
        if shouldFailRecording {
            throw VoiceInputError.audioEngineError
        }
        
        isTranscribing = true
        
        // Simulate partial transcription updates
        Task {
            let words = mockTranscriptionResult.components(separatedBy: " ")
            var partial = ""
            
            for word in words {
                guard isTranscribing else { break }
                partial += (partial.isEmpty ? "" : " ") + word
                onPartialTranscription?(partial)
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
            }
        }
    }
    
    func stopStreamingTranscription() async {
        recordInvocation(#function)
        stopStreamingCalled = true
        
        isTranscribing = false
    }
    
    // MARK: - Test Helpers
    func simulateTranscription(_ text: String) {
        mockTranscriptionResult = text
        currentTranscription = text
        onTranscription?(text)
    }
    
    func simulatePartialTranscription(_ text: String) {
        onPartialTranscription?(text)
    }
    
    func simulateWaveformUpdate(_ levels: [Float]) {
        waveformBuffer = levels
        onWaveformUpdate?(levels)
    }
    
    func simulateError(_ error: Error) {
        onError?(error)
    }
    
    func reset() {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        invocations.removeAll()
        stubbedResults.removeAll()
        
        isRecording = false
        isTranscribing = false
        waveformBuffer.removeAll()
        currentTranscription = ""
        
        shouldGrantPermission = true
        shouldFailRecording = false
        shouldFailTranscription = false
        mockTranscriptionResult = "Mock transcription result"
        transcriptionDelay = 0.1
        
        requestPermissionCalled = false
        startRecordingCalled = false
        stopRecordingCalled = false
        startStreamingCalled = false
        stopStreamingCalled = false
        
        onTranscription = nil
        onPartialTranscription = nil
        onWaveformUpdate = nil
        onError = nil
    }
} 