//
//  AirFitLiveActivity.swift
//  AirFit
//
//  Created on 2025-09-06 for iPhone 16 Pro Dynamic Island integration
//  iOS 26 Enhanced with Liquid Glass effects
//

import ActivityKit
import SwiftUI
import AppIntents
import WidgetKit

// MARK: - Live Activity Attributes

/// Defines the Live Activity attributes for AirFit workout tracking
struct AirFitActivityAttributes: ActivityAttributes {
    public typealias ContentState = AirFitContentState
    
    /// Dynamic state that updates during the activity
    public struct AirFitContentState: Codable, Hashable {
        // Core workout metrics
        let calories: Int
        let activeMinutes: Int
        let currentActivity: String
        let heartRate: Int?
        let isWorkoutActive: Bool
        
        // Additional context
        let workoutProgress: Double // 0.0 to 1.0
        let currentExercise: String?
        let targetCalories: Int?
        let elapsedSeconds: Int
        
        // Performance indicators
        let intensity: WorkoutIntensity
        let zone: HeartRateZone?
    }
    
    // Static values set at activity start
    let workoutType: String
    let startTime: Date
    let userGoalCalories: Int?
    let estimatedDuration: TimeInterval?
}

// MARK: - Supporting Types

enum WorkoutIntensity: String, Codable, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case vigorous = "Vigorous"
    case peak = "Peak"
    
    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .yellow
        case .vigorous: return .orange
        case .peak: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .vigorous: return "figure.strengthtraining.traditional"
        case .peak: return "bolt.fill"
        }
    }
}

enum HeartRateZone: String, Codable, CaseIterable {
    case zone1 = "Zone 1"
    case zone2 = "Zone 2"
    case zone3 = "Zone 3"
    case zone4 = "Zone 4"
    case zone5 = "Zone 5"
    
    var color: Color {
        switch self {
        case .zone1: return .gray
        case .zone2: return .blue
        case .zone3: return .green
        case .zone4: return .yellow
        case .zone5: return .red
        }
    }
}

// MARK: - Dynamic Island Views

// WORKOUT FEATURES REMOVED - This entire widget is disabled
/*
struct AirFitLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AirFitActivityAttributes.self) { context in
            // Lock screen view with iOS 26 Liquid Glass effects
            LockScreenView(context: context)
                .glassEffect(.regular)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view when user long-presses the Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Workout type and intensity indicator
                        HStack(spacing: 6) {
                            Image(systemName: context.state.intensity.systemImage)
                                .foregroundStyle(context.state.intensity.color)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(context.attributes.workoutType)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        
                        // Heart rate zone if available
                        if let zone = context.state.zone {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(zone.color)
                                    .frame(width: 8, height: 8)
                                Text(zone.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Calories burned with goal progress
                        HStack(spacing: 4) {
                            Text("\(context.state.calories)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("cal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Goal progress if available
                        if let targetCals = context.state.targetCalories {
                            let progress = Double(context.state.calories) / Double(targetCals)
                            HStack(spacing: 2) {
                                Text("\(Int(progress * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: progress)
                                    .frame(width: 30)
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        // Current activity or exercise
                        Text(context.state.currentActivity)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        // Heart rate if available
                        if let hr = context.state.heartRate {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 14))
                                    .symbolEffect(.pulse.byLayer, isActive: context.state.isWorkoutActive)
                                
                                Text("\(hr)")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                                
                                Text("BPM")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Workout timer
                        Text(formatWorkoutTime(context.state.elapsedSeconds))
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        // Active minutes indicator
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 16))
                            Text("\(context.state.activeMinutes) min")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Action buttons with Liquid Glass effect
                        HStack(spacing: 12) {
                            Button(intent: PauseWorkoutIntent()) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.thin)
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial, in: Circle())
                            
                            Button(intent: EndWorkoutIntent()) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.thin)
                            .frame(width: 32, height: 32)
                            .background(.red.opacity(0.2), in: Circle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                // Compact left side - Workout intensity indicator
                Image(systemName: context.state.intensity.systemImage)
                    .foregroundStyle(context.state.intensity.color)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.bounce, value: context.state.currentActivity)
            } compactTrailing: {
                // Compact right side - Calories and time
                VStack(spacing: 1) {
                    Text("\(context.state.calories)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(formatCompactTime(context.state.elapsedSeconds))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } minimal: {
                // Minimal view - Just the workout type icon
                Image(systemName: getWorkoutIcon(for: context.attributes.workoutType))
                    .foregroundStyle(.green)
                    .font(.system(size: 14, weight: .medium))
                    .symbolEffect(.pulse, isActive: context.state.isWorkoutActive)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<AirFitActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with workout type and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.workoutType)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Started at \(context.attributes.startTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatWorkoutTime(context.state.elapsedSeconds))
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                    
                    if let zone = context.state.zone {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 8, height: 8)
                            Text(zone.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Metrics row
            HStack(spacing: 24) {
                MetricView(
                    value: "\(context.state.calories)",
                    unit: "cal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                if let hr = context.state.heartRate {
                    MetricView(
                        value: "\(hr)",
                        unit: "BPM",
                        icon: "heart.fill",
                        color: .red
                    )
                }
                
                MetricView(
                    value: "\(context.state.activeMinutes)",
                    unit: "min",
                    icon: "figure.run",
                    color: .green
                )
            }
            
            // Progress bar if goal is set
            if let target = context.state.targetCalories, target > 0 {
                let progress = Double(context.state.calories) / Double(target)
                VStack(spacing: 4) {
                    HStack {
                        Text("Goal Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 0.8)
                }
            }
            
            // Current activity
            if !context.state.currentActivity.isEmpty {
                Text(context.state.currentActivity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(16)
    }
}

// MARK: - Helper Views

struct MetricView: View {
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16))
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Helper Functions

private func formatWorkoutTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

private func formatCompactTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    return "\(minutes)m"
}

private func getWorkoutIcon(for workoutType: String) -> String {
    switch workoutType.lowercased() {
    case "running", "run":
        return "figure.run"
    case "cycling", "bike":
        return "figure.outdoor.cycle"
    case "swimming":
        return "figure.pool.swim"
    case "strength", "weights":
        return "figure.strengthtraining.traditional"
    case "yoga":
        return "figure.yoga"
    case "hiit":
        return "bolt.fill"
    default:
        return "figure.mixed.cardio"
    }
}
*/

// MARK: - App Intents

// WORKOUT FEATURES REMOVED - These intents are no longer needed
/*
struct PauseWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Workout"
    
    func perform() async throws -> some IntentResult {
        // Send notification to pause workout
        NotificationCenter.default.post(name: .pauseWorkout, object: nil)
        return .result()
    }
}

struct EndWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "End Workout"
    
    func perform() async throws -> some IntentResult {
        // Send notification to end workout
        NotificationCenter.default.post(name: .endWorkout, object: nil)
        return .result()
    }
}
*/

// MARK: - Notification Extensions
// WORKOUT FEATURES REMOVED - These notifications are no longer needed
/*
extension Notification.Name {
    static let pauseWorkout = Notification.Name("pauseWorkout")
    static let endWorkout = Notification.Name("endWorkout")
}
*/