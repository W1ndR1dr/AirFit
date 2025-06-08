import XCTest

final class SmokeTest: XCTestCase {
    func test_basic_math() {
        XCTAssertEqual(2 + 2, 4)
    }
    
    func test_string_operations() {
        let result = "Hello, " + "World!"
        XCTAssertEqual(result, "Hello, World!")
    }
}