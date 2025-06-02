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
        return HealthContext(
            lastNightSleepDurationHours: snapshot.sleep.duration,
            sleepQuality: snapshot.sleep.quality,
            currentWeatherCondition: snapshot.environmental.weatherCondition,
            currentTemperatureCelsius: snapshot.environmental.temperature,
            yesterdayEnergyLevel: snapshot.subjective.energyLevel,
            currentHeartRate: snapshot.heart.restingHeartRate,
            hrv: snapshot.heart.hrv,
            steps: snapshot.activity.steps
        )
    }
    
    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
        let context = await contextAssembler.assembleContext()
        
        // Calculate recovery score based on sleep, HRV, and activity
        var score = 50 // Base score
        
        // Sleep contribution (up to 30 points)
        if let duration = context.sleep.duration {
            let sleepScore = min(30, Int(duration / 8.0 * 30))
            score += sleepScore
        }
        
        // HRV contribution (up to 20 points)
        if let hrv = context.heart.hrv, let baseline = user.baselineHRV {
            let hrvRatio = hrv / baseline
            let hrvScore = Int(min(20, hrvRatio * 20))
            score += hrvScore
        }
        
        // Yesterday's activity impact
        if let yesterdayCalories = context.activity.activeCalories,
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
                "Sleep duration: \(context.sleep.duration?.rounded(toPlaces: 1) ?? 0) hrs",
                "HRV: \(context.heart.hrv?.rounded(toPlaces: 0) ?? 0) ms"
            ]
        )
    }
    
    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        // Get recent workout data
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        // Fetch workout count and average intensity
        let workoutData = await healthKitManager.getWorkoutData(from: startDate, to: endDate)
        
        let trend: PerformanceInsight.Trend
        if workoutData.count > days / 2 {
            trend = .improving
        } else if workoutData.count < days / 4 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        let totalCalories = workoutData.reduce(0) { $0 + ($1.totalCalories ?? 0) }
        
        return PerformanceInsight(
            trend: trend,
            metric: "Weekly Active Days",
            value: "\(workoutData.count)",
            insight: workoutData.isEmpty 
                ? "Time to get moving! Start with a short walk today."
                : "You've been active \(workoutData.count) days. Total burn: \(Int(totalCalories)) cal"
        )
    }
}