import Foundation
import Combine

/// Real-time Heart Rate Recovery (HRR) tracker for detecting workout fatigue.
/// Monitors inter-set recovery rate and detects the "asymptote" - when productive training ends.
@MainActor
final class HRRTracker: ObservableObject {
    static let shared = HRRTracker()

    // MARK: - Published State

    @Published private(set) var currentPhase: ActivityPhase = .idle
    @Published private(set) var currentHR: Double = 0
    @Published private(set) var peakHR: Double = 0
    @Published private(set) var restPeriods: [RestPeriod] = []
    @Published private(set) var fatigueLevel: FatigueLevel = .fresh
    @Published private(set) var degradationPercent: Double = 0
    @Published private(set) var setsCompleted: Int = 0

    // Computed session data for UI and export
    var sessionData: HRRSessionData {
        HRRSessionData(
            isWorkoutActive: currentPhase != .idle,
            currentPhase: currentPhase.rawValue,
            currentHR: currentHR,
            peakHR: peakHR,
            restPeriods: restPeriods.map { period in
                HRRSessionData.RestPeriod(
                    startHR: period.startHR,
                    endHR: period.endHR,
                    duration: period.duration,
                    recoveryRate: period.recoveryRate
                )
            },
            fatigueLevel: fatigueLevel.rawValue,
            degradationPercent: degradationPercent,
            setsCompleted: setsCompleted
        )
    }

    // MARK: - Types

    enum ActivityPhase: String, CaseIterable {
        case idle       // Not in a set
        case exertion   // Actively performing a set (HR rising/sustained)
        case recovery   // HR dropping after set
        case resting    // HR stabilized between sets
    }

    enum FatigueLevel: String, CaseIterable {
        case fresh      // Full recovery capacity
        case productive // Normal training fatigue
        case fatigued   // Recovery slowing
        case asymptote  // Diminishing returns zone
        case depleted   // Should stop

        var color: String {
            switch self {
            case .fresh: return "green"
            case .productive: return "blue"
            case .fatigued: return "yellow"
            case .asymptote: return "orange"
            case .depleted: return "red"
            }
        }

        var icon: String {
            switch self {
            case .fresh: return "flame.fill"
            case .productive: return "checkmark.circle.fill"
            case .fatigued: return "exclamationmark.circle.fill"
            case .asymptote: return "exclamationmark.triangle.fill"
            case .depleted: return "stop.circle.fill"
            }
        }

        var message: String {
            switch self {
            case .fresh: return "Full steam ahead"
            case .productive: return "Good training zone"
            case .fatigued: return "Recovery slowing"
            case .asymptote: return "Diminishing returns - 2-3 sets left"
            case .depleted: return "Consider ending workout"
            }
        }
    }

    struct RestPeriod: Identifiable {
        let id = UUID()
        let startTime: Date
        let startHR: Double    // Peak HR before rest
        var endHR: Double      // HR at end of rest
        var duration: TimeInterval

        /// Recovery rate in BPM per second
        var recoveryRate: Double {
            guard duration > 0 else { return 0 }
            return (startHR - endHR) / duration
        }

        /// Recovery as percentage toward baseline
        func recoveryPercent(baseline: Double) -> Double {
            guard startHR > baseline else { return 100 }
            return ((startHR - endHR) / (startHR - baseline)) * 100
        }
    }

    // MARK: - Configuration

    private let hrAccelerationThreshold: Double = 0.5   // bpm/sec to detect set start
    private let hrDecelerationThreshold: Double = 0.3   // bpm/sec to detect set end
    private let minRestDuration: TimeInterval = 15      // Min rest for valid HRR
    private let maxSetDuration: TimeInterval = 90       // Safety cap
    private let rollingWindowSize = 3                   // Sets to average for degradation
    private let significantDegradation: Double = 15     // % decline = concerning
    private let asymptoteVariance: Double = 5           // % variance = plateau

    // MARK: - Private State

    private var hrBuffer: [(date: Date, bpm: Double)] = []
    private let bufferDuration: TimeInterval = 30  // 30-second sliding window
    private var setStartTime: Date?
    private var restStartTime: Date?
    private var currentRestPeriod: RestPeriod?
    private var baselineHR: Double = 60
    private var sessionBaseline: Double?  // Best HRR from first few sets

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Process a new heart rate sample
    func processSample(_ sample: WatchHealthKitManager.HRSample) {
        let bpm = sample.bpm
        let date = sample.date

        // Update buffer
        hrBuffer.append((date: date, bpm: bpm))
        cleanupBuffer()

        // Update current HR
        currentHR = bpm
        peakHR = max(peakHR, bpm)

        // Run phase detection
        updatePhaseDetection(currentBPM: bpm, timestamp: date)
    }

    /// Reset tracker for new workout
    func reset() {
        currentPhase = .idle
        currentHR = 0
        peakHR = 0
        restPeriods.removeAll()
        fatigueLevel = .fresh
        degradationPercent = 0
        setsCompleted = 0
        hrBuffer.removeAll()
        setStartTime = nil
        restStartTime = nil
        currentRestPeriod = nil
        sessionBaseline = nil
    }

    /// Set baseline resting HR (from HealthKit history)
    func setBaselineHR(_ baseline: Double) {
        baselineHR = baseline
    }

    // MARK: - Phase Detection

    private func cleanupBuffer() {
        let cutoff = Date().addingTimeInterval(-bufferDuration)
        hrBuffer.removeAll { $0.date < cutoff }
    }

    private func updatePhaseDetection(currentBPM: Double, timestamp: Date) {
        guard hrBuffer.count >= 5 else { return }

        // Calculate HR derivative (bpm/sec)
        let derivative = calculateDerivative()

        switch currentPhase {
        case .idle:
            // Detect set start: significant HR acceleration
            if derivative > hrAccelerationThreshold {
                transitionToExertion(timestamp: timestamp, initialHR: currentBPM)
            }

        case .exertion:
            // Update peak HR during set
            peakHR = max(peakHR, currentBPM)

            // Check for set end conditions
            if derivative < -hrDecelerationThreshold {
                // HR dropping = set ended
                transitionToRecovery(timestamp: timestamp, peakHR: peakHR)
            } else if let start = setStartTime,
                      timestamp.timeIntervalSince(start) > maxSetDuration {
                // Safety cap exceeded
                transitionToRecovery(timestamp: timestamp, peakHR: peakHR)
            }

        case .recovery:
            // Update current rest period
            if var period = currentRestPeriod {
                period.endHR = currentBPM
                period.duration = timestamp.timeIntervalSince(period.startTime)
                currentRestPeriod = period
            }

            // Check for transition to resting (HR stabilized)
            if abs(derivative) < 0.1 {
                transitionToResting()
            }

            // Check for next set start
            if derivative > hrAccelerationThreshold {
                finalizeRestPeriod()
                transitionToExertion(timestamp: timestamp, initialHR: currentBPM)
            }

        case .resting:
            // Check for next set start
            if derivative > hrAccelerationThreshold {
                finalizeRestPeriod()
                transitionToExertion(timestamp: timestamp, initialHR: currentBPM)
            }
        }
    }

    private func calculateDerivative() -> Double {
        guard hrBuffer.count >= 2 else { return 0 }

        // Use last 10 seconds of data
        let recentSamples = hrBuffer.suffix(10)
        guard recentSamples.count >= 2 else { return 0 }

        let firstSample = recentSamples.first!
        let lastSample = recentSamples.last!

        let timeDelta = lastSample.date.timeIntervalSince(firstSample.date)
        guard timeDelta > 0 else { return 0 }

        let bpmDelta = lastSample.bpm - firstSample.bpm
        return bpmDelta / timeDelta
    }

    // MARK: - Phase Transitions

    private func transitionToExertion(timestamp: Date, initialHR: Double) {
        currentPhase = .exertion
        setStartTime = timestamp
        peakHR = initialHR
    }

    private func transitionToRecovery(timestamp: Date, peakHR: Double) {
        currentPhase = .recovery
        restStartTime = timestamp
        setsCompleted += 1

        // Start new rest period
        currentRestPeriod = RestPeriod(
            startTime: timestamp,
            startHR: peakHR,
            endHR: peakHR,
            duration: 0
        )
    }

    private func transitionToResting() {
        currentPhase = .resting
    }

    private func finalizeRestPeriod() {
        guard var period = currentRestPeriod else { return }

        // Only count if rest was long enough
        if period.duration >= minRestDuration {
            period.endHR = currentHR
            restPeriods.append(period)

            // Establish session baseline from first valid rest periods
            if sessionBaseline == nil && restPeriods.count >= 2 {
                let earlyRates = restPeriods.prefix(3).map(\.recoveryRate)
                sessionBaseline = earlyRates.sorted(by: >).prefix(2).reduce(0, +) / 2
            }

            // Update degradation and fatigue
            calculateDegradation()
        }

        currentRestPeriod = nil
        restStartTime = nil
    }

    // MARK: - Fatigue Calculation

    private func calculateDegradation() {
        guard let baseline = sessionBaseline,
              baseline > 0,
              restPeriods.count >= rollingWindowSize else {
            degradationPercent = 0
            return
        }

        // Calculate rolling average of recent recovery rates
        let recentRates = restPeriods.suffix(rollingWindowSize).map(\.recoveryRate)
        let currentAverage = recentRates.reduce(0, +) / Double(recentRates.count)

        // Calculate degradation from session baseline
        degradationPercent = ((baseline - currentAverage) / baseline) * 100

        // Calculate variance to detect plateau
        let variance = calculateVariance(recentRates)
        let normalizedVariance = (variance / baseline) * 100

        // Determine fatigue level
        updateFatigueLevel(
            degradation: degradationPercent,
            variance: normalizedVariance
        )
    }

    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count))
    }

    private func updateFatigueLevel(degradation: Double, variance: Double) {
        // Check for asymptote: low variance + significant degradation
        let isAsymptote = variance < asymptoteVariance && degradation > significantDegradation

        switch (degradation, isAsymptote) {
        case (_, true) where degradation > 40:
            fatigueLevel = .depleted
        case (_, true):
            fatigueLevel = .asymptote
        case (35..., _):
            fatigueLevel = .fatigued
        case (15..., _):
            fatigueLevel = .productive
        default:
            fatigueLevel = .fresh
        }
    }
}

// MARK: - Extensions

extension HRRTracker {
    /// Get estimated sets remaining before hitting asymptote
    var estimatedSetsRemaining: Int? {
        guard restPeriods.count >= 3,
              degradationPercent > 0,
              degradationPercent < 50 else {
            return nil
        }

        // Simple linear projection
        let rateOfDegradation = degradationPercent / Double(restPeriods.count)
        guard rateOfDegradation > 0 else { return nil }

        let remainingDegradation = 50 - degradationPercent  // 50% = depleted
        return Int(remainingDegradation / rateOfDegradation)
    }

    /// Average recovery rate for the session
    var averageRecoveryRate: Double {
        guard !restPeriods.isEmpty else { return 0 }
        return restPeriods.map(\.recoveryRate).reduce(0, +) / Double(restPeriods.count)
    }

    /// Latest recovery rate
    var latestRecoveryRate: Double? {
        restPeriods.last?.recoveryRate
    }
}
