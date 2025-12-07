import Foundation

actor APIClient {
    // Change this to your Mac's IP when testing on real device
    // For simulator, localhost works fine
    private let baseURL: URL

    init(baseURL: String = "http://localhost:8080") {
        self.baseURL = URL(string: baseURL)!
    }

    struct ChatRequest: Encodable {
        let message: String
        let system_prompt: String?
        let health_context: [String: String]?
    }

    struct ChatResponse: Decodable {
        let response: String
        let provider: String
        let success: Bool
        let error: String?
    }

    func sendMessage(_ message: String, systemPrompt: String? = nil, healthContext: [String: String]? = nil) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(
            message: message,
            system_prompt: systemPrompt,
            health_context: healthContext
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        if !chatResponse.success {
            throw APIError.llmError(chatResponse.error ?? "Unknown error")
        }

        return chatResponse.response
    }

    func checkHealth() async -> Bool {
        let url = baseURL.appendingPathComponent("health")

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

enum APIError: Error, LocalizedError {
    case serverError
    case llmError(String)

    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Could not connect to server"
        case .llmError(let message):
            return message
        }
    }
}
