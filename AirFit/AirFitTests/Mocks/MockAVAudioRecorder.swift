import Foundation
import AVFoundation
@testable import AirFit

// MARK: - Mock AVAudioRecorder

final class MockAVAudioRecorder: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockAVAudioRecorder", attributes: .concurrent)
    
    private var _isRecording = false
    private var _isMeteringEnabled = false
    private var _recordingError: Error?
    private var _averagePowerValue: Float = -20.0
    
    private let url: URL
    private let settings: [String: Any]
    
    var isRecording: Bool {
        get { queue.sync { _isRecording } }
        set { queue.async(flags: .barrier) { self._isRecording = newValue } }
    }
    
    var isMeteringEnabled: Bool {
        get { queue.sync { _isMeteringEnabled } }
        set { queue.async(flags: .barrier) { self._isMeteringEnabled = newValue } }
    }
    
    var recordingError: Error? {
        get { queue.sync { _recordingError } }
        set { queue.async(flags: .barrier) { self._recordingError = newValue } }
    }
    
    var averagePowerValue: Float {
        get { queue.sync { _averagePowerValue } }
        set { queue.async(flags: .barrier) { self._averagePowerValue = newValue } }
    }
    
    init(url: URL, settings: [String: Any]) throws {
        self.url = url
        self.settings = settings
        
        if let error = recordingError {
            throw error
        }
    }
    
    func record() -> Bool {
        guard recordingError == nil else { return false }
        isRecording = true
        return true
    }
    
    func stop() {
        isRecording = false
        // Create a dummy audio file for testing
        try? "dummy audio data".write(to: url, atomically: true, encoding: .utf8)
    }
    
    func updateMeters() {
        // Simulate meter updates
    }
    
    func averagePower(forChannel channelNumber: Int) -> Float {
        return averagePowerValue
    }
    
    // MARK: - Test Stubbing
    func stubRecordingError(_ error: Error?) {
        recordingError = error
    }
    
    func stubAveragePower(_ power: Float) {
        averagePowerValue = power
    }
    
    // MARK: - Reset
    func reset() {
        isRecording = false
        isMeteringEnabled = false
        recordingError = nil
        averagePowerValue = -20.0
    }
}
