@testable import AirFit
import Foundation
import AVFoundation

@MainActor
final class MockVoiceInputManager: @preconcurrency MockProtocol, VoiceInputProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Published State
    private(set) var state: VoiceInputState = .idle
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""
    
    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?
    
    // MARK: - Mock Configuration
    var shouldGrantPermission = true
    var shouldFailRecording = false
    var shouldFailTranscription = false
    var mockTranscriptionResult = "Mock transcription result"
    var mockWaveformData: [Float] = [0.1, 0.3, 0.5, 0.7, 0.5, 0.3, 0.1]
    var transcriptionDelay: TimeInterval = 0.1
    var shouldSimulateDownload = false
    var downloadProgress: Double = 0.0
    
    // MARK: - Call Tracking
    private(set) var requestPermissionCalled = false
    private(set) var startRecordingCalled = false
    private(set) var stopRecordingCalled = false
    private(set) var startStreamingCalled = false
    private(set) var stopStreamingCalled = false
    private(set) var initializeCalled = false
    
    // MARK: - Initialization
    func initialize() async {
        recordInvocation(#function)
        initializeCalled = true
        
        if shouldSimulateDownload {
            updateState(.downloadingModel(progress: 0.0, modelName: "Mock Model"))
            
            // Simulate download progress
            Task {
                for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    downloadProgress = progress
                    updateState(.downloadingModel(progress: progress, modelName: "Mock Model"))
                }
                updateState(.preparingModel)
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                updateState(.ready)
            }
        } else {
            updateState(.ready)
        }
    }
    
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
            throw VoiceInputError.recordingFailed("Mock recording failure")
        }
        
        isRecording = true
        updateState(.recording)
        
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
        updateState(.transcribing)
        
        if shouldFailTranscription {
            updateState(.error(.transcriptionFailed))
            onError?(VoiceInputError.transcriptionFailed)
            return nil
        }
        
        // Simulate transcription delay
        try? await Task.sleep(nanoseconds: UInt64(transcriptionDelay * 1_000_000_000))
        
        currentTranscription = mockTranscriptionResult
        onTranscription?(mockTranscriptionResult)
        updateState(.ready)
        return mockTranscriptionResult
    }
    
    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        recordInvocation(#function)
        startStreamingCalled = true
        
        if shouldFailRecording {
            throw VoiceInputError.recordingFailed("Mock streaming failure")
        }
        
        isTranscribing = true
        updateState(.transcribing)
        
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
        updateState(.ready)
    }
    
    // MARK: - State Management
    private func updateState(_ newState: VoiceInputState) {
        state = newState
        onStateChange?(newState)
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
    
    func simulateStateChange(_ state: VoiceInputState) {
        updateState(state)
    }
    
    func reset() {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        invocations.removeAll()
        stubbedResults.removeAll()
        
        state = .idle
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
        initializeCalled = false
        
        shouldSimulateDownload = false
        downloadProgress = 0.0
        
        onTranscription = nil
        onPartialTranscription = nil
        onWaveformUpdate = nil
        onError = nil
        onStateChange = nil
    }
}
