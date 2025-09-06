import SwiftData
import Foundation

/// Records historical strength data for tracking progression over time
@Model
final class StrengthRecord: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var exerciseName: String
    var oneRepMax: Double
    var recordedDate: Date
    var actualWeight: Double?
    var actualReps: Int?
    var isEstimated: Bool // true if calculated via formula, false if actual 1RM test
    var formula: String? // Which formula was used (e.g., "Epley", "Brzycki")

    // MARK: - Relationships
    var user: User?

    // MARK: - Computed Properties
    var isPersonalRecord: Bool {
        // This would be determined by comparing to previous records
        // Implementation would query other records for this exercise
        true // Placeholder
    }

    var percentageOfMax: Double? {
        guard let weight = actualWeight, oneRepMax > 0 else { return nil }
        return (weight / oneRepMax) * 100
    }

    // MARK: - Initialization
    init(
        exerciseName: String,
        oneRepMax: Double,
        recordedDate: Date = Date(),
        actualWeight: Double? = nil,
        actualReps: Int? = nil,
        isEstimated: Bool = true,
        formula: String? = "Epley"
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.oneRepMax = oneRepMax
        self.recordedDate = recordedDate
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.isEstimated = isEstimated
        self.formula = formula
    }
}
