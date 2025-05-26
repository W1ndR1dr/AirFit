@testable import AirFit
import XCTest

final class KeychainWrapperTests: XCTestCase {
    var sut: KeychainWrapper!
    let testKey = "test_key"
    let testString = "test_value_123"
    let testData = "test_data".data(using: .utf8) ?? Data()
    
    override func setUp() {
        super.setUp()
        sut = KeychainWrapper.shared
        // Clean up any existing test data
        sut.delete(key: testKey)
    }
    
    override func tearDown() {
        sut.delete(key: testKey)
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Save Tests
    func test_saveData_givenValidData_shouldReturnTrue() {
        // Act
        let result = sut.save(testData, for: testKey)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_saveString_givenValidString_shouldReturnTrue() {
        // Act
        let result = sut.saveString(testString, for: testKey)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_saveCodable_givenValidObject_shouldReturnTrue() {
        // Arrange
        let testObject = TestCodableObject(id: 123, name: "Test")
        
        // Act
        let result = sut.saveCodable(testObject, for: testKey)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    // MARK: - Retrieve Tests
    func test_getData_givenSavedData_shouldReturnData() {
        // Arrange
        sut.save(testData, for: testKey)
        
        // Act
        let retrievedData = sut.getData(for: testKey)
        
        // Assert
        XCTAssertEqual(retrievedData, testData)
    }
    
    func test_getString_givenSavedString_shouldReturnString() {
        // Arrange
        sut.saveString(testString, for: testKey)
        
        // Act
        let retrievedString = sut.getString(for: testKey)
        
        // Assert
        XCTAssertEqual(retrievedString, testString)
    }
    
    func test_getCodable_givenSavedObject_shouldReturnObject() {
        // Arrange
        let testObject = TestCodableObject(id: 456, name: "Test Object")
        sut.saveCodable(testObject, for: testKey)
        
        // Act
        let retrievedObject = sut.getCodable(TestCodableObject.self, for: testKey)
        
        // Assert
        XCTAssertEqual(retrievedObject?.id, testObject.id)
        XCTAssertEqual(retrievedObject?.name, testObject.name)
    }
    
    func test_getData_givenNonExistentKey_shouldReturnNil() {
        // Act
        let data = sut.getData(for: "non_existent_key")
        
        // Assert
        XCTAssertNil(data)
    }
    
    // MARK: - Delete Tests
    func test_delete_givenExistingKey_shouldReturnTrue() {
        // Arrange
        sut.saveString(testString, for: testKey)
        
        // Act
        let result = sut.delete(key: testKey)
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertNil(sut.getString(for: testKey))
    }
    
    func test_delete_givenNonExistentKey_shouldReturnTrue() {
        // Act
        let result = sut.delete(key: "non_existent_key")
        
        // Assert
        XCTAssertTrue(result) // Should return true even if key doesn't exist
    }
    
    // MARK: - Clear All Tests
    func test_clearAll_shouldRemoveAllItems() {
        // Arrange
        sut.saveString("value1", for: "key1")
        sut.saveString("value2", for: "key2")
        sut.saveString("value3", for: "key3")
        
        // Act
        sut.clearAll()
        
        // Assert
        XCTAssertNil(sut.getString(for: "key1"))
        XCTAssertNil(sut.getString(for: "key2"))
        XCTAssertNil(sut.getString(for: "key3"))
    }
}

// MARK: - Test Helper
private struct TestCodableObject: Codable, Equatable {
    let id: Int
    let name: String
} 
