import Foundation

public enum Formatters {
    // MARK: - Nested Types

    enum WeightUnit {
        case metric, imperial
    }

    // MARK: - Static Properties

    // MARK: - Number Formatters
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // MARK: - Date Formatters
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let fileName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()

    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols
    }()

    static let shortWeekdaySymbols: [String] = {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols ?? []
    }()

    // MARK: - ISO8601 Formatter
    static let iso8601: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()

    // MARK: - Static Methods

    // MARK: - Custom Formatters
    static func formatCalories(_ calories: Double) -> String {
        "\(integer.string(from: NSNumber(value: calories)) ?? "0") cal"
    }

    static func formatMacro(_ grams: Double, suffix: String = "g") -> String {
        "\(integer.string(from: NSNumber(value: grams)) ?? "0")\(suffix)"
    }

    static func formatWeight(_ kilograms: Double, unit: WeightUnit = .metric) -> String {
        switch unit {
        case .metric:
            return "\(decimal.string(from: NSNumber(value: kilograms)) ?? "0") kg"
        case .imperial:
            let pounds = kilograms.kilogramsToPounds
            return "\(decimal.string(from: NSNumber(value: pounds)) ?? "0") lbs"
        }
    }
}
