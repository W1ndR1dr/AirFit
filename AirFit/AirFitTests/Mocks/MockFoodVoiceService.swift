import Foundation
@testable import AirFit

// MARK: - MockFoodVoiceService
@MainActor
final class MockFoodVoiceService: FoodVoiceServiceProtocol, MockProtocol {
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    // FoodVoiceServiceProtocol conformance
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var transcribedText: String = ""
    var voiceWaveform: [Float] = []

    // Callbacks
    var onFoodTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    // Stubbed responses
    var stubbedRequestPermissionResult: Bool = true
    var stubbedRequestPermissionError: Error?
    var stubbedStartRecordingError: Error?
    var stubbedStopRecordingResult: String? = "Mock transcription"
    var stubbedTranscriptionUpdates: [String] = []
    var stubbedWaveformUpdates: [[Float]] = []

    func requestPermission() async throws -> Bool {
        recordInvocation("requestPermission")

        if let error = stubbedRequestPermissionError {
            throw error
        }

        return stubbedRequestPermissionResult
    }

    func startRecording() async throws {
        recordInvocation("startRecording")

        if let error = stubbedStartRecordingError {
            throw error
        }

        isRecording = true
        isTranscribing = true

        // Simulate transcription updates
        Task {
            for update in stubbedTranscriptionUpdates {
                guard isRecording else { break }

                transcribedText = update
                onFoodTranscription?(update)

                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            }
        }

        // Simulate waveform updates
        Task {
            for waveform in stubbedWaveformUpdates {
                guard isRecording else { break }

                voiceWaveform = waveform

                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
            }
        }
    }

    func stopRecording() async -> String? {
        recordInvocation("stopRecording")

        isRecording = false
        isTranscribing = false

        if let result = stubbedStopRecordingResult {
            transcribedText = result
            return result
        }

        return transcribedText.isEmpty ? nil : transcribedText
    }

    // Helper methods for testing
    func stubRequestPermission(with result: Bool) {
        stubbedRequestPermissionResult = result
    }

    func stubRequestPermissionError(with error: Error) {
        stubbedRequestPermissionError = error
    }

    func stubStartRecordingError(with error: Error) {
        stubbedStartRecordingError = error
    }

    func stubStopRecording(with result: String?) {
        stubbedStopRecordingResult = result
    }

    func stubTranscriptionUpdates(with updates: [String]) {
        stubbedTranscriptionUpdates = updates
    }

    func stubWaveformUpdates(with waveforms: [[Float]]) {
        stubbedWaveformUpdates = waveforms
    }

    func simulateError(_ error: Error) {
        onError?(error)
    }

    func simulateTranscription(_ text: String) {
        transcribedText = text
        onFoodTranscription?(text)
    }

    // Verify helpers
    func verifyRequestPermission(called times: Int = 1) {
        verify("requestPermission", called: times)
    }

    func verifyStartRecording(called times: Int = 1) {
        verify("startRecording", called: times)
    }

    func verifyStopRecording(called times: Int = 1) {
        verify("stopRecording", called: times)
    }

    // Reset state
    func reset() {
        // Clear invocations
        mockLock.lock()
        invocations.removeAll()
        stubbedResults.removeAll()
        mockLock.unlock()

        // Reset state
        isRecording = false
        isTranscribing = false
        transcribedText = ""
        voiceWaveform = []
        onFoodTranscription = nil
        onError = nil
        stubbedRequestPermissionResult = true
        stubbedRequestPermissionError = nil
        stubbedStartRecordingError = nil
        stubbedStopRecordingResult = "Mock transcription"
        stubbedTranscriptionUpdates = []
        stubbedWaveformUpdates = []
    }
}
