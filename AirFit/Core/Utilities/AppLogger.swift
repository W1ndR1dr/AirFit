import Foundation
import os.log

/// Centralized logging system for AirFit
public enum AppLogger {
    // MARK: - Categories
    enum Category: String {
        case general = "General"
        case ui = "UI"
        case data = "Data"
        case network = "Network"
        case networking = "Networking"
        case health = "HealthKit"
        case ai = "AI"
        case auth = "Authentication"
        case onboarding = "Onboarding"
        case meals = "Meals"
        case performance = "Performance"
        case app = "App"
        case storage = "Storage"

        var osLog: OSLog {
            OSLog(subsystem: subsystem, category: rawValue)
        }
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.airfit.app"

    // MARK: - Logging Methods
    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        log(message, category: category, level: .debug, file: file, function: function, line: line)
        #endif
    }

    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }

    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .default, file: file, function: function, line: line)
    }

    static func error(
        _ message: String,
        error: Error? = nil,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += "\nError: \(error.localizedDescription)"
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
                fullMessage += "\nUnderlying: \(underlyingError.localizedDescription)"
            }
        }
        log(fullMessage, category: category, level: .error, file: file, function: function, line: line)
    }

    static func fault(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .fault, file: file, function: function, line: line)
    }

    // MARK: - Private Methods
    private static func log(
        _ message: String,
        category: Category,
        level: OSLogType,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"

        os_log("%{public}@", log: category.osLog, type: level, logMessage)

        #if DEBUG
        let emoji = emojiForLevel(level)
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        debugPrint("\(emoji) \(timestamp) [\(category.rawValue)] \(logMessage)")
        #endif
    }

    private static func emojiForLevel(_ level: OSLogType) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .default: return "⚠️"
        case .error: return "❌"
        case .fault: return "💥"
        default: return "📝"
        }
    }
}

// MARK: - Performance Logging
extension AppLogger {
    static func measure<T>(
        _ label: String,
        category: Category = .performance,
        operation: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1_000
            debug("\(label) took \(String(format: "%.2f", timeElapsed))ms", category: category)
        }
        return try operation()
    }

    static func measureAsync<T>(
        _ label: String,
        category: Category = .performance,
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1_000
            debug("\(label) took \(String(format: "%.2f", timeElapsed))ms", category: category)
        }
        return try await operation()
    }
}
