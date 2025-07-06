import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
final class BodyViewModel: ErrorHandling {
    // MARK: - State
    private(set) var currentMetrics: BodyMetrics?
    private(set) var weightHistory: [BodyMetrics] = []
    private(set) var isLoading = false
    private var healthKitObserver: Any?

    // Recovery metrics
    private(set) var restingHeartRate: Int?
    private(set) var hrv: Measurement<UnitDuration>?
    private(set) var sleepQuality: String?
    private(set) var energyLevel: Int?

    // Trends
    private(set) var heartRateTrend: BodyMetrics.Trend?
    private(set) var hrvTrend: BodyMetrics.Trend?

    // User preferences
    var weightGoal: Double?
    var userGoal: UserGoal = .maintenance

    // Error handling
    var error: AppError?
    var isShowingError = false

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let healthKitManager: HealthKitManaging
    private let contextAssembler: ContextAssembler

    // MARK: - Types
    enum UserGoal {
        case weightLoss
        case muscleGain
        case maintenance
        case recomposition
    }

    // MARK: - Init
    init(
        modelContext: ModelContext,
        user: User,
        healthKitManager: HealthKitManaging
    ) {
        self.modelContext = modelContext
        self.user = user
        self.healthKitManager = healthKitManager
        self.contextAssembler = ContextAssembler(healthKitManager: healthKitManager)
    }

    // MARK: - Loading
    func loadLatestMetrics() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch from HealthKit
            currentMetrics = try await healthKitManager.fetchLatestBodyMetrics()

            // Get heart metrics
            let heartMetrics = try await healthKitManager.fetchHeartHealthMetrics()
            restingHeartRate = heartMetrics.restingHeartRate
            hrv = heartMetrics.hrv

            // Get sleep data
            if let sleepSession = try await healthKitManager.fetchLastNightSleep() {
                sleepQuality = sleepSession.quality?.rawValue
            }

            // Calculate trends
            await calculateTrends()

            AppLogger.info("Loaded body metrics successfully", category: .health)
        } catch {
            handleError(error)
            AppLogger.error("Failed to load body metrics", error: error, category: .health)
        }
    }

    func loadWeightHistory() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch weight history from HealthKit (last 30 days)
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            weightHistory = try await healthKitManager.fetchBodyMetricsHistory(
                from: startDate,
                to: endDate
            )

            AppLogger.info("Loaded \(weightHistory.count) weight history entries from HealthKit", category: .health)
        } catch {
            handleError(error)
            AppLogger.error("Failed to load weight history", error: error, category: .health)
        }
    }

    /// Sets up observer for HealthKit changes
    func setupHealthKitObserver() {
        Task {
            do {
                // Observe changes to body mass and body fat percentage
                try await healthKitManager.observeBodyMetrics { [weak self] in
                    Task { @MainActor [weak self] in
                        // Reload data when HealthKit changes
                        await self?.loadLatestMetrics()
                        await self?.loadWeightHistory()
                    }
                }
                AppLogger.info("Set up HealthKit observer for body metrics", category: .health)
            } catch {
                AppLogger.error("Failed to set up HealthKit observer", error: error, category: .health)
            }
        }
    }

    // MARK: - Data Management
    func addMeasurement(type: String, value: String, date: Date) async {
        guard let numericValue = Double(value) else {
            handleError(AppError.validationError(message: "Invalid number"))
            return
        }

        // Save to HealthKit if it's weight or body fat
        switch type {
        case "Weight":
            // Save weight to HealthKit
            do {
                try await healthKitManager.saveBodyMass(weightKg: numericValue, date: date)
                AppLogger.info("Saved weight: \(numericValue)kg to HealthKit", category: .health)
            } catch {
                handleError(error)
                AppLogger.error("Failed to save weight to HealthKit", error: error, category: .health)
            }

        case "Body Fat %":
            // Save body fat percentage to HealthKit
            do {
                try await healthKitManager.saveBodyFatPercentage(percentage: numericValue / 100.0, date: date)
                AppLogger.info("Saved body fat: \(numericValue)% to HealthKit", category: .health)
            } catch {
                handleError(error)
                AppLogger.error("Failed to save body fat to HealthKit", error: error, category: .health)
            }

        case "Lean Mass":
            // Save lean body mass to HealthKit
            do {
                try await healthKitManager.saveLeanBodyMass(massKg: numericValue, date: date)
                AppLogger.info("Saved lean mass: \(numericValue)kg to HealthKit", category: .health)
            } catch {
                handleError(error)
                AppLogger.error("Failed to save lean mass to HealthKit", error: error, category: .health)
            }

        default:
            AppLogger.warning("Unsupported measurement type: \(type)", category: .data)
        }

        // Reload data from HealthKit
        await loadLatestMetrics()
        await loadWeightHistory()
    }

    /// Cleanup observer when ViewModel is deallocated
    deinit {
        // Cannot access MainActor properties in deinit
        // HealthKit will clean up observers automatically
    }

    // MARK: - Private Methods
    private func calculateTrends() async {
        // Calculate heart rate trend
        // In production, this would analyze historical data
        heartRateTrend = .stable
        hrvTrend = .increasing
    }
}
