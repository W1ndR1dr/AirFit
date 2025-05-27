import Foundation
import HealthKit

/// Snapshot of the user's health context for a specific day.
struct HealthContextSnapshot: Sendable, Codable {
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
struct SubjectiveData: Sendable, Codable {
    var energyLevel: Int?      // 1-5
    var mood: Int?             // 1-5
    var stress: Int?           // 1-5
    var motivation: Int?       // 1-5
    var soreness: Int?         // 1-5
    var notes: String?
}

struct EnvironmentContext: Sendable, Codable {
    var weatherCondition: String?
    var temperature: Measurement<UnitTemperature>?
    var humidity: Double?           // percentage 0-100
    var airQualityIndex: Int?
    var timeOfDay: TimeOfDay = .init()

    enum TimeOfDay: String, Sendable, Codable {
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

struct ActivityMetrics: Sendable, Codable {
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
    var workoutTypeRawValue: UInt?  // Store HKWorkoutActivityType as raw value

    // Ring progress (0-1)
    var moveProgress: Double?
    var exerciseProgress: Double?
    var standProgress: Double?
    
    // Computed property for HKWorkoutActivityType
    var workoutType: HKWorkoutActivityType? {
        get {
            guard let rawValue = workoutTypeRawValue else { return nil }
            return HKWorkoutActivityType(rawValue: rawValue)
        }
        set {
            workoutTypeRawValue = newValue?.rawValue
        }
    }
}

struct SleepAnalysis: Sendable, Codable {
    var lastNight: SleepSession?
    var weeklyAverage: SleepAverages?

    struct SleepSession: Sendable, Codable {
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

    struct SleepAverages: Sendable, Codable {
        let averageBedtime: Date?
        let averageWakeTime: Date?
        let averageDuration: TimeInterval?
        let averageEfficiency: Double?
        let consistency: Double?    // 0-100
    }

    enum SleepQuality: String, Sendable, Codable {
        case excellent
        case good
        case fair
        case poor
    }
}

struct HeartHealthMetrics: Sendable, Codable {
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

    enum CardioFitnessLevel: String, Sendable, Codable {
        case low
        case belowAverage
        case average
        case aboveAverage
        case high
    }
}

struct BodyMetrics: Sendable, Codable {
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

    enum BMICategory: String, Sendable, Codable {
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

    enum Trend: String, Sendable, Codable {
        case increasing
        case stable
        case decreasing
    }
}

struct AppSpecificContext: Sendable, Codable {
    var activeWorkoutName: String?
    var lastMealTime: Date?
    var lastMealSummary: String?
    var waterIntakeToday: Measurement<UnitVolume>?
    var lastCoachInteraction: Date?
    var upcomingWorkout: String?
    var currentStreak: Int?
    var workoutContext: WorkoutContext?
}

// MARK: - Enhanced Workout Context Types

/// Comprehensive workout context optimized for AI coaching with token efficiency
struct WorkoutContext: Sendable, Codable {
    var recentWorkouts: [CompactWorkout] = []
    var activeWorkout: CompactWorkout?
    var upcomingWorkout: CompactWorkout?
    var plannedWorkouts: [CompactWorkout] = []
    var streakDays: Int = 0
    var weeklyVolume: Double = 0
    var muscleGroupBalance: [String: Int] = [:]
    var intensityTrend: IntensityTrend = .stable
    var recoveryStatus: RecoveryStatus = .unknown
    
    init(
        recentWorkouts: [CompactWorkout] = [],
        activeWorkout: CompactWorkout? = nil,
        upcomingWorkout: CompactWorkout? = nil,
        plannedWorkouts: [CompactWorkout] = [],
        streakDays: Int = 0,
        weeklyVolume: Double = 0,
        muscleGroupBalance: [String: Int] = [:],
        intensityTrend: IntensityTrend = .stable,
        recoveryStatus: RecoveryStatus = .unknown
    ) {
        self.recentWorkouts = recentWorkouts
        self.activeWorkout = activeWorkout
        self.upcomingWorkout = upcomingWorkout
        self.plannedWorkouts = plannedWorkouts
        self.streakDays = streakDays
        self.weeklyVolume = weeklyVolume
        self.muscleGroupBalance = muscleGroupBalance
        self.intensityTrend = intensityTrend
        self.recoveryStatus = recoveryStatus
    }
}

/// Compressed workout representation for efficient API context
struct CompactWorkout: Sendable, Codable {
    let name: String
    let type: String
    let date: Date
    let duration: TimeInterval?
    let exerciseCount: Int
    let totalVolume: Double // weight × reps total
    let avgRPE: Double?
    let muscleGroups: [String]
    let keyExercises: [String] // Top 3 exercises
}

/// Workout pattern analysis for intelligent coaching
struct WorkoutPatterns: Sendable, Codable {
    let weeklyVolume: Double
    let muscleGroupBalance: [String: Int]
    let intensityTrend: IntensityTrend
    let recoveryStatus: RecoveryStatus
}

enum IntensityTrend: String, Sendable, Codable {
    case increasing
    case stable
    case decreasing
}

enum RecoveryStatus: String, Sendable, Codable {
    case active      // 0-1 days since last workout
    case recovered   // 2-3 days since last workout
    case wellRested  // 4-7 days since last workout
    case detraining  // 8+ days since last workout
    case unknown
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .coreTraining: return "Core Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .flexibility: return "Flexibility"
        case .cooldown: return "Cooldown"
        case .other: return "Other"
        default: return "Workout"
        }
    }
}

struct HealthTrends: Sendable, Codable {
    var weeklyActivityChange: Double?       // percentage
    var sleepConsistencyScore: Double?      // 0-100
    var recoveryTrend: RecoveryTrend?
    var performanceTrend: PerformanceTrend?

    enum RecoveryTrend: String, Sendable, Codable {
        case wellRecovered
        case normal
        case needsRecovery
        case overreaching
    }

    enum PerformanceTrend: String, Sendable, Codable {
        case peaking
        case improving
        case maintaining
        case declining
    }
}
