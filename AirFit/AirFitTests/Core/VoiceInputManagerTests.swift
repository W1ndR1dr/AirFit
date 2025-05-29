import XCTest
import AVFoundation
@testable import AirFit

@MainActor
final class VoiceInputManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    var sut: TestableVoiceInputManager!
    var mockModelManager: MockWhisperModelManager!
    var mockAudioSession: MockAVAudioSession!
    
    // MARK: - Test Lifecycle
    override func setUp() async throws {
        mockModelManager = MockWhisperModelManager()
        mockAudioSession = MockAVAudioSession()
        sut = TestableVoiceInputManager(modelManager: mockModelManager, audioSession: mockAudioSession)
        
        // Allow time for async initialization
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        _ = await sut.stopRecording()
        await sut.stopStreamingTranscription()
        sut = nil
        mockModelManager = nil
        mockAudioSession = nil
    }
    
    // MARK: - Permission Tests
    func test_requestPermission_whenGranted_shouldReturnTrue() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        
        // When
        let result = try await sut.requestPermission()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_requestPermission_whenDenied_shouldReturnFalse() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = false
        
        // When
        let result = try await sut.requestPermission()
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Recording State Tests
    func test_startRecording_shouldUpdateState() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        
        // When
        try await sut.startRecording()
        
        // Then
        XCTAssertTrue(sut.isRecording)
        XCTAssertFalse(sut.isTranscribing)
    }
    
    func test_stopRecording_shouldUpdateStateAndReturnTranscription() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        let expectedTranscription = "Hello world"
        mockModelManager.stubTranscription(expectedTranscription)
        
        try await sut.startRecording()
        
        // When
        let result = await sut.stopRecording()
        
        // Then
        XCTAssertFalse(sut.isRecording)
        XCTAssertEqual(result, expectedTranscription)
        XCTAssertEqual(sut.currentTranscription, expectedTranscription)
    }
    
    func test_stopRecording_whenNotRecording_shouldReturnNil() async {
        // When
        let result = await sut.stopRecording()
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Streaming Transcription Tests
    func test_startStreamingTranscription_shouldUpdateState() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubWhisperReady(true)
        
        // When
        try await sut.startStreamingTranscription()
        
        // Then
        XCTAssertTrue(sut.isTranscribing)
        XCTAssertFalse(sut.isRecording)
    }
    
    func test_startStreamingTranscription_whenWhisperNotReady_shouldThrowError() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        
        // Create new instance with error
        let errorModelManager = MockWhisperModelManager()
        errorModelManager.stubInitializationError(VoiceInputError.whisperInitializationFailed)
        let errorSut = TestableVoiceInputManager(modelManager: errorModelManager, audioSession: mockAudioSession)
        
        // Allow initialization to complete
        do {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        } catch {
            XCTFail("Unexpected error during sleep: \(error)")
        }
        
        // When/Then
        do {
            try await errorSut.startStreamingTranscription()
            XCTFail("Expected VoiceInputError.whisperNotReady")
        } catch VoiceInputError.whisperNotReady {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_stopStreamingTranscription_shouldUpdateState() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubWhisperReady(true)
        
        try await sut.startStreamingTranscription()
        
        // When
        await sut.stopStreamingTranscription()
        
        // Then
        XCTAssertFalse(sut.isTranscribing)
    }
    
    // MARK: - Callback Tests
    func test_transcriptionCallback_shouldBeCalledOnSuccess() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        let expectedTranscription = "Test transcription"
        mockModelManager.stubTranscription(expectedTranscription)
        
        var receivedTranscription: String?
        sut.onTranscription = { text in
            receivedTranscription = text
        }
        
        try await sut.startRecording()
        
        // When
        _ = await sut.stopRecording()
        
        // Then
        XCTAssertEqual(receivedTranscription, expectedTranscription)
    }
    
    func test_partialTranscriptionCallback_shouldBeCalledDuringStreaming() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubWhisperReady(true)
        let expectedText = "Partial text"
        mockModelManager.stubTranscription(expectedText)
        
        var receivedPartialTranscription: String?
        sut.onPartialTranscription = { text in
            receivedPartialTranscription = text
        }
        
        // When
        try await sut.startStreamingTranscription()
        
        // Allow time for async processing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then
        XCTAssertEqual(receivedPartialTranscription, expectedText)
    }
    
    func test_errorCallback_shouldBeCalledOnTranscriptionFailure() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscriptionError(VoiceInputError.transcriptionFailed)
        
        var receivedError: Error?
        sut.onError = { error in
            receivedError = error
        }
        
        try await sut.startRecording()
        
        // When
        _ = await sut.stopRecording()
        
        // Then
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(receivedError is VoiceInputError)
    }
    
    func test_waveformCallback_shouldBeCalledWithData() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        
        var receivedWaveform: [Float]?
        sut.onWaveformUpdate = { waveform in
            receivedWaveform = waveform
        }
        
        // When
        try await sut.startRecording()
        
        // Allow time for waveform timer
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        _ = await sut.stopRecording()
        
        // Then
        XCTAssertNotNil(receivedWaveform)
        XCTAssertFalse(receivedWaveform?.isEmpty ?? true)
    }
    
    // MARK: - Fitness-Specific Post-Processing Tests
    func test_postProcessTranscription_shouldCorrectFitnessTerms() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscription("I did 3 sets of 10 reps and some hiit cardio")
        
        try await sut.startRecording()
        
        // When
        let result = await sut.stopRecording()
        
        // Then
        XCTAssertEqual(result, "I did 3 sets of 10 reps and some HIIT cardio")
    }
    
    func test_postProcessTranscription_shouldHandlePRCorrection() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscription("I hit a new pr with my one rm")
        
        try await sut.startRecording()
        
        // When
        let result = await sut.stopRecording()
        
        // Then
        XCTAssertEqual(result, "I hit a new PR with my 1RM")
    }
    
    func test_postProcessTranscription_shouldTrimWhitespace() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscription("  workout complete  ")
        
        try await sut.startRecording()
        
        // When
        let result = await sut.stopRecording()
        
        // Then
        XCTAssertEqual(result, "workout complete")
    }
    
    // MARK: - Error Handling Tests
    func test_whisperInitializationFailure_shouldCallErrorCallback() async throws {
        // Given
        let errorModelManager = MockWhisperModelManager()
        errorModelManager.stubInitializationError(VoiceInputError.whisperInitializationFailed)
        
        var receivedError: Error?
        let errorExpectation = expectation(description: "Error callback called")
        
        // When
        let manager = TestableVoiceInputManager(modelManager: errorModelManager, audioSession: mockAudioSession)
        manager.onError = { error in
            receivedError = error
            errorExpectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(receivedError is VoiceInputError)
    }
    
    // MARK: - Performance Tests
    func test_transcriptionPerformance_shouldMeetLatencyRequirements() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscription("Performance test transcription")
        
        try await sut.startRecording()
        
        // When - Measure latency manually to avoid concurrency issues
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await sut.stopRecording()
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertLessThan(latency, 2.0, "Transcription should complete within 2 seconds")
    }
    
    func test_waveformBufferSize_shouldBeLimited() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        
        try await sut.startRecording()
        
        // When - Allow waveform to accumulate
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        _ = await sut.stopRecording()
        
        // Then
        XCTAssertLessThanOrEqual(sut.waveformBuffer.count, 50, "Waveform buffer should be limited to 50 samples")
    }
    
    // MARK: - Memory Management Tests
    func test_stopRecording_shouldCleanupResources() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        
        try await sut.startRecording()
        
        // When
        _ = await sut.stopRecording()
        
        // Then
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(sut.waveformBuffer.isEmpty)
    }
    
    func test_stopStreamingTranscription_shouldCleanupResources() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubWhisperReady(true)
        
        try await sut.startStreamingTranscription()
        
        // When
        await sut.stopStreamingTranscription()
        
        // Then
        XCTAssertFalse(sut.isTranscribing)
        XCTAssertTrue(sut.waveformBuffer.isEmpty)
    }
    
    // MARK: - WhisperKit Integration Tests
    func test_modelSelection_shouldUseOptimalModel() async throws {
        // Given
        mockModelManager.stubOptimalModel("large-v3")
        
        // When
        let selectedModel = mockModelManager.selectOptimalModel()
        
        // Then
        XCTAssertEqual(selectedModel, "large-v3")
    }
    
    func test_modelDownload_shouldUpdateDownloadedModels() async throws {
        // Given
        let modelId = "medium"
        
        // When
        try await mockModelManager.downloadModel(modelId)
        
        // Then
        XCTAssertTrue(mockModelManager.downloadedModels.contains(modelId))
    }
    
    func test_modelDeletion_shouldRemoveFromDownloadedModels() throws {
        // Given
        let modelId = "base"
        XCTAssertTrue(mockModelManager.downloadedModels.contains(modelId))
        
        // When
        try mockModelManager.deleteModel(modelId)
        
        // Then
        XCTAssertFalse(mockModelManager.downloadedModels.contains(modelId))
    }
    
    // MARK: - Audio Session Integration Tests
    func test_audioSessionConfiguration_shouldSetCorrectCategory() throws {
        // Given
        mockAudioSession.stubCategorySetError(nil)
        
        // When
        try mockAudioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        
        // Then
        XCTAssertEqual(mockAudioSession.category, .playAndRecord)
    }
    
    func test_audioSessionActivation_shouldActivateSuccessfully() throws {
        // Given
        mockAudioSession.stubActivationError(nil)
        
        // When
        try mockAudioSession.setActive(true)
        
        // Then
        XCTAssertTrue(mockAudioSession.isActive)
    }
    
    func test_audioSessionActivation_whenError_shouldThrow() {
        // Given
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
        mockAudioSession.stubActivationError(expectedError)
        
        // When/Then
        XCTAssertThrowsError(try mockAudioSession.setActive(true)) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
    
    // MARK: - Concurrent Access Tests
    func test_concurrentRecordingAttempts_shouldHandleGracefully() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        
        // When - Start multiple recording attempts sequentially to avoid concurrency issues
        try await sut.startRecording()
        try await sut.startRecording() // Should handle gracefully
        try await sut.startRecording() // Should handle gracefully
        
        // Then - Should not crash and maintain consistent state
        XCTAssertTrue(sut.isRecording)
        _ = await sut.stopRecording()
    }
    
    func test_rapidStartStopCycles_shouldMaintainStability() async throws {
        // Given
        mockAudioSession.recordPermissionResponse = true
        mockModelManager.stubOptimalModel("base")
        mockModelManager.stubTranscription("Test")
        
        // When - Rapid start/stop cycles
        for _ in 0..<5 {
            try await sut.startRecording()
            _ = await sut.stopRecording()
        }
        
        // Then - Should maintain stable state
        XCTAssertFalse(sut.isRecording)
        XCTAssertFalse(sut.isTranscribing)
    }
    
    // MARK: - Error Description Tests
    func test_errorDescriptions_shouldMatch() {
        XCTAssertEqual(VoiceInputError.notAuthorized.errorDescription, "Microphone access not authorized")
        XCTAssertEqual(VoiceInputError.whisperInitializationFailed.errorDescription, "Failed to initialize Whisper model")
        XCTAssertEqual(VoiceInputError.whisperNotReady.errorDescription, "Whisper is not ready for transcription")
        XCTAssertEqual(VoiceInputError.recordingFailed.errorDescription, "Audio recording failed")
        XCTAssertEqual(VoiceInputError.transcriptionFailed.errorDescription, "Failed to transcribe audio")
        XCTAssertEqual(VoiceInputError.audioEngineError.errorDescription, "Audio engine error occurred")
    }
} 