import Foundation
import XCTest

/// Base protocol for all mocks to track method calls
protocol MockProtocol: AnyObject {
    var invocations: [String: [Any]] { get set }
    var stubbedResults: [String: Any] { get set }
    
    func recordInvocation(_ method: String, arguments: Any...)
    func stub<T>(_ method: String, with result: T)
    func verify(_ method: String, called times: Int)
}

extension MockProtocol {
    func recordInvocation(_ method: String, arguments: Any...) {
        if invocations[method] == nil {
            invocations[method] = []
        }
        invocations[method]?.append(arguments)
    }
    
    func stub<T>(_ method: String, with result: T) {
        stubbedResults[method] = result
    }
    
    func verify(_ method: String, called times: Int) {
        let actual = invocations[method]?.count ?? 0
        XCTAssertEqual(actual, times, "\(method) was called \(actual) times, expected \(times)")
    }
    
    func reset() {
        invocations.removeAll()
        stubbedResults.removeAll()
    }
} 
