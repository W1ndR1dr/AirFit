import Foundation

/// Readiness assessment engine for recovery-based training guidance.
///
/// Evidence-based design principles:
/// - Single-day HRV is noise (20-30% variance) - only use deviation from 7-day baseline
/// - 14 days minimum data required before any readiness assessment
/// - Categorical output (Great/Good/Moderate/Rest) - not numeric scores
/// - Bedtime consistency is a primary sleep metric
/// - No SpO2, VO2 Max, or other bro-science metrics
@MainActor
class ReadinessEngine: ObservableObject {
    private let healthKit = HealthKitManager()

    // MARK: - Types

    /// Overall readiness category (not a numeric score)
    enum ReadinessCategory: String, CaseIterable {
        case great = "Great"        // All indicators positive, train hard
        case good = "Good"          // Most indicators positive, normal training
        case moderate = "Moderate"  // Mixed signals, reduce intensity 20-30%
        case rest = "Rest"          // Multiple concerning indicators, recovery day

        var description: String {
            switch self {
            case .great: return "All systems go. Train hard."
            case .good: return "Normal training recommended."
            case .moderate: return "Consider reduced intensity today."
            case .rest: return "Recovery day recommended."
            }
        }

        var icon: String {
            switch self {
            case .great: return "flame.fill"
            case .good: return "checkmark.circle.fill"
            case .moderate: return "exclamationmark.circle.fill"
            case .rest: return "bed.double.fill"
            }
        }
    }

    /// Individual readiness indicator
    struct Indicator: Identifiable {
        let id = UUID()
        let name: String
        let isPositive: Bool
        let detail: String
        let weight: Double  // 0.0-1.0

        var icon: String {
            isPositive ? "checkmark.circle.fill" : "circle"
        }
    }

    /// Complete readiness assessment result
    struct Assessment {
        let category: ReadinessCategory
        let indicators: [Indicator]
        let positiveCount: Int
        let totalCount: Int
        let isBaselineReady: Bool
        let baselineProgress: BaselineProgress?

        var summary: String {
            if !isBaselineReady, let progress = baselineProgress {
                return "Building baseline: Day \(progress.currentDays) of \(progress.requiredDays)"
            }
            return "\(positiveCount) of \(totalCount) indicators positive"
        }
    }

    /// Baseline building progress
    struct BaselineProgress {
        let currentDays: Int
        let requiredDays: Int = 14
        let hrvDays: Int
        let sleepDays: Int
        let rhrDays: Int

        var isReady: Bool { currentDays >= requiredDays }
        var progressPercent: Double { Double(currentDays) / Double(requiredDays) }
    }

    // MARK: - Weights (from plan)

    private let hrvWeight: Double = 0.35
    private let sleepWeight: Double = 0.30
    private let rhrWeight: Double = 0.20
    private let trainingLoadWeight: Double = 0.15

    // MARK: - Thresholds

    /// HRV deviation thresholds (percent from baseline)
    private let hrvDeviationGood: Double = -5.0      // Within 5% of baseline = good
    private let hrvDeviationConcerning: Double = -15.0  // >15% below = concerning

    /// Sleep thresholds
    private let minSleepHours: Double = 6.5
    private let targetSleepHours: Double = 7.5

    /// RHR deviation thresholds (bpm from baseline)
    private let rhrDeviationGood: Double = 3.0       // Within 3 bpm = good
    private let rhrDeviationConcerning: Double = 8.0 // >8 bpm above = concerning

    // MARK: - Public API

    /// Compute today's readiness assessment
    func getReadinessAssessment() async -> Assessment {
        // Check baseline readiness first
        let progress = await getBaselineProgress()

        guard progress.isReady else {
            return Assessment(
                category: .good,  // Default to "good" while building baseline
                indicators: [],
                positiveCount: 0,
                totalCount: 0,
                isBaselineReady: false,
                baselineProgress: progress
            )
        }

        // Fetch ALL required data once
        let today = Date()
        async let snapshotTask = healthKit.getDailySnapshot(for: today)
        async let hrvBaselineTask = healthKit.getHRVBaseline()
        async let rhrBaselineTask = healthKit.getRestingHRBaseline()
        async let sleepBreakdownTask = healthKit.getSleepBreakdown(for: today)

        let (snapshot, hrvBaseline, rhrBaseline, sleepBreakdown) = await (
            snapshotTask,
            hrvBaselineTask,
            rhrBaselineTask,
            sleepBreakdownTask
        )

        // Compute indicators from shared data (no more async)
        var indicators: [Indicator] = []

        // 1. HRV indicator (35% weight)
        if let hrvIndicator = computeHRVIndicator(snapshot: snapshot, baseline: hrvBaseline) {
            indicators.append(hrvIndicator)
        }

        // 2. Sleep indicator (30% weight)
        if let sleepIndicator = computeSleepIndicator(breakdown: sleepBreakdown) {
            indicators.append(sleepIndicator)
        }

        // 3. Resting HR indicator (20% weight)
        if let rhrIndicator = computeRHRIndicator(snapshot: snapshot, baseline: rhrBaseline) {
            indicators.append(rhrIndicator)
        }

        // 4. Training load indicator (15% weight)
        // Note: We don't have Hevy training load data directly available here
        // This could be added later by integrating with HevyCacheManager
        // For now, we'll use the 3 available indicators

        // Compute category from weighted score
        let positiveCount = indicators.filter { $0.isPositive }.count
        let totalCount = indicators.count
        let category = computeCategory(from: indicators)

        return Assessment(
            category: category,
            indicators: indicators,
            positiveCount: positiveCount,
            totalCount: totalCount,
            isBaselineReady: true,
            baselineProgress: progress
        )
    }

    // MARK: - Baseline Progress

    private func getBaselineProgress() async -> BaselineProgress {
        // Check how many UNIQUE DAYS of data we have for each metric
        // Important: Count distinct calendar days, not sample counts
        // (multiple HRV/RHR samples can occur per day)
        async let hrvHistory = healthKit.getHRVHistory(days: 14)
        async let rhrHistory = healthKit.getRestingHRHistory(days: 14)
        async let sleepBreakdowns = healthKit.getRecentSleepBreakdowns(nights: 14)

        let calendar = Calendar.current

        // Count unique days for HRV (returns [(date: Date, value: Double)])
        let hrvUniqueDays = Set(await hrvHistory.map { calendar.startOfDay(for: $0.date) }).count

        // Count unique days for RHR (returns [(date: Date, bpm: Double)])
        let rhrUniqueDays = Set(await rhrHistory.map { calendar.startOfDay(for: $0.date) }).count

        // Sleep breakdowns are typically one per night
        let sleepDays = await sleepBreakdowns.count

        // Use minimum of all three as overall progress
        let currentDays = min(hrvUniqueDays, rhrUniqueDays, sleepDays)

        return BaselineProgress(
            currentDays: currentDays,
            hrvDays: hrvUniqueDays,
            sleepDays: sleepDays,
            rhrDays: rhrUniqueDays
        )
    }

    // MARK: - Individual Indicators

    private func computeHRVIndicator(
        snapshot: DailyHealthSnapshot,
        baseline: HRVBaseline?
    ) -> Indicator? {
        guard let baseline = baseline,
              baseline.isReliable else {
            return nil
        }

        guard let todayHRV = snapshot.hrvMs else {
            return nil
        }

        let deviation = baseline.percentDeviation(for: todayHRV)

        let isPositive = deviation >= hrvDeviationGood
        let detail: String

        if deviation >= 5 {
            detail = "HRV \(Int(deviation))% above baseline"
        } else if deviation >= hrvDeviationGood {
            detail = "HRV within normal range"
        } else if deviation >= hrvDeviationConcerning {
            detail = "HRV \(Int(abs(deviation)))% below baseline"
        } else {
            detail = "HRV significantly below baseline"
        }

        return Indicator(
            name: "HRV",
            isPositive: isPositive,
            detail: detail,
            weight: hrvWeight
        )
    }

    private func computeSleepIndicator(
        breakdown: SleepBreakdown?
    ) -> Indicator? {
        guard let breakdown = breakdown else {
            return nil
        }

        let hours = breakdown.totalSleep
        let efficiency = breakdown.efficiency

        // Sleep is positive if duration >= 6.5h AND efficiency >= 80%
        let isPositive = hours >= minSleepHours && efficiency >= 80

        let detail: String
        if hours >= targetSleepHours && efficiency >= 85 {
            detail = String(format: "%.1fh sleep, %d%% efficiency", hours, Int(efficiency))
        } else if hours >= minSleepHours {
            detail = String(format: "%.1fh sleep (goal: %.1fh)", hours, targetSleepHours)
        } else {
            detail = String(format: "Only %.1fh sleep", hours)
        }

        return Indicator(
            name: "Sleep",
            isPositive: isPositive,
            detail: detail,
            weight: sleepWeight
        )
    }

    private func computeRHRIndicator(
        snapshot: DailyHealthSnapshot,
        baseline: (mean: Double, standardDeviation: Double, sampleCount: Int)?
    ) -> Indicator? {
        guard let baseline = baseline,
              baseline.sampleCount >= 5 else {
            return nil
        }

        guard let todayRHR = snapshot.restingHR else {
            return nil
        }

        let deviation = Double(todayRHR) - baseline.mean

        let isPositive = deviation <= rhrDeviationGood
        let detail: String

        if deviation <= 0 {
            detail = "RHR \(todayRHR) bpm (below baseline)"
        } else if deviation <= rhrDeviationGood {
            detail = "RHR \(todayRHR) bpm (normal)"
        } else if deviation <= rhrDeviationConcerning {
            detail = "RHR \(Int(deviation)) bpm above baseline"
        } else {
            detail = "RHR elevated significantly"
        }

        return Indicator(
            name: "Resting HR",
            isPositive: isPositive,
            detail: detail,
            weight: rhrWeight
        )
    }

    // MARK: - Category Computation

    private func computeCategory(from indicators: [Indicator]) -> ReadinessCategory {
        guard !indicators.isEmpty else {
            return .good  // Default when no data
        }

        // Compute weighted positive score
        let totalWeight = indicators.reduce(0.0) { $0 + $1.weight }
        let positiveWeight = indicators.filter { $0.isPositive }.reduce(0.0) { $0 + $1.weight }

        let positiveRatio = totalWeight > 0 ? positiveWeight / totalWeight : 0.5

        // Also consider raw positive count for simpler assessment
        let positiveCount = indicators.filter { $0.isPositive }.count
        let totalCount = indicators.count

        // Categorical thresholds
        switch (positiveRatio, positiveCount, totalCount) {
        case (0.9..., _, _):
            return .great  // 90%+ weighted positive
        case (0.7..., _, _):
            return .good   // 70-90% weighted positive
        case (0.4..., _, _):
            return .moderate  // 40-70% weighted positive
        default:
            return .rest   // <40% weighted positive
        }
    }
}

