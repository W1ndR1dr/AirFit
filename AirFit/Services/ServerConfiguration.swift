import SwiftUI

/// Manages server URL configuration with AppStorage persistence.
/// Used by APIClient and onboarding to enable Tailscale/TestFlight distribution.
@MainActor
final class ServerConfiguration: ObservableObject {
    static let shared = ServerConfiguration()

    /// UserDefaults key for server URL (must match @AppStorage key)
    // nonisolated(unsafe) required for access from nonisolated configuredBaseURL
    private nonisolated(unsafe) static let urlKey = "serverURL"

    /// The stored server URL string (persisted via AppStorage for SwiftUI binding)
    @AppStorage("serverURL") private var storedURL: String = ""

    /// Published property for SwiftUI views to observe
    @Published private(set) var currentURL: String = ""

    /// Default Tailscale MagicDNS hostname
    static let defaultURL = "http://airfit-server:8080"

    /// Placeholder shown in text fields
    static let placeholder = "http://airfit-server:8080"

    private init() {
        // Sync published property with stored value
        self.currentURL = storedURL
    }

    /// Thread-safe base URL read for APIClient (can be called from any actor)
    /// Reads directly from UserDefaults which is thread-safe
    nonisolated static var configuredBaseURL: URL {
        let stored = UserDefaults.standard.string(forKey: urlKey) ?? ""
        if let url = URL(string: stored), !stored.isEmpty {
            return url
        }
        // Fallback for development
        #if targetEnvironment(simulator)
        return URL(string: "http://localhost:8080")!
        #else
        // Physical device needs actual IP (localhost = the iPhone itself)
        return URL(string: "http://192.168.86.50:8080")!
        #endif
    }

    /// The base URL for API requests (MainActor-isolated version)
    var baseURL: URL {
        Self.configuredBaseURL
    }

    /// Whether a server URL has been configured
    var isConfigured: Bool {
        !storedURL.isEmpty
    }

    /// Set the server URL (validates format before saving)
    /// - Parameter urlString: The server URL to save
    /// - Returns: True if the URL was valid and saved
    @discardableResult
    func setServer(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic URL validation
        guard let url = URL(string: trimmed),
              url.scheme == "http" || url.scheme == "https",
              url.host != nil else {
            return false
        }

        storedURL = trimmed
        currentURL = trimmed
        return true
    }

    /// Clear the stored server URL (for logout/reset)
    func clearServer() {
        storedURL = ""
        currentURL = ""
    }

    /// Test connection to the configured server
    /// - Returns: True if the server responds to health check
    func testConnection() async -> Bool {
        let healthURL = baseURL.appendingPathComponent("health")

        do {
            let (_, response) = try await URLSession.shared.data(from: healthURL)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Parse a server URL from a QR code
    /// Expected format: airfit://server?url=http://airfit-server:8080
    /// - Parameter qrContent: The scanned QR code content
    /// - Returns: The extracted server URL, or nil if invalid format
    static func parseQRCode(_ qrContent: String) -> String? {
        guard let components = URLComponents(string: qrContent),
              components.scheme == "airfit",
              components.host == "server",
              let urlParam = components.queryItems?.first(where: { $0.name == "url" }),
              let serverURL = urlParam.value,
              URL(string: serverURL) != nil else {
            return nil
        }
        return serverURL
    }

    /// Generate a QR code content string for a server URL
    /// - Parameter serverURL: The server URL to encode
    /// - Returns: The QR code content string
    static func generateQRContent(for serverURL: String) -> String {
        "airfit://server?url=\(serverURL)"
    }
}
