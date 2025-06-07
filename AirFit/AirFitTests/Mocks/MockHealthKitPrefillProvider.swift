@testable import AirFit
import Foundation

// Simple thread-safe wrapper for testing
final class Mutex<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    init(_ value: T) {
        _value = value
    }

    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

final class MockHealthKitPrefillProvider: HealthKitPrefillProviding, @unchecked Sendable {
    private let _result = Mutex<Result<(bed: Date, wake: Date)?, Error>>(.success(nil))

    var result: Result<(bed: Date, wake: Date)?, Error> {
        get { _result.value }
        set { _result.value = newValue }
    }

    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func reset() {
        result = .success(nil)
    }
}
