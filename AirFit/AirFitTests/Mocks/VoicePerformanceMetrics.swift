import Foundation
@testable import AirFit

// MARK: - Performance Testing Utilities

final class VoicePerformanceMetrics: @unchecked Sendable {
    static func measureTranscriptionLatency<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, latency: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        return (result, latency)
    }

    static func measureMemoryUsage<T>(
        operation: () throws -> T
    ) rethrows -> (result: T, memoryDelta: Int64) {
        let startMemory = getMemoryUsage()
        let result = try operation()
        let endMemory = getMemoryUsage()
        let delta = endMemory - startMemory
        return (result, delta)
    }

    private static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}
