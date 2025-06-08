@testable import AirFit
import XCTest

final class KeychainWrapperTests: XCTestCase {
    private var sut: KeychainWrapper!
    private let testKey = "test_key"

    override func setUp() async throws {
        try super.setUp()
        sut = KeychainWrapper.shared
        // Clean up any existing test data
        try? sut.delete(key: testKey)
    }

    override func tearDown() async throws {
        try? sut.delete(key: testKey)
        try super.tearDown()
    }

    func test_saveData_shouldSucceed() throws {
        let testData = Data("test data".utf8)

        try sut.save(testData, forKey: testKey)

        XCTAssertTrue(sut.exists(key: testKey))
    }

    func test_saveString_shouldSucceed() throws {
        let testString = "test string"

        try sut.saveString(testString, forKey: testKey)

        XCTAssertTrue(sut.exists(key: testKey))
    }

    func test_saveCodable_shouldSucceed() throws {
        let testObject = TestCodableObject(id: 123, name: "Test")

        try sut.saveCodable(testObject, forKey: testKey)

        XCTAssertTrue(sut.exists(key: testKey))
    }

    func test_loadData_shouldReturnSavedData() throws {
        let testData = Data("test data".utf8)
        try sut.save(testData, forKey: testKey)

        let retrievedData = try sut.load(key: testKey)

        XCTAssertEqual(retrievedData, testData)
    }

    func test_loadString_shouldReturnSavedString() throws {
        let testString = "test string"
        try sut.saveString(testString, forKey: testKey)

        let retrievedString = try sut.loadString(key: testKey)

        XCTAssertEqual(retrievedString, testString)
    }

    func test_loadCodable_shouldReturnSavedObject() throws {
        let testObject = TestCodableObject(id: 456, name: "Test Object")
        try sut.saveCodable(testObject, forKey: testKey)

        let retrievedObject = try sut.loadCodable(TestCodableObject.self, key: testKey)

        XCTAssertEqual(retrievedObject.id, testObject.id)
        XCTAssertEqual(retrievedObject.name, testObject.name)
    }

    func test_loadData_withNonExistentKey_shouldThrow() {
        XCTAssertThrowsError(try sut.load(key: "non_existent_key")) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }

    func test_deleteKey_shouldSucceed() throws {
        let testString = "test string"
        try sut.saveString(testString, forKey: testKey)

        try sut.delete(key: testKey)

        XCTAssertFalse(sut.exists(key: testKey))
    }

    func test_deleteNonExistentKey_shouldSucceed() throws {
        // Should not throw even if key doesn't exist
        try sut.delete(key: "non_existent_key")
    }

    func test_exists_withExistingKey_shouldReturnTrue() throws {
        try sut.saveString("test", forKey: testKey)

        XCTAssertTrue(sut.exists(key: testKey))
    }

    func test_exists_withNonExistentKey_shouldReturnFalse() {
        XCTAssertFalse(sut.exists(key: "non_existent_key"))
    }

    func test_update_existingKey_shouldSucceed() throws {
        let originalData = Data("original".utf8)
        let updatedData = Data("updated".utf8)

        try sut.save(originalData, forKey: testKey)
        try sut.update(updatedData, forKey: testKey)

        let retrievedData = try sut.load(key: testKey)
        XCTAssertEqual(retrievedData, updatedData)
    }

    func test_update_nonExistentKey_shouldCreateNew() throws {
        let testData = Data("test".utf8)

        try sut.update(testData, forKey: testKey)

        let retrievedData = try sut.load(key: testKey)
        XCTAssertEqual(retrievedData, testData)
    }
}

// MARK: - Test Helper
private struct TestCodableObject: Codable, Equatable {
    let id: Int
    let name: String
}
