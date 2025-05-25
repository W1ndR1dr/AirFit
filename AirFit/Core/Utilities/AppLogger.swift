import Foundation
import os.log

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.airfit.app"
    
    enum LogCategory: String {
        case general = "General"
        case ui = "UI"
        case data = "Data"
        case healthKit = "HealthKit"
        case network = "Network"
        case ai = "AI"
        case onboarding = "Onboarding"
        case dashboard = "Dashboard"
        case settings = "Settings"
        case error = "Error"
        case performance = "Performance"
    }
    
    private static func getOSLog(category: LogCategory) -> OSLog {
        return OSLog(subsystem: subsystem, category: category.rawValue)
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
    
    static func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
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
    
    static func fault(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .fault, file: file, function: function, line: line)
    }
} 