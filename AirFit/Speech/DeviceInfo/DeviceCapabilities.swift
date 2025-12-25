import Foundation

/// Detects device hardware capabilities for model recommendations
actor DeviceCapabilities {
    static let shared = DeviceCapabilities()

    // MARK: - Types

    struct DeviceInfo: Sendable {
        let identifier: String
        let marketingName: String
        let ramGB: Int
        let isHighPerformance: Bool

        var description: String {
            "\(marketingName) (\(ramGB) GB RAM)"
        }
    }

    // MARK: - Private Properties

    private var cachedInfo: DeviceInfo?

    // MARK: - Public API

    /// Get device info (cached after first call)
    func detect() -> DeviceInfo {
        if let cached = cachedInfo {
            return cached
        }

        let identifier = Self.getMachineIdentifier()
        let ramGB = Self.getPhysicalMemoryGB()
        let marketingName = Self.marketingName(for: identifier)
        let isHighPerformance = ramGB >= 8

        let info = DeviceInfo(
            identifier: identifier,
            marketingName: marketingName,
            ramGB: ramGB,
            isHighPerformance: isHighPerformance
        )

        cachedInfo = info
        return info
    }

    // MARK: - Hardware Detection

    /// Get the hw.machine identifier (e.g., "iPhone17,1")
    private static func getMachineIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(decoding: machine.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    /// Get physical memory in GB (rounded)
    private static func getPhysicalMemoryGB() -> Int {
        let bytes = ProcessInfo.processInfo.physicalMemory
        return Int(bytes / 1_073_741_824) // 1 GiB
    }

    // MARK: - Device Mapping

    /// Map hw.machine identifier to marketing name
    private static func marketingName(for identifier: String) -> String {
        // iPhone 16 series (A18)
        let deviceMap: [String: String] = [
            // iPhone 16 series
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",

            // iPhone 15 series
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",

            // iPhone 14 series
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",

            // Simulator
            "arm64": "Simulator",
            "x86_64": "Simulator"
        ]

        return deviceMap[identifier] ?? "iPhone (\(identifier))"
    }
}

// MARK: - Chip Detection

extension DeviceCapabilities {
    /// Chip family for performance profiling
    enum ChipFamily: Sendable {
        case a18Pro     // iPhone 16 Pro/Pro Max
        case a18        // iPhone 16/16 Plus
        case a17Pro     // iPhone 15 Pro/Pro Max
        case a16        // iPhone 15/15 Plus, 14 Pro/Pro Max
        case a15        // iPhone 14/14 Plus, 13 series
        case older
        case simulator

        var supportsLargeModels: Bool {
            switch self {
            case .a18Pro, .a18, .a17Pro, .a16:
                return true
            default:
                return false
            }
        }
    }

    /// Detect chip family from identifier
    func chipFamily() -> ChipFamily {
        let info = detect()
        let id = info.identifier

        // iPhone 16 series
        if id.hasPrefix("iPhone17,1") || id.hasPrefix("iPhone17,2") {
            return .a18Pro
        }
        if id.hasPrefix("iPhone17,3") || id.hasPrefix("iPhone17,4") {
            return .a18
        }

        // iPhone 15 series
        if id.hasPrefix("iPhone16,1") || id.hasPrefix("iPhone16,2") {
            return .a17Pro
        }
        if id.hasPrefix("iPhone15,4") || id.hasPrefix("iPhone15,5") {
            return .a16
        }

        // iPhone 14 Pro
        if id.hasPrefix("iPhone15,2") || id.hasPrefix("iPhone15,3") {
            return .a16
        }

        // iPhone 14 (non-Pro)
        if id.hasPrefix("iPhone14,7") || id.hasPrefix("iPhone14,8") {
            return .a15
        }

        // Simulator
        if id == "arm64" || id == "x86_64" {
            return .simulator
        }

        return .older
    }
}
