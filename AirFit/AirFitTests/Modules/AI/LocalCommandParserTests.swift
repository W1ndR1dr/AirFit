import XCTest
@testable import AirFit

final class LocalCommandParserTests: XCTestCase {
    var sut: LocalCommandParser!

    @MainActor
    func test_parseWaterCommands() {
        sut = LocalCommandParser()
        XCTAssertEqual(sut.parse("log 16oz water"), .logWater(amount: 16, unit: .ounces))
        XCTAssertEqual(sut.parse("log 500ml water"), .logWater(amount: 500, unit: .milliliters))
        XCTAssertEqual(sut.parse("log water"), .logWater(amount: 8, unit: .ounces))
    }

    @MainActor
    func test_parseNavigationCommands() {
        sut = LocalCommandParser()
        XCTAssertEqual(sut.parse("dashboard"), .showDashboard)
        XCTAssertEqual(sut.parse("show settings"), .showSettings)
        XCTAssertEqual(sut.parse("start workout"), .startWorkout)
    }

    @MainActor
    func test_parseQuickLogCommands() {
        sut = LocalCommandParser()
        XCTAssertEqual(sut.parse("log breakfast"), .quickLog(type: .meal(.breakfast)))
    }

    @MainActor
    func test_unrecognizedCommand_shouldReturnNone() {
        sut = LocalCommandParser()
        XCTAssertEqual(sut.parse("random text"), .none)
    }
}
