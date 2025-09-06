import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class SwiftDataCRUDTests: XCTestCase {
    func testUserCreateAndFetchInMemory() throws {
        let container = try TestSupport.makeInMemoryModelContainer()
        let context = container.mainContext

        let user = User(email: "unit@test.com", name: "Unit", preferredUnits: "imperial")
        context.insert(user)

        try context.save()

        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == "unit@test.com" })
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Unit")
    }
}
