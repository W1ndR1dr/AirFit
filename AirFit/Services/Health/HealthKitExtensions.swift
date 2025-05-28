import Foundation
import HealthKit

// MARK: - Extensions

extension HeartHealthMetrics.CardioFitnessLevel {
    static func from(vo2Max: Double) -> HeartHealthMetrics.CardioFitnessLevel? {
        // Simplified VO2 Max categorization (would need age/gender specific ranges in production)
        switch vo2Max {
        case 0..<25: return .low
        case 25..<35: return .belowAverage
        case 35..<45: return .average
        case 45..<55: return .aboveAverage
        case 55...: return .high
        default: return nil
        }
    }
}

extension HealthKitManager: HealthKitManaging {}
