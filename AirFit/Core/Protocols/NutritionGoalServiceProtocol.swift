import Foundation

@MainActor
protocol NutritionGoalServiceProtocol: ServiceProtocol {
    /// Computes and persists today's adjusted nutrition targets based on activity and recent intake.
    func adjustTodayTargets(for user: User, base: DynamicNutritionTargets) async throws -> NutritionTargets
    /// Returns the most recent applied adjustment percentage (e.g., +0.08 for +8%) for today, if any.
    func todayAdjustmentPercent(for user: User) async -> Double?
}

