import Foundation

/// Converts AirFit's HealthKit data structures to RecoveryInference inputs
@MainActor
public struct RecoveryDataAdapter {
    
    private let healthKitManager: HealthKitManaging
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
    }
    
    /// Converts HealthContextSnapshot + historical data into DailyBiometrics
    func convertToDailyBiometrics(
        from snapshot: HealthContextSnapshot,
        date: Date = Date()
    ) -> DailyBiometrics {
        
        let sleep = snapshot.sleep.lastNight
        
        return DailyBiometrics(
            date: Calendar.current.startOfDay(for: date),
            heartRate: Double(snapshot.heartHealth.restingHeartRate ?? 0), // Use resting HR as proxy
            hrv: snapshot.heartHealth.hrv?.value ?? 0,
            restingHeartRate: Double(snapshot.heartHealth.restingHeartRate ?? 0),
            heartRateRecovery: Double(snapshot.heartHealth.heartRateRecovery ?? 0),
            vo2Max: snapshot.heartHealth.vo2Max ?? 0,
            respiratoryRate: snapshot.heartHealth.respiratoryRate ?? 0,
            bedtime: sleep?.bedtime ?? Date(),
            wakeTime: sleep?.wakeTime ?? Date(),
            sleepDuration: sleep?.totalSleepTime ?? 0,
            remSleep: sleep?.remTime ?? 0,
            coreSleep: sleep?.coreTime ?? 0,
            deepSleep: sleep?.deepTime ?? 0,
            awakeTime: sleep?.awakeTime ?? 0,
            sleepEfficiency: (sleep?.efficiency ?? 0) / 100.0,  // Convert from 0-100 to 0-1
            activeEnergyBurned: snapshot.activity.activeEnergyBurned?.value ?? 0,
            basalEnergyBurned: snapshot.activity.basalEnergyBurned?.value ?? 0,
            steps: snapshot.activity.steps ?? 0,
            exerciseTime: Double(snapshot.activity.exerciseMinutes ?? 0) * 60.0,  // Convert minutes to seconds
            standHours: snapshot.activity.standHours ?? 0
        )
    }
    
    /// Fetches historical biometric data for the past N days
    public func fetchHistoricalBiometrics(days: Int = 7) async -> [DailyBiometrics] {
        // For now, return empty array - this would need to be implemented
        // to fetch historical HealthKit data day by day
        // TODO: Implement historical data fetching
        return []
    }
    
    /// Converts AirFit WorkoutData to RecoveryInference WorkoutData
    func convertWorkouts(_ workouts: [WorkoutData]) -> [WorkoutData] {
        // WorkoutData is already the correct type from RecoveryInference
        return workouts
    }
    
    /// Prepares complete input for recovery analysis
    func prepareRecoveryInput(
        currentSnapshot: HealthContextSnapshot,
        subjectiveRating: Double? = nil
    ) async throws -> RecoveryInference.Input {
        
        // Get current metrics
        let currentMetrics = convertToDailyBiometrics(from: currentSnapshot)
        
        // Get historical data (would need implementation)
        let historicalData = await fetchHistoricalBiometrics(days: 7)
        
        // Get recent workouts
        let recentWorkouts = try await healthKitManager.fetchRecentWorkouts(limit: 50)
        let convertedWorkouts = convertWorkouts(recentWorkouts)
        
        return RecoveryInference.Input(
            currentMetrics: currentMetrics,
            historicalData: historicalData,
            recentWorkouts: convertedWorkouts,
            subjectiveRating: subjectiveRating
        )
    }
}