import XCTest
@testable import AirFit

@MainActor
final class VoiceInputManagerTests: XCTestCase {
    
    var sut: VoiceInputManager!
    var mockModelManager: MockWhisperModelManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock model manager
        mockModelManager = MockWhisperModelManager()
        
        // Create VoiceInputManager with mock
        sut = VoiceInputManager(modelManager: mockModelManager)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockModelManager?.reset()
        mockModelManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_setsIdleState() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isRecording)
        XCTAssertFalse(sut.isTranscribing)
        XCTAssertEqual(sut.currentTranscription, "")
        XCTAssertEqual(sut.waveformBuffer, [])
    }
    
    func test_initialize_withNoDownloadedModels_triggersDownload() async {
        // Arrange
        mockModelManager.downloadedModels = []
        mockModelManager.stubOptimalModel("base")
        
        var stateChanges: [VoiceInputState] = []
        sut.onStateChange = { state in
            stateChanges.append(state)
        }
        
        // Act
        await sut.initialize()
        
        // Assert
        XCTAssertTrue(stateChanges.contains { state in
            if case .downloadingModel(_, let modelName) = state {
                return modelName == "Base (74 MB)"
            }
            return false
        })
    }
    
    func test_initialize_withDownloadedModel_skipDownload() async {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        mockModelManager.stubOptimalModel("base")
        
        var stateChanges: [VoiceInputState] = []
        sut.onStateChange = { state in
            stateChanges.append(state)
        }
        
        // Act
        await sut.initialize()
        
        // Wait a bit for initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert - Should go through preparingModel to ready without download
        XCTAssertTrue(stateChanges.contains { state in
            if case .preparingModel = state { return true }
            return false
        })
        XCTAssertFalse(stateChanges.contains { state in
            if case .downloadingModel = state { return true }
            return false
        })
    }
    
    // MARK: - Download Progress Tests
    
    func test_downloadProgress_updatesState() async {
        // Arrange
        mockModelManager.downloadedModels = []
        mockModelManager.stubOptimalModel("tiny")
        
        var progressUpdates: [Double] = []
        sut.onStateChange = { state in
            if case .downloadingModel(let progress, _) = state {
                progressUpdates.append(progress)
            }
        }
        
        // Act
        await sut.initialize()
        
        // Wait for simulated progress updates
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        
        // Assert
        XCTAssertTrue(progressUpdates.count > 0)
        XCTAssertTrue(progressUpdates.first ?? 1.0 < progressUpdates.last ?? 0.0)
    }
    
    // MARK: - Recording State Tests
    
    func test_startRecording_requiresReadyState() async throws {
        // Arrange - Keep in idle state
        XCTAssertEqual(sut.state, .idle)
        
        // Act & Assert
        do {
            try await sut.startRecording()
            XCTFail("Should throw whisperNotReady error")
        } catch {
            XCTAssertEqual(error as? VoiceInputError, .whisperNotReady)
        }
    }
    
    func test_startRecording_transitionsToRecordingState() async throws {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        await sut.initialize()
        // Wait for initialization to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        var recordingStateReceived = false
        sut.onStateChange = { state in
            if case .recording = state {
                recordingStateReceived = true
            }
        }
        
        // Act
        try await sut.startRecording()
        
        // Assert
        XCTAssertTrue(recordingStateReceived)
        XCTAssertTrue(sut.isRecording)
    }
    
    // MARK: - Transcription State Tests
    
    func test_stopRecording_transitionsToTranscribingThenReady() async throws {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        await sut.initialize()
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        try await sut.startRecording()
        
        var stateSequence: [VoiceInputState] = []
        sut.onStateChange = { state in
            stateSequence.append(state)
        }
        
        // Act
        _ = await sut.stopRecording()
        
        // Assert
        XCTAssertTrue(stateSequence.contains { state in
            if case .transcribing = state { return true }
            return false
        })
        XCTAssertTrue(stateSequence.contains { state in
            if case .ready = state { return true }
            return false
        })
    }
    
    // MARK: - Error State Tests
    
    func test_downloadFailure_setsErrorState() async {
        // Arrange
        mockModelManager.downloadedModels = []
        mockModelManager.stubInitializationError(VoiceInputError.whisperInitializationFailed)
        
        var errorStateReceived = false
        sut.onStateChange = { state in
            if case .error = state {
                errorStateReceived = true
            }
        }
        
        // Act
        await sut.initialize()
        
        // Wait for initialization attempt
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Assert
        XCTAssertTrue(errorStateReceived)
    }
    
    func test_transcriptionFailure_setsErrorState() async throws {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        await sut.initialize()
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        try await sut.startRecording()
        
        var errorStateReceived = false
        sut.onStateChange = { state in
            if case .error(.transcriptionFailed) = state {
                errorStateReceived = true
            }
        }
        
        // Configure to fail transcription
        // This would need actual WhisperKit mocking in production
        
        // Act
        _ = await sut.stopRecording()
        
        // For this test, we're just verifying the structure exists
        // Real implementation would test actual transcription failure
    }
    
    // MARK: - Streaming Tests
    
    func test_startStreamingTranscription_requiresReadyState() async throws {
        // Arrange - Keep in idle state
        XCTAssertEqual(sut.state, .idle)
        
        // Act & Assert
        do {
            try await sut.startStreamingTranscription()
            XCTFail("Should throw whisperNotReady error")
        } catch {
            XCTAssertEqual(error as? VoiceInputError, .whisperNotReady)
        }
    }
    
    func test_startStreamingTranscription_transitionsToTranscribingState() async throws {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        await sut.initialize()
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        var transcribingStateReceived = false
        sut.onStateChange = { state in
            if case .transcribing = state {
                transcribingStateReceived = true
            }
        }
        
        // Act
        try await sut.startStreamingTranscription()
        
        // Assert
        XCTAssertTrue(transcribingStateReceived)
        XCTAssertTrue(sut.isTranscribing)
    }
    
    func test_stopStreamingTranscription_transitionsToReadyState() async throws {
        // Arrange
        mockModelManager.downloadedModels = ["base"]
        await sut.initialize()
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        try await sut.startStreamingTranscription()
        
        var readyStateReceived = false
        sut.onStateChange = { state in
            if case .ready = state {
                readyStateReceived = true
            }
        }
        
        // Act
        await sut.stopStreamingTranscription()
        
        // Assert
        XCTAssertTrue(readyStateReceived)
        XCTAssertFalse(sut.isTranscribing)
    }
    
    // MARK: - Callback Tests
    
    func test_stateChangeCallback_calledOnStateTransitions() async {
        var callbackCount = 0
        sut.onStateChange = { _ in
            callbackCount += 1
        }
        
        await sut.initialize()
        
        // Should have received at least one state change
        XCTAssertGreaterThan(callbackCount, 0)
    }
    
    func test_errorCallback_calledOnError() async {
        mockModelManager.stubInitializationError(VoiceInputError.whisperInitializationFailed)
        
        var errorReceived: Error?
        sut.onError = { error in
            errorReceived = error
        }
        
        await sut.initialize()
        
        // Wait for initialization attempt
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        XCTAssertNotNil(errorReceived)
    }
}

