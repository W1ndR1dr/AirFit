import XCTest
@testable import AirFit

final class NetworkClientTests: XCTestCase {
    var sut: NetworkClient!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        sut = NetworkClient(session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Request Tests
    func test_request_givenSuccessfulResponse_shouldReturnDecodedData() async throws {
        // Arrange
        let expectedUser = TestUser(id: 1, name: "John Doe", email: "john@example.com")
        let jsonData = try JSONEncoder().encode(expectedUser)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/user")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockData = jsonData
        mockSession.mockResponse = response
        
        let endpoint = Endpoint(path: "/user", method: .get)
        
        // Act
        let result: TestUser = try await sut.request(endpoint)
        
        // Assert
        XCTAssertEqual(result.id, expectedUser.id)
        XCTAssertEqual(result.name, expectedUser.name)
        XCTAssertEqual(result.email, expectedUser.email)
    }
    
    func test_request_givenHTTPError_shouldThrowHTTPError() async {
        // Arrange
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/user")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockData = Data()
        mockSession.mockResponse = response
        
        let endpoint = Endpoint(path: "/user", method: .get)
        
        // Act & Assert
        do {
            let _: TestUser = try await sut.request(endpoint)
            XCTFail("Should throw error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func test_request_givenInvalidJSON_shouldThrowDecodingError() async {
        // Arrange
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/user")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockData = invalidJSON
        mockSession.mockResponse = response
        
        let endpoint = Endpoint(path: "/user", method: .get)
        
        // Act & Assert
        do {
            let _: TestUser = try await sut.request(endpoint)
            XCTFail("Should throw error")
        } catch let error as NetworkError {
            if case .decodingError = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Upload Tests
    func test_upload_givenSuccessfulResponse_shouldComplete() async throws {
        // Arrange
        let testData = "test data".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/upload")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockResponse = response
        
        let endpoint = Endpoint(path: "/upload", method: .post)
        
        // Act & Assert (should not throw)
        try await sut.upload(testData, to: endpoint)
    }
    
    // MARK: - Download Tests
    func test_download_givenSuccessfulResponse_shouldReturnData() async throws {
        // Arrange
        let expectedData = "downloaded content".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/download")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockData = expectedData
        mockSession.mockResponse = response
        
        let endpoint = Endpoint(path: "/download", method: .get)
        
        // Act
        let result = try await sut.download(from: endpoint)
        
        // Assert
        XCTAssertEqual(result, expectedData)
    }
    
    // MARK: - Convenience Methods Tests
    func test_get_shouldCallRequestWithCorrectEndpoint() async throws {
        // Arrange
        let expectedData = TestUser(id: 1, name: "Test", email: "test@test.com")
        let jsonData = try JSONEncoder().encode(expectedData)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.airfit.com/v1/users")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockData = jsonData
        mockSession.mockResponse = response
        
        // Act
        let result: TestUser = try await sut.get("/users")
        
        // Assert
        XCTAssertEqual(result.id, expectedData.id)
    }
}

// MARK: - Test Models
private struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - Mock URLSession
private class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? URLResponse()
        
        return (data, response)
    }
} 