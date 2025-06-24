import Foundation
import AVFoundation
@testable import AirFit

// MARK: - Mock AVAudioSession

final class MockAVAudioSession: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockAVAudioSession", attributes: .concurrent)
    
    private var _recordPermissionResponse = true
    private var _categorySetError: Error?
    private var _activationError: Error?
    private var _isActive = false
    private var _category: AVAudioSession.Category = .playAndRecord
    
    var recordPermissionResponse: Bool {
        get { queue.sync { _recordPermissionResponse } }
        set { queue.async(flags: .barrier) { self._recordPermissionResponse = newValue } }
    }
    
    var categorySetError: Error? {
        get { queue.sync { _categorySetError } }
        set { queue.async(flags: .barrier) { self._categorySetError = newValue } }
    }
    
    var activationError: Error? {
        get { queue.sync { _activationError } }
        set { queue.async(flags: .barrier) { self._activationError = newValue } }
    }
    
    var isActive: Bool {
        get { queue.sync { _isActive } }
        set { queue.async(flags: .barrier) { self._isActive = newValue } }
    }
    
    var category: AVAudioSession.Category {
        get { queue.sync { _category } }
        set { queue.async(flags: .barrier) { self._category = newValue } }
    }
    
    func requestRecordPermission(_ response: @escaping @Sendable (Bool) -> Void) {
        let permission = recordPermissionResponse
        DispatchQueue.main.async {
            response(permission)
        }
    }
    
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        if let error = categorySetError {
            throw error
        }
        self.category = category
    }
    
    func setActive(_ active: Bool) throws {
        if let error = activationError {
            throw error
        }
        isActive = active
    }
    
    // MARK: - Test Stubbing
    func stubCategorySetError(_ error: Error?) {
        categorySetError = error
    }
    
    func stubActivationError(_ error: Error?) {
        activationError = error
    }
    
    // MARK: - Reset
    func reset() {
        recordPermissionResponse = true
        categorySetError = nil
        activationError = nil
        isActive = false
        category = .playAndRecord
    }
}
