import Foundation

extension URLRequest {

    /// Add common headers for API requests
    mutating func addCommonHeaders() {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }

    /// Add streaming headers for SSE
    mutating func addStreamingHeaders() {
        setValue("text/event-stream", forHTTPHeaderField: "Accept")
        setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    }

    /// Add authorization header
    mutating func addAuthorization(_ token: String, type: String = "Bearer") {
        setValue("\(type) \(token)", forHTTPHeaderField: "Authorization")
    }

    /// Set JSON body
    mutating func setJSONBody<T: Encodable>(_ body: T) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        httpBody = try encoder.encode(body)
    }

    /// Set raw JSON body from dictionary
    mutating func setJSONBody(_ body: [String: Any]) throws {
        httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    }

    /// Add query parameters
    mutating func addQueryParameters(_ parameters: [String: String]) {
        guard let url = url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = (components.queryItems ?? []) + queryItems
        self.url = components.url
    }

    /// Log request details for debugging
    func logDetails(category: AppLogger.Category = .networking) {
        var details = ["URL: \(url?.absoluteString ?? "nil")"]
        details.append("Method: \(httpMethod ?? "GET")")

        if let headers = allHTTPHeaderFields, !headers.isEmpty {
            let sanitizedHeaders = headers.map { key, value in
                // Sanitize sensitive headers
                if key.lowercased().contains("authorization") || key.lowercased().contains("api-key") {
                    return "\(key): [REDACTED]"
                }
                return "\(key): \(value)"
            }
            details.append("Headers: \(sanitizedHeaders.joined(separator: ", "))")
        }

        if let body = httpBody {
            details.append("Body size: \(body.count) bytes")
        }

        AppLogger.debug("Request: \(details.joined(separator: " | "))", category: category)
    }

    /// Create a cURL command for debugging
    var cURLCommand: String {
        var command = ["curl -v"]

        // Method
        if let method = httpMethod, method != "GET" {
            command.append("-X \(method)")
        }

        // Headers
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers {
                // Sanitize sensitive headers
                if key.lowercased().contains("authorization") || key.lowercased().contains("api-key") {
                    command.append("-H '\(key): [REDACTED]'")
                } else {
                    command.append("-H '\(key): \(value)'")
                }
            }
        }

        // Body
        if let body = httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            // Escape single quotes in JSON
            let escaped = bodyString.replacingOccurrences(of: "'", with: "'\"'\"'")
            command.append("-d '\(escaped)'")
        }

        // URL
        if let url = url {
            command.append("'\(url.absoluteString)'")
        }

        return command.joined(separator: " \\\n  ")
    }

    // MARK: - Private Helpers

    private var userAgent: String {
        let appVersion = AppConstants.appVersion
        let buildNumber = AppConstants.buildNumber
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = "iOS Device" // Generic model string to avoid MainActor isolation

        return "AirFit/\(appVersion) (Build \(buildNumber); \(deviceModel); \(osVersion))"
    }
}
