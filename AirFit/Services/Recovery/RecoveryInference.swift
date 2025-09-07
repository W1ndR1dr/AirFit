//
//  RecoveryInference.swift
//  AirFit
//
//  Created: 2025-01-16
//  Swift 6
//

import Foundation
import HealthKit

// MARK: - Primitive Models -----------------------------------------------------

public struct DailyBiometrics: Hashable, Sendable {
    public let date: Date                       // Local-midnight key
    // Cardiovascular
    public let heartRate: Double                // bpm (mean while awake)
    public let hrv: Double                      // ms (SDNN)
    public let restingHeartRate: Double         // bpm
    public let heartRateRecovery: Double        // bpm @ 1 min
    public let vo2Max: Double                   // ml•kg-1•min-1
    public let respiratoryRate: Double          // brpm
    
    // Sleep
    public let bedtime: Date
    public let wakeTime: Date
    public let sleepDuration: TimeInterval      // s
    public let remSleep: TimeInterval           // s
    public let coreSleep: TimeInterval          // s
    public let deepSleep: TimeInterval          // s
    public let awakeTime: TimeInterval          // s
    public let sleepEfficiency: Double          // 0–1
    
    // Activity
    public let activeEnergyBurned: Double       // kcal
    public let basalEnergyBurned: Double        // kcal
    public let steps: Int
    public let exerciseTime: TimeInterval       // s
    public let standHours: Int
    
    public init(
        date: Date,
        heartRate: Double,
        hrv: Double,
        restingHeartRate: Double,
        heartRateRecovery: Double,
        vo2Max: Double,
        respiratoryRate: Double,
        bedtime: Date,
        wakeTime: Date,
        sleepDuration: TimeInterval,
        remSleep: TimeInterval,
        coreSleep: TimeInterval,
        deepSleep: TimeInterval,
        awakeTime: TimeInterval,
        sleepEfficiency: Double,
        activeEnergyBurned: Double,
        basalEnergyBurned: Double,
        steps: Int,
        exerciseTime: TimeInterval,
        standHours: Int
    ) {
        self.date = date
        self.heartRate = heartRate
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.heartRateRecovery = heartRateRecovery
        self.vo2Max = vo2Max
        self.respiratoryRate = respiratoryRate
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.sleepDuration = sleepDuration
        self.remSleep = remSleep
        self.coreSleep = coreSleep
        self.deepSleep = deepSleep
        self.awakeTime = awakeTime
        self.sleepEfficiency = sleepEfficiency
        self.activeEnergyBurned = activeEnergyBurned
        self.basalEnergyBurned = basalEnergyBurned
        self.steps = steps
        self.exerciseTime = exerciseTime
        self.standHours = standHours
    }
}

public struct WorkoutData: Hashable, Sendable {
    public let workoutType: String              // HKWorkoutActivityType rawValue
    public let startDate: Date
    public let duration: TimeInterval           // s
    public let totalEnergyBurned: Double        // kcal
    public let averageHeartRate: Double         // bpm
    
    public init(
        workoutType: String,
        startDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: Double,
        averageHeartRate: Double
    ) {
        self.workoutType = workoutType
        self.startDate = startDate
        self.duration = duration
        self.totalEnergyBurned = totalEnergyBurned
        self.averageHeartRate = averageHeartRate
    }
}

// MARK: - Recovery Inference ---------------------------------------------------

public struct RecoveryInference: Sendable {

    // MARK: Input / Output
    
    public struct Input: Sendable {
        public let currentMetrics: DailyBiometrics
        public let historicalData: [DailyBiometrics]        // ≥ 7 and ≤ 30 d
        public let recentWorkouts: [WorkoutData]            // last 7 d
        public let subjectiveRating: Double?                // 1–10 optional
        public init(currentMetrics: DailyBiometrics,
                    historicalData: [DailyBiometrics],
                    recentWorkouts: [WorkoutData],
                    subjectiveRating: Double? = nil) {
            self.currentMetrics   = currentMetrics
            self.historicalData   = historicalData
            self.recentWorkouts   = recentWorkouts
            self.subjectiveRating = subjectiveRating
        }
    }
    
    public enum RecoveryStatus: String, Sendable, CaseIterable {
        case fullyRecovered = "Fully Recovered"
        case adequate = "Adequate"
        case compromised = "Compromised"
        case needsRest = "Needs Rest"
        
        public var color: String {
            switch self {
            case .fullyRecovered: return "green"
            case .adequate: return "blue"
            case .compromised: return "orange"
            case .needsRest: return "red"
            }
        }
    }
    
    public enum TrainingIntensity: String, Sendable, CaseIterable {
        case highIntensity = "High Intensity"
        case moderate = "Moderate"
        case activeRecovery = "Active Recovery"
        case rest = "Rest"
        
        public var description: String {
            switch self {
            case .highIntensity: return "Go for it. Your body is ready for challenging workouts."
            case .moderate: return "Moderate intensity work is appropriate today."
            case .activeRecovery: return "Light movement and recovery activities recommended."
            case .rest: return "Focus on rest and recovery today."
            }
        }
    }
    
    public struct Output: Sendable {
        public let readinessScore: Double        // 0–100
        public let recoveryStatus: RecoveryStatus
        public let limitingFactors: [String]
        public let trainingRecommendation: TrainingIntensity
        public let confidence: Double            // 0–1 (data coverage)
    }
    
    // MARK: Public API
    
    public init() {}
    
    public func analyzeRecovery(input: Input) async -> Output {
        // 1. Guard against insufficient data
        let history = input.historicalData
        guard history.count >= 7 else {
            return Output(readinessScore: 50,
                          recoveryStatus: .compromised,
                          limitingFactors: ["Insufficient historical data (<7 d)"],
                          trainingRecommendation: .activeRecovery,
                          confidence: 0.3)
        }
        
        // 2. Compute rolling baselines (last 7 d, inclusive of current? No)
        let window = history.suffix(7)                           // exactly 7
        let hrvBase = Self.meanStd(window.map(\.hrv))
        let rhrBase = Self.meanStd(window.map(\.restingHeartRate))
        
        // 3. Current deviations (z-scores)
        let hrvZ  = Self.zScore(value: input.currentMetrics.hrv,
                           mean: hrvBase.mean,
                           sd:   hrvBase.sd)
        let rhrZ  = Self.zScore(value: input.currentMetrics.restingHeartRate,
                           mean: rhrBase.mean,
                           sd:   rhrBase.sd)
        
        // 4. Sleep quality 0–1
        let sleepScore = Self.sleepQualityScore(for: input.currentMetrics)
        
        // 5. Cumulative (acute) training load
        let loadScore = Self.acuteLoadScore(from: input.recentWorkouts)
        
        // 6. Aggregate into readiness (100 = best)
        var readiness: Double = 100
        var factors: [String] = []
        
        // HRV penalty
        if hrvZ < -1 {
            let penalty = min(20, abs(hrvZ) * 10)   // up to 20
            readiness -= penalty
            factors.append("Low HRV (z \(String(format: "%.1f", hrvZ)))")
        }
        // RHR penalty
        if rhrZ > 1 {
            let penalty = min(15, rhrZ * 8)         // up to 15
            readiness -= penalty
            factors.append("Elevated RHR (z \(String(format: "%.1f", rhrZ)))")
        }
        // Sleep penalty
        if sleepScore < 0.85 {
            let penalty = (1 - sleepScore) * 25     // up to 25
            readiness -= penalty
            factors.append("Sub-optimal sleep")
        }
        // Load penalty (ratios >1 = heavy)
        if loadScore > 1.2 {
            let penalty = min(20, (loadScore - 1) * 25)
            readiness -= penalty
            factors.append("High acute training load")
        }
        
        // Trend bonus: improving HRV & decreasing RHR over 3 d
        if Self.isTrendPositive(history: window, metric: \.hrv) { readiness += 5 }
        if Self.isTrendPositive(history: window, metric: \.restingHeartRate, inversed: true) {
            readiness += 5
        }
        
        // Clamp 0–100
        readiness = readiness.clamped(to: 0...100)
        
        // 7. Calibration with subjective rating
        let calibrationResult = await CalibrationManager.shared.applyCalibration(to: readiness,
                                                                                 subjective: input.subjectiveRating)
        readiness = calibrationResult.score
        factors   += calibrationResult.recalibrationNotes
        
        // 8. Status & recommendation
        let (status, recommendation) = Self.statusAndRecommendation(for: readiness)
        
        // 9. Confidence – % of data present
        let confidence = Self.dataCoverage(for: input)
        
        return Output(readinessScore: readiness.rounded(.towardZero),
                      recoveryStatus: status,
                      limitingFactors: factors,
                      trainingRecommendation: recommendation,
                      confidence: confidence)
    }
}

// MARK: - Calibration Manager --------------------------------------------------

public actor CalibrationManager: Sendable {
    public static let shared = CalibrationManager()
    
    // Simple moving averages of errors between predicted score (0-100) and
    // optional subjective (10⇢100) – stored in-memory; persist as desired.
    private var bias: Double = 0                // additive offset
    private var samples: Int  = 0
    
    public struct Adjustment: Sendable {
        public let score: Double
        public let recalibrationNotes: [String]
    }
    
    public func applyCalibration(to raw: Double,
                                 subjective: Double?) -> Adjustment {
        guard let subjective = subjective else { return .init(score: raw,
                                                              recalibrationNotes: []) }
        let target = subjective * 10            // map 1–10 ➜ 10–100
        let error  = target - raw
        // EWMA – α = 0.1
        bias += 0.1 * (error - bias)
        samples += 1
        let calibrated = (raw + bias).clamped(to: 0...100)
        return .init(score: calibrated,
                     recalibrationNotes: ["Calibrated (+\(Int(bias.rounded())))"])
    }
}

// MARK: - Private Helpers ------------------------------------------------------

private extension RecoveryInference {
    
    typealias MeanSD = (mean: Double, sd: Double)
    
    /// Mean & population SD
    static func meanStd(_ arr: [Double]) -> MeanSD {
        let n = Double(arr.count)
        let mean = arr.reduce(0, +) / n
        let variance = arr.reduce(0) { $0 + pow($1 - mean, 2) } / n
        return (mean, sqrt(variance))
    }
    
    static func zScore(value: Double, mean: Double, sd: Double) -> Double {
        guard sd > 0 else { return 0 }
        return (value - mean) / sd
    }
    
    /// Sleep quality 0–1 (duration × efficiency × stage weighting)
    static func sleepQualityScore(for day: DailyBiometrics) -> Double {
        // Duration weight – ideal 7.5–9 h
        let hours = day.sleepDuration / 3600
        let durationFactor = max(0, min(1, (hours - 5) / 3))        // <5h→0, 8h→1
        // Stage factor (deep+REM >= 90 min ideal)
        let restorative = (day.deepSleep + day.remSleep) / 60       // minutes
        let stageFactor  = max(0, min(1, restorative / 90))
        // Combine
        return (durationFactor * 0.5) + (day.sleepEfficiency * 0.3) + (stageFactor * 0.2)
    }
    
    /// Exponentially weighted 7-day load ratio vs 7-day mean.
    static func acuteLoadScore(from workouts: [WorkoutData]) -> Double {
        guard !workouts.isEmpty else { return 0 }
        // Aggregate daily kcal
        let byDay = Dictionary(grouping: workouts) {
            Calendar.current.startOfDay(for: $0.startDate)
        }.mapValues { $0.reduce(0) { $0 + $1.totalEnergyBurned } }
        
        // Past 7 days ordered oldest→newest
        let days = (0..<7).compactMap { offset -> (Date, Double)? in
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = Calendar.current.startOfDay(for: date)
            return (key, byDay[key] ?? 0)
        }.reversed()
        
        // EWMA α = 0.3
        var ewma: Double = 0
        var denom: Double = 0
        for (_, kcal) in days {
            ewma = 0.3 * kcal + (1 - 0.3) * ewma
            denom += kcal
        }
        let mean = denom / 7
        return mean == 0 ? 0 : ewma / mean        // ratio
    }
    
    static func isTrendPositive<T: BinaryFloatingPoint>(
        history: ArraySlice<DailyBiometrics>,
        metric keyPath: KeyPath<DailyBiometrics, T>,
        inversed: Bool = false) -> Bool
    {
        // Simple linear regression slope sign over the 7-d window
        let n = Double(history.count)
        let xs = stride(from: 0, to: n, by: 1).map { Double($0) }
        let ys = history.enumerated().map { Double($1[keyPath: keyPath]) }
        let meanX = (n - 1) / 2
        let meanY = ys.reduce(0, +) / n
        let numer = zip(xs, ys).reduce(0) { acc, pair in
            acc + (pair.0 - meanX) * (pair.1 - meanY)
        }
        let denom = xs.reduce(0) { $0 + pow($1 - meanX, 2) }
        guard denom > 0 else { return false }
        let slope = numer / denom
        return inversed ? slope < 0 : slope > 0
    }
    
    static func statusAndRecommendation(for score: Double)
    -> (RecoveryStatus, TrainingIntensity) {
        switch score {
        case 85...:
            return (.fullyRecovered, .highIntensity)
        case 70..<85:
            return (.adequate, .moderate)
        case 50..<70:
            return (.compromised, .activeRecovery)
        default:
            return (.needsRest, .rest)
        }
    }
    
    static func dataCoverage(for input: Input) -> Double {
        // Rough proportion of non-zero fields in current metrics
        let mirror = Mirror(reflecting: input.currentMetrics)
        let total = mirror.children.count
        let filled = mirror.children.filter {
            if let v = $0.value as? Double { return v != 0 }
            if let v = $0.value as? Int    { return v != 0 }
            return true
        }.count
        return Double(filled) / Double(total)
    }
}

// MARK: - Utilities -----------------------------------------------------------

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}