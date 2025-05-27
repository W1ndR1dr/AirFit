import Foundation
import HealthKit

/// Snapshot of the user's health context for a specific day.
struct HealthContextSnapshot: Sendable {
    // MARK: - Metadata
    let id: UUID
    let timestamp: Date
    let date: Date

    // MARK: - Subjective Data
    let subjectiveData: SubjectiveData

    // MARK: - Environmental Context
    let environment: EnvironmentContext

    // MARK: - Activity Metrics
    let activity: ActivityMetrics

    // MARK: - Sleep Analysis
    let sleep: SleepAnalysis

    // MARK: - Heart Health
    let heartHealth: HeartHealthMetrics

    // MARK: - Body Metrics
    let body: BodyMetrics

    // MARK: - App Context
    let appContext: AppSpecificContext

    // MARK: - Trends
    let trends: HealthTrends

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        subjectiveData: SubjectiveData = SubjectiveData(),
        environment: EnvironmentContext = EnvironmentContext(),
        activity: ActivityMetrics = ActivityMetrics(),
        sleep: SleepAnalysis = SleepAnalysis(),
        heartHealth: HeartHealthMetrics = HeartHealthMetrics(),
        body: BodyMetrics = BodyMetrics(),
        appContext: AppSpecificContext = AppSpecificContext(),
        trends: HealthTrends = HealthTrends()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.date = date
        self.subjectiveData = subjectiveData
        self.environment = environment
        self.activity = activity
        self.sleep = sleep
        self.heartHealth = heartHealth
        self.body = body
        self.appContext = appContext
        self.trends = trends
    }
}

// MARK: - Component Structures
struct SubjectiveData: Sendable {
    var energyLevel: Int?      // 1-5
    var mood: Int?             // 1-5
    var stress: Int?           // 1-5
    var motivation: Int?       // 1-5
    var soreness: Int?         // 1-5
    var notes: String?
}

struct EnvironmentContext: Sendable {
    var weatherCondition: String?
    var temperature: Measurement<UnitTemperature>?
    var humidity: Double?           // percentage 0-100
    var airQualityIndex: Int?
    var timeOfDay: TimeOfDay = .init()

    enum TimeOfDay: String, Sendable {
        case earlyMorning = "early_morning" // 5-8am
        case morning      = "morning"       // 8-12pm
        case afternoon    = "afternoon"     // 12-5pm
        case evening      = "evening"       // 5-9pm
        case night        = "night"         // 9pm-5am

        init(from date: Date = Date()) {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<8: self = .earlyMorning
            case 8..<12: self = .morning
            case 12..<17: self = .afternoon
            case 17..<21: self = .evening
            default: self = .night
            }
        }
    }
}

struct ActivityMetrics: Sendable {
    // Daily totals
    var activeEnergyBurned: Measurement<UnitEnergy>?
    var basalEnergyBurned: Measurement<UnitEnergy>?
    var steps: Int?
    var distance: Measurement<UnitLength>?
    var flightsClimbed: Int?
    var exerciseMinutes: Int?
    var standHours: Int?
    var moveMinutes: Int?

    // Current activity
    var currentHeartRate: Int?
    var isWorkoutActive = false
    var workoutType: HKWorkoutActivityType?

    // Ring progress (0-1)
    var moveProgress: Double?
    var exerciseProgress: Double?
    var standProgress: Double?
}

struct SleepAnalysis: Sendable {
    var lastNight: SleepSession?
    var weeklyAverage: SleepAverages?

    struct SleepSession: Sendable {
        let bedtime: Date?
        let wakeTime: Date?
        let totalSleepTime: TimeInterval?
        let timeInBed: TimeInterval?
        let efficiency: Double?   // 0-100

        // iOS 18 sleep stages
        let remTime: TimeInterval?
        let coreTime: TimeInterval?
        let deepTime: TimeInterval?
        let awakeTime: TimeInterval?

        var quality: SleepQuality? {
            guard let efficiency else { return nil }
            switch efficiency {
            case 85...: return .excellent
            case 75..<85: return .good
            case 65..<75: return .fair
            default: return .poor
            }
        }
    }

    struct SleepAverages: Sendable {
        let averageBedtime: Date?
        let averageWakeTime: Date?
        let averageDuration: TimeInterval?
        let averageEfficiency: Double?
        let consistency: Double?    // 0-100
    }

    enum SleepQuality: String, Sendable {
        case excellent
        case good
        case fair
        case poor
    }
}

struct HeartHealthMetrics: Sendable {
    // Resting metrics
    var restingHeartRate: Int?
    var hrv: Measurement<UnitDuration>?      // milliseconds
    var respiratoryRate: Double?             // breaths per minute

    // Fitness metrics
    var vo2Max: Double?                      // ml/kg/min
    var cardioFitness: CardioFitnessLevel?

    // Recovery metrics
    var recoveryHeartRate: Int?              // 1 min post-workout
    var heartRateRecovery: Int?              // drop from peak

    enum CardioFitnessLevel: String, Sendable {
        case low
        case belowAverage
        case average
        case aboveAverage
        case high
    }
}

struct BodyMetrics: Sendable {
    var weight: Measurement<UnitMass>?
    var bodyFatPercentage: Double?
    var leanBodyMass: Measurement<UnitMass>?
    var bmi: Double?

    /// Category derived from the BMI value.
    var bodyMassIndex: BMICategory? {
        bmi.flatMap { BMICategory(bmi: $0) }
    }

    // Trends
    var weightTrend: Trend?
    var bodyFatTrend: Trend?

    enum BMICategory: String, Sendable {
        case underweight
        case normal
        case overweight
        case obese

        init?(bmi: Double) {
            switch bmi {
            case ..<18.5: self = .underweight
            case 18.5..<25: self = .normal
            case 25..<30: self = .overweight
            case 30...: self = .obese
            default: return nil
            }
        }
    }

    enum Trend: String, Sendable {
        case increasing
        case stable
        case decreasing
    }
}

struct AppSpecificContext: Sendable {
    var activeWorkoutName: String?
    var lastMealTime: Date?
    var lastMealSummary: String?
    var waterIntakeToday: Measurement<UnitVolume>?
    var lastCoachInteraction: Date?
    var upcomingWorkout: String?
    var currentStreak: Int?
}

struct HealthTrends: Sendable {
    var weeklyActivityChange: Double?       // percentage
    var sleepConsistencyScore: Double?      // 0-100
    var recoveryTrend: RecoveryTrend?
    var performanceTrend: PerformanceTrend?

    enum RecoveryTrend: String, Sendable {
        case wellRecovered
        case normal
        case needsRecovery
        case overreaching
    }

    enum PerformanceTrend: String, Sendable {
        case peaking
        case improving
        case maintaining
        case declining
    }
}
