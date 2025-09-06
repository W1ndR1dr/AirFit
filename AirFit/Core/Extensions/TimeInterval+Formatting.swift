import Foundation

extension TimeInterval {
    /// Formats the time interval into a human readable duration string.
    /// - Parameter style: The units style to use when formatting. Defaults to `.abbreviated`.
    /// - Returns: Formatted duration string.
    func formattedDuration(style: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = style
        formatter.allowedUnits = self >= 3_600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? "0m"
    }
}
