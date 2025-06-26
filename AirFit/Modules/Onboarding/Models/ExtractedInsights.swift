import Foundation

/// Insights extracted from the onboarding conversation for user confirmation
struct ExtractedInsights: Codable, Sendable {
    let primaryGoal: String
    let keyObstacles: [String]
    let exercisePreferences: [String]
    let currentFitnessLevel: String
    let dailySchedule: String
    let motivationalNeeds: [String]
    let communicationStyle: String

    /// Create a summary for display
    var summary: String {
        var points: [String] = []

        points.append("Your main goal is to \(primaryGoal)")

        if !keyObstacles.isEmpty {
            points.append("You're working around: \(keyObstacles.joined(separator: ", "))")
        }

        if !exercisePreferences.isEmpty {
            points.append("You enjoy: \(exercisePreferences.joined(separator: ", "))")
        }

        points.append("Your fitness level: \(currentFitnessLevel)")
        points.append("Your schedule: \(dailySchedule)")

        if !motivationalNeeds.isEmpty {
            points.append("You need: \(motivationalNeeds.joined(separator: ", "))")
        }

        return points.joined(separator: "\n")
    }
}
