import Foundation
import os.log

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.airfit"

    enum LogCategory: String {
        case general = "General"
        case ui = "UI"
        case data = "Data"
        case healthKit = "HealthKit"
        case network = "Network"
        case ai = "AI"
        case onboarding = "Onboarding"
    }

    private static func getOSLog(category: LogCategory) -> OSLog {
        OSLog(subsystem: subsystem, category: category.rawValue)
    }

    static func log(
        _ message: String,
        category: LogCategory = .general,
        level: OSLogType = .default,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: getOSLog(category: category), type: level, logMessage)
        #endif
    }

    static func error(
        _ message: String,
        category: LogCategory = .general,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(fileName):\(line)] \(function) - ERROR: \(message)"
        if let error = error {
            logMessage += "\nError Details: \(error.localizedDescription)"
        }
        os_log("%{public}@", log: getOSLog(category: category), type: .error, logMessage)
        #endif
    }
}
