import Foundation

/// Processes memory markers from AI responses.
///
/// Memory markers are special tags the AI uses to note things worth remembering:
/// - `<memory:remember>` - General things to remember
/// - `<memory:callback>` - Inside jokes, phrases to reference later
/// - `<memory:tone>` - Communication style observations
/// - `<memory:thread>` - Topics to follow up on
///
/// These markers are stripped from the displayed response but stored for
/// profile evolution and relationship building.
enum MemoryMarkerProcessor {

    /// Regular expression pattern for memory markers
    /// Matches: <memory:type>content</memory:type>
    private static let markerPattern = try! NSRegularExpression(
        pattern: #"<memory:(\w+)>(.*?)</memory:\1>"#,
        options: [.dotMatchesLineSeparators]
    )

    /// Extract memory markers from a response and return cleaned text.
    ///
    /// - Parameter response: Raw AI response potentially containing markers
    /// - Returns: Tuple of (cleaned text for display, extracted markers)
    static func extractAndStrip(_ response: String) -> (clean: String, markers: [MemoryMarker]) {
        var markers: [MemoryMarker] = []
        let range = NSRange(response.startIndex..., in: response)

        // Find all matches
        let matches = markerPattern.matches(in: response, options: [], range: range)

        for match in matches {
            // Extract type (group 1)
            guard let typeRange = Range(match.range(at: 1), in: response),
                  let contentRange = Range(match.range(at: 2), in: response) else {
                continue
            }

            let type = String(response[typeRange])
            let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            if !content.isEmpty {
                markers.append(MemoryMarker(type: type, content: content))
            }
        }

        // Remove markers from response
        var clean = markerPattern.stringByReplacingMatches(
            in: response,
            options: [],
            range: range,
            withTemplate: ""
        )

        // Clean up extra whitespace from removed markers
        clean = clean.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        return (clean, markers)
    }

    /// Check if a response contains any memory markers.
    static func containsMarkers(_ response: String) -> Bool {
        let range = NSRange(response.startIndex..., in: response)
        return markerPattern.firstMatch(in: response, options: [], range: range) != nil
    }

    /// Format markers for display (debugging/admin use)
    static func formatMarkersForDisplay(_ markers: [MemoryMarker]) -> String {
        markers.map { marker in
            "[\(marker.type)] \(marker.content)"
        }.joined(separator: "\n")
    }
}

// MARK: - Convenience Extensions

extension Array where Element == MemoryMarker {
    /// Filter to specific marker types
    func ofType(_ types: String...) -> [MemoryMarker] {
        filter { types.contains($0.type) }
    }

    /// Get just the callback markers (inside jokes, phrases)
    var callbacks: [MemoryMarker] {
        ofType("callback")
    }

    /// Get just the tone calibration markers
    var toneCalibrations: [MemoryMarker] {
        ofType("tone")
    }

    /// Get just the thread markers (follow-up topics)
    var threads: [MemoryMarker] {
        ofType("thread")
    }

    /// Get just the general remember markers
    var remembers: [MemoryMarker] {
        ofType("remember")
    }
}
