import Foundation

final class NetworkClient: NetworkClientProtocol {
    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Request
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(from: endpoint)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                AppLogger.error("Decoding failed for \(T.self)",
                              error: error,
                              category: .networking)
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.error("Network request failed",
                          error: error,
                          category: .networking)
            throw NetworkError.networkError(error)
        }
    }

    // MARK: - Upload
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        var request = try buildRequest(from: endpoint)
        request.httpBody = data

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: nil)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.error("Upload failed",
                          error: error,
                          category: .networking)
            throw NetworkError.networkError(error)
        }
    }

    // MARK: - Download
    func download(from endpoint: Endpoint) async throws -> Data {
        let request = try buildRequest(from: endpoint)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
            }

            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.error("Download failed",
                          error: error,
                          category: .networking)
            throw NetworkError.networkError(error)
        }
    }

    // MARK: - Helpers
    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(string: APIConstants.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = AppConstants.API.timeoutInterval

        // Default headers
        request.setValue(APIConstants.ContentType.json, forHTTPHeaderField: APIConstants.Headers.contentType)
        request.setValue(APIConstants.ContentType.json, forHTTPHeaderField: APIConstants.Headers.accept)
        request.setValue(userAgent, forHTTPHeaderField: APIConstants.Headers.userAgent)

        // Custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Body
        request.httpBody = endpoint.body

        return request
    }

    private var userAgent: String {
        let appVersion = AppConstants.appVersion
        let buildNumber = AppConstants.buildNumber
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "AirFit/\(appVersion) (Build \(buildNumber); \(osVersion))"
    }
}

// MARK: - Convenience Methods
extension NetworkClient {
    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let endpoint = Endpoint(path: path, method: .get, queryItems: queryItems)
        return try await request(endpoint)
    }

    func post<T: Decodable, U: Encodable>(_ path: String, body: U) async throws -> T {
        let data = try encoder.encode(body)
        let endpoint = Endpoint(path: path, method: .post, body: data)
        return try await request(endpoint)
    }

    func put<T: Decodable, U: Encodable>(_ path: String, body: U) async throws -> T {
        let data = try encoder.encode(body)
        let endpoint = Endpoint(path: path, method: .put, body: data)
        return try await request(endpoint)
    }

    func delete(_ path: String) async throws {
        let endpoint = Endpoint(path: path, method: .delete)
        let _: EmptyResponse = try await request(endpoint)
    }
}

// MARK: - Empty Response
struct EmptyResponse: Decodable {}
