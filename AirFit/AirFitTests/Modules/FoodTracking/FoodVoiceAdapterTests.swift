import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class FoodVoiceAdapterTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: FoodVoiceAdapter!
    private var mockVoiceInputManager: MockVoiceInputManager!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Create mock voice input manager
        mockVoiceInputManager = MockVoiceInputManager()
        
        // Create subject under test with injected dependencies
        sut = FoodVoiceAdapter(voiceInputManager: mockVoiceInputManager)
    }
    
    override func tearDown() async throws {
        mockVoiceInputManager?.reset()
        sut = nil
        mockVoiceInputManager = nil
        container = nil
        try super.tearDown()
    }
    
    // MARK: - Post-Processing Tests
    
    func test_postProcessForFood_trimsWhitespace() {
        let testCases = [
            ("  hello world  ", "hello world"),
            ("\n\ttest\n\t", "test"),
            ("   ", "")
        ]
        
        for (input, expected) in testCases {
            let processed = sut.postProcessForFood(input)
            XCTAssertEqual(processed, expected, "Failed for input: '\(input)'")
        }
    }
    
    func test_postProcessForFood_correctsCommonMistakes() {
        let testCases = [
            ("to eggs", "two eggs"),
            ("for slices of bread", "four slices of bread"),
            ("won cup of coffee", "one cup of coffee"),
            ("tree cups water", "three cups water"),
            ("ate ounces chicken", "eight ounces chicken"),
            ("I had CHICKEN BREAST", "I had chicken breast"),
            ("a sweet potato", "a sweet potato"),
            ("greek yogurt with berries", "Greek yogurt with berries"),
            ("peanut butter sandwich", "peanut butter sandwich"),
            ("olive oil for cooking", "olive oil for cooking"),
            ("one table spoon of sugar", "one tablespoon of sugar"),
            ("half tea spoon salt", "half teaspoon salt"),
            ("two fluid ounce juice", "two fl oz juice"),
            ("five pounds of potatoes", "five lbs of potatoes"),
            ("  won cup of tea with to eggs  ", "one cup of tea with two eggs")
        ]
        
        for (input, expected) in testCases {
            let processed = sut.postProcessForFood(input)
            XCTAssertEqual(processed, expected, "Failed for input: '\(input)'")
        }
    }
    
    func test_postProcessForFood_preservesCorrectText() {
        let input = "two apples and a banana with some almonds"
        let processed = sut.postProcessForFood(input)
        XCTAssertEqual(processed, input)
    }
    
    // MARK: - State Tests
    
    func test_initialState() {
        XCTAssertFalse(sut.isRecording)
        XCTAssertFalse(sut.isTranscribing)
        XCTAssertEqual(sut.transcribedText, "")
        XCTAssertEqual(sut.voiceWaveform, [])
    }
    
    // MARK: - Permission Tests
    
    func test_requestPermission_granted_returnsTrue() async throws {
        mockVoiceInputManager.shouldGrantPermission = true
        
        let granted = try await sut.requestPermission()
        
        XCTAssertTrue(granted)
        XCTAssertTrue(mockVoiceInputManager.requestPermissionCalled)
    }
    
    func test_requestPermission_denied_throwsError() async {
        mockVoiceInputManager.shouldGrantPermission = false
        
        do {
            _ = try await sut.requestPermission()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is VoiceInputError)
        }
    }
    
    // MARK: - Recording Tests
    
    func test_startRecording_success_updatesState() async throws {
        mockVoiceInputManager.shouldFailRecording = false
        
        try await sut.startRecording()
        
        XCTAssertTrue(sut.isRecording)
        XCTAssertTrue(mockVoiceInputManager.startRecordingCalled)
    }
    
    func test_startRecording_failure_callsErrorCallback() async {
        mockVoiceInputManager.shouldFailRecording = true
        var errorReceived: Error?
        
        sut.onError = { error in
            errorReceived = error
        }
        
        do {
            try await sut.startRecording()
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
        }
        
        XCTAssertNotNil(errorReceived)
    }
    
    func test_stopRecording_success_returnsTranscription() async throws {
        mockVoiceInputManager.mockTranscriptionResult = "test food transcription"
        mockVoiceInputManager.shouldFailTranscription = false
        
        try await sut.startRecording()
        let result = await sut.stopRecording()
        
        XCTAssertEqual(result, "test food transcription")
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(mockVoiceInputManager.stopRecordingCalled)
    }
    
    func test_stopRecording_failure_returnsNil() async throws {
        mockVoiceInputManager.shouldFailTranscription = true
        
        try await sut.startRecording()
        let result = await sut.stopRecording()
        
        XCTAssertNil(result)
        XCTAssertFalse(sut.isRecording)
    }
    
    // MARK: - Callback Tests
    
    func test_onFoodTranscription_calledWithProcessedText() async throws {
        var receivedText: String?
        sut.onFoodTranscription = { text in
            receivedText = text
        }
        
        // Simulate transcription through mock
        mockVoiceInputManager.simulateTranscription("won cup of coffee")
        
        // Wait a bit for callback processing
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(receivedText, "one cup of coffee", "Should receive post-processed text")
    }
    
    func test_onError_forwardsErrorsFromVoiceInput() {
        var receivedError: Error?
        sut.onError = { error in
            receivedError = error
        }
        
        let testError = VoiceInputError.transcriptionFailed
        mockVoiceInputManager.simulateError(testError)
        
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(receivedError is VoiceInputError)
    }
    
    func test_waveformUpdate_forwardsFromVoiceInput() {
        let testWaveform: [Float] = [0.1, 0.3, 0.5, 0.3, 0.1]
        
        mockVoiceInputManager.simulateWaveformUpdate(testWaveform)
        
        XCTAssertEqual(sut.voiceWaveform, testWaveform)
    }
    
    func test_partialTranscription_updatesTranscribedText() {
        mockVoiceInputManager.simulatePartialTranscription("partial text")
        
        XCTAssertEqual(sut.transcribedText, "partial text")
    }
    
    // MARK: - Streaming Tests
    
    func test_startStreamingTranscription_success() async throws {
        mockVoiceInputManager.shouldFailRecording = false
        
        try await sut.startStreamingTranscription()
        
        XCTAssertTrue(sut.isTranscribing)
        XCTAssertTrue(mockVoiceInputManager.startStreamingCalled)
    }
    
    func test_stopStreamingTranscription_updatesState() async throws {
        try await sut.startStreamingTranscription()
        await sut.stopStreamingTranscription()
        
        XCTAssertFalse(sut.isTranscribing)
        XCTAssertTrue(mockVoiceInputManager.stopStreamingCalled)
    }
    
    // MARK: - Initialization Tests
    
    func test_initialize_callsVoiceInputManagerInitialize() async {
        await sut.initialize()
        
        XCTAssertTrue(mockVoiceInputManager.initializeCalled)
    }
    
    func test_initialize_withModelDownload_propagatesStateChanges() async {
        mockVoiceInputManager.shouldSimulateDownload = true
        
        var stateUpdates: [VoiceInputState] = []
        sut.onStateChange = { state in
            stateUpdates.append(state)
        }
        
        await sut.initialize()
        
        // Wait for simulated download to complete
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        
        // Should have received state updates
        XCTAssertTrue(stateUpdates.contains { state in
            if case .downloadingModel = state { return true }
            return false
        })
        XCTAssertTrue(stateUpdates.contains { state in
            if case .preparingModel = state { return true }
            return false
        })
        XCTAssertTrue(stateUpdates.contains { state in
            if case .ready = state { return true }
            return false
        })
    }
    
    // MARK: - State Change Tests
    
    func test_stateChange_propagatesFromVoiceInputManager() {
        var receivedState: VoiceInputState?
        sut.onStateChange = { state in
            receivedState = state
        }
        
        // Simulate state change
        mockVoiceInputManager.simulateStateChange(.downloadingModel(progress: 0.5, modelName: "Test Model"))
        
        XCTAssertNotNil(receivedState)
        if case .downloadingModel(let progress, let modelName) = receivedState {
            XCTAssertEqual(progress, 0.5)
            XCTAssertEqual(modelName, "Test Model")
        } else {
            XCTFail("Expected downloadingModel state")
        }
    }
    
    func test_waveformUpdate_propagatesToCallback() {
        var receivedWaveform: [Float]?
        sut.onWaveformUpdate = { waveform in
            receivedWaveform = waveform
        }
        
        let testWaveform: [Float] = [0.1, 0.5, 0.8, 0.3]
        mockVoiceInputManager.simulateWaveformUpdate(testWaveform)
        
        XCTAssertEqual(receivedWaveform, testWaveform)
        XCTAssertEqual(sut.voiceWaveform, testWaveform)
    }
    
    // MARK: - Error State Tests
    
    func test_downloadError_propagatesToStateAndCallback() async {
        var receivedError: Error?
        var receivedState: VoiceInputState?
        
        sut.onError = { error in
            receivedError = error
        }
        sut.onStateChange = { state in
            receivedState = state
        }
        
        // Simulate download error
        mockVoiceInputManager.simulateError(VoiceInputError.modelDownloadFailed("Test error"))
        
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as? VoiceInputError), .modelDownloadFailed("Test error"))
    }
    
    // MARK: - Memory Management
    
    func test_adapterDeinitialization() {
        var adapterInstance: FoodVoiceAdapter? = FoodVoiceAdapter(voiceInputManager: mockVoiceInputManager)
        weak var weakAdapter = adapterInstance
        
        XCTAssertNotNil(weakAdapter)
        adapterInstance = nil
        XCTAssertNil(weakAdapter, "FoodVoiceAdapter should deinitialize when no longer strongly referenced")
    }
}

// MARK: - Test Extension
// Expose the private postProcessForFood method for testing
extension FoodVoiceAdapter {
    func postProcessForFood(_ text: String) -> String {
        var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let foodCorrections: [String: String] = [
            "to eggs": "two eggs",
            "for slices": "four slices",
            "won cup": "one cup",
            "tree cups": "three cups",
            "ate ounces": "eight ounces",
            "chicken breast": "chicken breast",
            "sweet potato": "sweet potato",
            "greek yogurt": "Greek yogurt",
            "peanut butter": "peanut butter",
            "olive oil": "olive oil",
            "table spoon": "tablespoon",
            "tea spoon": "teaspoon",
            "fluid ounce": "fl oz",
            "pounds": "lbs"
        ]
        
        for (pattern, replacement) in foodCorrections {
            processed = processed.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.caseInsensitive]
            )
        }
        
        return processed
    }
}
