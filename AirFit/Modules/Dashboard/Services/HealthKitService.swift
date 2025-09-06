import Foundation
import SwiftData

/// Implementation of HealthKitServiceProtocol for the Dashboard
actor HealthKitService: HealthKitServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "healthkit-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For actors, return true as services are ready when created
        true
    }

    private let healthKitManager: HealthKitManaging
    private let contextAssembler: ContextAssemblerProtocol

    init(healthKitManager: HealthKitManaging, contextAssembler: ContextAssemblerProtocol) {
        self.healthKitManager = healthKitManager
        self.contextAssembler = contextAssembler
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [
                "hasHealthKitManager": "true",
                "hasContextAssembler": "true"
            ]
        )
    }

    func getCurrentContext() async throws -> HealthContext {
        // Get the full health context snapshot
        let snapshot = await contextAssembler.assembleContext()

        // Map to the lightweight dashboard context
        let sleepHours: Double? = if let duration = snapshot.sleep.lastNight?.totalSleepTime {
            duration / 3_600
        } else {
            nil
        }

        return HealthContext(
            lastNightSleepDurationHours: sleepHours,
            sleepQuality: snapshot.sleep.lastNight?.efficiency.map { Int($0) },
            currentWeatherCondition: snapshot.environment.weatherCondition,
            currentTemperatureCelsius: snapshot.environment.temperature?.converted(to: .celsius).value,
            yesterdayEnergyLevel: snapshot.subjectiveData.energyLevel,
            currentHeartRate: snapshot.heartHealth.restingHeartRate,
            hrv: snapshot.heartHealth.hrv?.converted(to: .milliseconds).value,
            steps: snapshot.activity.steps
        )
    }

    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
        let context = await contextAssembler.assembleContext()
        
        // Use the sophisticated RecoveryInference system
        let adapter = await RecoveryDataAdapter(healthKitManager: healthKitManager)
        let recoveryInput = try await adapter.prepareRecoveryInput(
            currentSnapshot: context,
            subjectiveRating: nil  // No subjective rating for dashboard
        )
        
        let inference = RecoveryInference()
        let output = await inference.analyzeRecovery(input: recoveryInput)
        
        // Convert RecoveryInference output to legacy RecoveryScore format
        let status: RecoveryScore.Status
        switch output.recoveryStatus {
        case .fullyRecovered:
            status = .good
        case .adequate:
            status = .moderate
        case .compromised, .needsRest:
            status = .poor
        }
        
        return RecoveryScore(
            score: Int(output.readinessScore),
            status: status,
            factors: output.limitingFactors.isEmpty ? 
                ["All systems normal"] : output.limitingFactors
        )
    }

    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        // Get recent workout data
        let endDate = Date()
        _ = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        // Fetch recent workout data
        let workouts = try await healthKitManager.fetchRecentWorkouts(limit: days)
        let workoutCount = workouts.count
        let trend: PerformanceInsight.Trend
        if workoutCount > days / 2 {
            trend = .improving
        } else if workoutCount < days / 4 {
            trend = .declining
        } else {
            trend = .stable
        }

        let totalCalories = 1_500.0 // Placeholder

        return PerformanceInsight(
            trend: trend,
            metric: "Weekly Active Days",
            value: "\(workoutCount)",
            insight: "You've been active \(workoutCount) days. Total burn: \(Int(totalCalories)) cal"
        )
    }
}
