import SwiftUI
import WatchKit

/// Real-time workout HRR tracking view.
/// Shows heart rate, fatigue level, and recovery degradation during workout.
struct WorkoutHRRView: View {
    @StateObject private var hrrTracker = HRRTracker.shared
    @StateObject private var healthKitManager = WatchHealthKitManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isTracking = false
    @State private var showEndConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Workout status header
                WorkoutStatusHeader(
                    isTracking: isTracking,
                    fatigueLevel: hrrTracker.fatigueLevel,
                    setsCompleted: hrrTracker.setsCompleted
                )

                // Heart rate display
                HeartRateCard(
                    currentHR: hrrTracker.currentHR,
                    peakHR: hrrTracker.peakHR,
                    phase: hrrTracker.currentPhase
                )

                // Fatigue meter
                FatigueMeter(
                    level: hrrTracker.fatigueLevel,
                    degradation: hrrTracker.degradationPercent
                )

                // Recovery history
                if !hrrTracker.restPeriods.isEmpty {
                    RecoveryHistoryCard(restPeriods: hrrTracker.restPeriods)
                }

                // Start/Stop button
                WorkoutControlButton(
                    isTracking: isTracking,
                    onStart: startTracking,
                    onStop: { showEndConfirmation = true }
                )
            }
            .padding(.horizontal)
        }
        .navigationTitle("HRR Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "End Workout?",
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                stopTracking()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("You've completed \(hrrTracker.setsCompleted) sets.")
        }
        .onChange(of: hrrTracker.fatigueLevel) { _, newLevel in
            // Haptic feedback on fatigue level change
            provideFatigueHaptic(level: newLevel)
        }
    }

    // MARK: - Actions

    private func startTracking() {
        Task {
            do {
                // Start HealthKit observation
                try await healthKitManager.startHeartRateObservation()

                // Get baseline HR
                if let baseline = await healthKitManager.getRestingHeartRate() {
                    await MainActor.run {
                        hrrTracker.setBaselineHR(baseline)
                    }
                }

                // Wire up sample callback
                await healthKitManager.setOnHeartRateSample { sample in
                    Task { @MainActor in
                        hrrTracker.processSample(sample)
                    }
                }

                await MainActor.run {
                    hrrTracker.reset()
                    isTracking = true
                }
            } catch {
                print("Failed to start tracking: \(error)")
            }
        }
    }

    private func stopTracking() {
        Task {
            await healthKitManager.stopHeartRateObservation()

            // Send session data to iPhone
            let connectivityManager = await WatchConnectivityManager.shared
            await connectivityManager.sendHRRSessionData(hrrTracker.sessionData)

            await MainActor.run {
                isTracking = false
                dismiss()
            }
        }
    }

    private func provideFatigueHaptic(level: HRRTracker.FatigueLevel) {
        switch level {
        case .fresh, .productive:
            break  // No haptic for positive states
        case .fatigued:
            WKInterfaceDevice.current().play(.notification)
        case .asymptote:
            WKInterfaceDevice.current().play(.notification)
            WKInterfaceDevice.current().play(.notification)
        case .depleted:
            WKInterfaceDevice.current().play(.failure)
        }
    }
}

// MARK: - Workout Status Header

private struct WorkoutStatusHeader: View {
    let isTracking: Bool
    let fatigueLevel: HRRTracker.FatigueLevel
    let setsCompleted: Int

    var body: some View {
        HStack {
            // Tracking indicator
            Circle()
                .fill(isTracking ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(isTracking ? "Tracking" : "Ready")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Sets counter
            if setsCompleted > 0 {
                Text("\(setsCompleted) sets")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Heart Rate Card

private struct HeartRateCard: View {
    let currentHR: Double
    let peakHR: Double
    let phase: HRRTracker.ActivityPhase

    private var phaseColor: Color {
        switch phase {
        case .idle: return .gray
        case .exertion: return .red
        case .recovery: return .orange
        case .resting: return .green
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Current HR
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)

                Text("\(Int(currentHR))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("bpm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Phase indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)

                Text(phase.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(phaseColor)

                Spacer()

                if peakHR > 0 {
                    Text("Peak: \(Int(peakHR))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Fatigue Meter

private struct FatigueMeter: View {
    let level: HRRTracker.FatigueLevel
    let degradation: Double

    private var meterColor: Color {
        switch level {
        case .fresh: return .green
        case .productive: return .blue
        case .fatigued: return .yellow
        case .asymptote: return .orange
        case .depleted: return .red
        }
    }

    private var fillAmount: Double {
        switch level {
        case .fresh: return 0.1
        case .productive: return 0.3
        case .fatigued: return 0.5
        case .asymptote: return 0.75
        case .depleted: return 1.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: level.icon)
                    .foregroundColor(meterColor)
                Text("Fatigue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if degradation > 0 {
                    Text("-\(Int(degradation))%")
                        .font(.caption.bold())
                        .foregroundColor(meterColor)
                }
            }

            // Meter bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(meterColor)
                        .frame(width: geo.size.width * fillAmount)
                }
            }
            .frame(height: 8)

            // Message
            Text(level.message)
                .font(.caption2)
                .foregroundColor(meterColor)
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Recovery History Card

private struct RecoveryHistoryCard: View {
    let restPeriods: [HRRTracker.RestPeriod]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery History")
                .font(.caption)
                .foregroundColor(.secondary)

            // Show last 5 rest periods as mini bars
            HStack(spacing: 4) {
                ForEach(restPeriods.suffix(5)) { period in
                    VStack(spacing: 2) {
                        // Recovery rate bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(recoveryColor(for: period.recoveryRate))
                            .frame(width: 16, height: barHeight(for: period.recoveryRate))

                        Text(String(format: "%.1f", period.recoveryRate))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 50, alignment: .bottom)

            // Legend
            Text("bpm/sec recovery")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }

    private func recoveryColor(for rate: Double) -> Color {
        switch rate {
        case 0.8...: return .green
        case 0.5...: return .blue
        case 0.3...: return .yellow
        default: return .red
        }
    }

    private func barHeight(for rate: Double) -> CGFloat {
        let normalized = min(1.0, rate / 1.5)  // Normalize to 1.5 bpm/sec max
        return max(8, CGFloat(normalized) * 40)
    }
}

// MARK: - Workout Control Button

private struct WorkoutControlButton: View {
    let isTracking: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        Button(action: isTracking ? onStop : onStart) {
            HStack {
                Image(systemName: isTracking ? "stop.fill" : "play.fill")
                Text(isTracking ? "End Workout" : "Start Tracking")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isTracking ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutHRRView()
    }
}

// MARK: - HealthKitManager Extension

extension WatchHealthKitManager {
    func setOnHeartRateSample(_ callback: @escaping @Sendable (HRSample) -> Void) {
        self.onHeartRateSample = callback
    }
}
