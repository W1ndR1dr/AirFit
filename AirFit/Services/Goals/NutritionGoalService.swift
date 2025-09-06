import Foundation
import SwiftData

@MainActor
final class NutritionGoalService: NutritionGoalServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "nutrition-goal-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true }

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let healthKit: HealthKitManaging

    init(modelContext: ModelContext, healthKit: HealthKitManaging) {
        self.modelContext = modelContext
        self.healthKit = healthKit
    }

    func configure() async throws { _isConfigured = true }
    func reset() async { _isConfigured = false }
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(status: .healthy, lastCheckTime: Date(), responseTime: nil, errorMessage: nil, metadata: [:])
    }

    // MARK: - Public
    func adjustTodayTargets(for user: User, base: DynamicNutritionTargets) async throws -> NutritionTargets {
        let today = Calendar.current.startOfDay(for: Date())

        // Compute signals
        let activityBonus = await activityAdjustmentPercent(for: today)
        let intakeTrend = try recentIntakeAdjustmentPercent(for: user, days: 3)

        // Combine and clamp
        let rawPct = activityBonus + intakeTrend
        let pct = max(min(rawPct, 0.15), -0.15)

        // Apply to calorie target; keep macros proportional except protein (mild adjust)
        let calories = base.totalCalories * (1 + pct)
        let protein = base.protein * (1 + (pct * 0.25))
        // Keep carbs/fat proportional to maintain calorie balance
        let remainingCalories = max(0, calories - protein * 4)
        let fatCalories = base.fat * 9 * (1 + pct * 0.5)
        let fat = max(0, fatCalories / 9)
        let carbsCalories = max(0, remainingCalories - fat * 9)
        let carbs = max(0, carbsCalories / 4)

        let targets = NutritionTargets(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: 25 // unchanged default for now
        )

        // Persist record
        let rationale = rationaleString(activity: activityBonus, intake: intakeTrend)
        try upsertAdjustment(for: user, date: today, percent: pct, targets: targets, rationale: rationale)

        return targets
    }

    func todayAdjustmentPercent(for user: User) async -> Double? {
        let today = Calendar.current.startOfDay(for: Date())
        let userId = user.id
        var descriptor = FetchDescriptor<DailyNutritionAdjustment>(
            predicate: #Predicate { adj in
                adj.userID == userId && adj.date == today
            }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first?.percent
    }

    // MARK: - Internals
    private func activityAdjustmentPercent(for date: Date) async -> Double {
        // Consider today's active energy vs a baseline (~300 kcal) to adjust calories ±10% max
        do {
            let metrics = try await healthKit.fetchTodayActivityMetrics()
            let active = metrics.activeEnergyBurned?.value ?? 0
            let baseline: Double = 300
            let delta = (active - baseline) / max(baseline, 1)
            // Scale and clamp to ±0.10
            return max(min(delta * 0.5, 0.10), -0.10)
        } catch {
            return 0
        }
    }

    private func recentIntakeAdjustmentPercent(for user: User, days: Int) throws -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        let userId = user.id
        let desc = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.user?.id == userId && entry.loggedAt >= start
            }
        )
        let entries = try modelContext.fetch(desc)

        // Aggregate per day
        var totalsByDay: [Date: Double] = [:]
        for e in entries {
            let d = calendar.startOfDay(for: e.loggedAt)
            totalsByDay[d, default: 0] += Double(e.totalCalories)
        }

        guard !totalsByDay.isEmpty else { return 0 }

        // Compare to baseline 2,000 kcal (fallback)
        let baseline = 2000.0
        let avg = totalsByDay.values.reduce(0, +) / Double(totalsByDay.count)
        let delta = (avg - baseline) / baseline
        // Scale lightly; clamp to ±0.08
        return max(min(delta * 0.5, 0.08), -0.08)
    }

    private func upsertAdjustment(
        for user: User,
        date: Date,
        percent: Double,
        targets: NutritionTargets,
        rationale: String?
    ) throws {
        let userId = user.id
        var desc = FetchDescriptor<DailyNutritionAdjustment>(
            predicate: #Predicate { adj in
                adj.userID == userId && adj.date == date
            }
        )
        desc.fetchLimit = 1
        if let existing = try modelContext.fetch(desc).first {
            existing.percent = percent
            existing.calories = targets.calories
            existing.protein = targets.protein
            existing.carbs = targets.carbs
            existing.fat = targets.fat
            existing.fiber = targets.fiber
            existing.rationale = rationale
        } else {
            let rec = DailyNutritionAdjustment(
                date: date,
                userID: user.id,
                percent: percent,
                calories: targets.calories,
                protein: targets.protein,
                carbs: targets.carbs,
                fat: targets.fat,
                fiber: targets.fiber,
                rationale: rationale
            )
            modelContext.insert(rec)
        }
        try modelContext.save()
    }

    private func rationaleString(activity: Double, intake: Double) -> String {
        var parts: [String] = []
        if activity != 0 { parts.append(String(format: "activity %.0f%%", activity * 100)) }
        if intake != 0 { parts.append(String(format: "intake %.0f%%", intake * 100)) }
        return parts.isEmpty ? "baseline" : parts.joined(separator: ", ")
    }
}
