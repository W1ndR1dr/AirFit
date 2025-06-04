import Foundation
import SwiftData

/// Default implementation of HealthKitServiceProtocol for the Dashboard
actor DefaultHealthKitService: HealthKitServiceProtocol {
    private let healthKitManager: HealthKitManaging
    private let contextAssembler: ContextAssembler
    
    init(healthKitManager: HealthKitManaging, contextAssembler: ContextAssembler) {
        self.healthKitManager = healthKitManager
        self.contextAssembler = contextAssembler
    }
    
    func getCurrentContext() async throws -> HealthContext {
        // Get the full health context snapshot
        let snapshot = await contextAssembler.assembleContext()
        
        // Map to the lightweight dashboard context
        let sleepHours: Double? = if let duration = snapshot.sleep.lastNight?.totalSleepTime {
            duration / 3600
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
        
        // Calculate recovery score based on sleep, HRV, and activity
        var score = 50 // Base score
        
        // Sleep contribution (up to 30 points)
        if let duration = context.sleep.lastNight?.totalSleepTime {
            let hours = duration / 3600
            let sleepScore = min(30, Int(hours / 8.0 * 30))
            score += sleepScore
        }
        
        // HRV contribution (up to 20 points)
        if let hrv = context.heartHealth.hrv?.converted(to: .milliseconds).value, let baseline = user.baselineHRV {
            let hrvRatio = hrv / baseline
            let hrvScore = Int(min(20, hrvRatio * 20))
            score += hrvScore
        }
        
        // Yesterday's activity impact
        if let yesterdayCalories = context.activity.activeEnergyBurned?.converted(to: .kilocalories).value,
           yesterdayCalories > 500 {
            score -= 10 // High activity yesterday, need more recovery
        }
        
        score = max(0, min(100, score))
        
        let status: RecoveryScore.Status
        switch score {
        case 0..<40: status = .poor
        case 40..<70: status = .moderate
        default: status = .good
        }
        
        return RecoveryScore(
            score: score,
            status: status,
            factors: [
                "Sleep duration: \((context.sleep.lastNight?.totalSleepTime.map { ($0 / 3600).rounded(toPlaces: 1) } ?? 0)) hrs",
                "HRV: \((context.heartHealth.hrv?.converted(to: .milliseconds).value.rounded(toPlaces: 0) ?? 0)) ms"
            ]
        )
    }
    
    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        // Get recent workout data
        let endDate = Date()
        let _ = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        // TODO: Fetch workout count and average intensity when getWorkoutData is added to protocol
        // let workoutData = await healthKitManager.getWorkoutData(from: startDate, to: endDate)
        
        // For now, use placeholder data
        let workoutCount = 3
        let trend: PerformanceInsight.Trend
        if workoutCount > days / 2 {
            trend = .improving
        } else if workoutCount < days / 4 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        let totalCalories = 1500.0 // Placeholder
        
        return PerformanceInsight(
            trend: trend,
            metric: "Weekly Active Days",
            value: "\(workoutCount)",
            insight: workoutCount == 0 
                ? "Time to get moving! Start with a short walk today."
                : "You've been active \(workoutCount) days. Total burn: \(Int(totalCalories)) cal"
        )
    }
}