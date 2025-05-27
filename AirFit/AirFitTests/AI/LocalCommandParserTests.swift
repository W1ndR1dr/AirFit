import XCTest
@testable import AirFit

final class LocalCommandParserTests: XCTestCase {
    var sut: LocalCommandParser!

    override func setUp() {
        super.setUp()
        sut = LocalCommandParser()
    }

    func test_parseWaterCommands() {
        XCTAssertEqual(sut.parse("log 16oz water"), .logWater(amount: 16, unit: .ounces))
        XCTAssertEqual(sut.parse("log 500ml water"), .logWater(amount: 500, unit: .milliliters))
        XCTAssertEqual(sut.parse("log water"), .logWater(amount: 8, unit: .ounces))
    }

    func test_parseNavigationCommands() {
        XCTAssertEqual(sut.parse("dashboard"), .showDashboard)
        XCTAssertEqual(sut.parse("show settings"), .showSettings)
        XCTAssertEqual(sut.parse("start workout"), .startWorkout)
    }

    func test_parseQuickLogCommands() {
        XCTAssertEqual(sut.parse("log breakfast"), .quickLog(type: .meal(.breakfast)))
    }

    func test_unrecognizedCommand_shouldReturnNone() {
        XCTAssertEqual(sut.parse("random text"), .none)
    }
}
