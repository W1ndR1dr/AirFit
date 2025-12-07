import Foundation
import SwiftData

/// Service that syncs nutrition and health data to the server for insights analysis.
/// This enables the AI to find patterns across all data sources.
@MainActor
class InsightsSyncService {
    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()

    /// Sync the last N days of data to the server
    func syncRecentDays(_ days: Int = 7, modelContext: ModelContext) async throws {
        // Get nutrition summaries from SwiftData
        let nutritionSummaries = try await aggregateNutritionByDay(days: days, modelContext: modelContext)

        // Get health snapshots from HealthKit
        let healthSnapshots = await healthKit.getRecentSnapshots(days: days)

        // Combine into sync data
        var syncData: [APIClient.DailySyncData] = []

        let calendar = Calendar.current
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)

            // Find matching nutrition and health data
            let nutrition = nutritionSummaries.first { $0.date == dateString }
            let health = healthSnapshots.first { $0.dateString == dateString }

            syncData.append(APIClient.DailySyncData(
                date: dateString,
                calories: nutrition?.calories ?? 0,
                protein: nutrition?.protein ?? 0,
                carbs: nutrition?.carbs ?? 0,
                fat: nutrition?.fat ?? 0,
                nutrition_entries: nutrition?.entryCount ?? 0,
                steps: health?.steps ?? 0,
                active_calories: health?.activeCalories ?? 0,
                weight_lbs: health?.weightLbs,
                body_fat_pct: health?.bodyFatPct,
                sleep_hours: health?.sleepHours,
                resting_hr: health?.restingHR,
                hrv_ms: health?.hrvMs
            ))
        }

        // Send to server
        _ = try await apiClient.syncInsightsData(syncData)
    }

    /// Aggregate nutrition entries by day for the last N days
    private func aggregateNutritionByDay(days: Int, modelContext: ModelContext) async throws -> [NutritionDaySummary] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        // Fetch all entries in the date range
        let predicate = #Predicate<NutritionEntry> { entry in
            entry.timestamp >= startDate
        }

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let entries = try modelContext.fetch(descriptor)

        // Group by date
        var dailyData: [String: NutritionDaySummary] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for entry in entries {
            let dateString = dateFormatter.string(from: entry.timestamp)

            if var existing = dailyData[dateString] {
                existing.calories += entry.calories
                existing.protein += entry.protein
                existing.carbs += entry.carbs
                existing.fat += entry.fat
                existing.entryCount += 1
                dailyData[dateString] = existing
            } else {
                dailyData[dateString] = NutritionDaySummary(
                    date: dateString,
                    calories: entry.calories,
                    protein: entry.protein,
                    carbs: entry.carbs,
                    fat: entry.fat,
                    entryCount: 1
                )
            }
        }

        return Array(dailyData.values)
    }
}

/// Summary of nutrition for a single day
struct NutritionDaySummary {
    let date: String  // YYYY-MM-DD
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var entryCount: Int
}
