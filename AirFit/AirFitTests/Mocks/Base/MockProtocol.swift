import Foundation
import XCTest

/// Base protocol for all mocks to track method calls
protocol MockProtocol: AnyObject {
    var invocations: [String: [Any]] { get set }
    var stubbedResults: [String: Any] { get set }
    var mockLock: NSLock { get }

    func recordInvocation(_ method: String, arguments: Any...)
    func stub<T>(_ method: String, with result: T)
    func verify(_ method: String, called times: Int)
}

extension MockProtocol {
    func recordInvocation(_ method: String, arguments: Any...) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        if invocations[method] == nil {
            invocations[method] = []
        }
        invocations[method]?.append(Array(arguments))
    }

    func stub<T>(_ method: String, with result: T) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        stubbedResults[method] = result
    }

    func verify(_ method: String, called times: Int) {
        mockLock.lock()
        let actual = invocations[method]?.count ?? 0
        mockLock.unlock()
        
        XCTAssertEqual(actual, times, "\(method) was called \(actual) times, expected \(times)")
    }

    func reset() {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        invocations.removeAll()
        stubbedResults.removeAll()
    }
}
