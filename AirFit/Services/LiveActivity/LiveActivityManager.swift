//
//  LiveActivityManager.swift
//  AirFit
//
//  Created on 2025-09-06 for iPhone 16 Pro Dynamic Island integration
//  Manages Live Activities for workout tracking, nutrition, and AI coaching
//

import ActivityKit
import SwiftUI
import Foundation
import Observation

@MainActor
@Observable
final class LiveActivityManager: ServiceProtocol {
    
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "live-activity-manager"
    private(set) var isConfigured = false
    
    // MARK: - Properties
    private var currentWorkoutActivity: Activity<AirFitActivityAttributes>?
    private var currentNutritionActivity: Activity<NutritionActivityAttributes>?
    private var currentCoachActivity: Activity<CoachActivityAttributes>?
    
    // Activity state tracking
    private(set) var isWorkoutActivityActive = false
    private(set) var isNutritionActivityActive = false
    private(set) var isCoachActivityActive = false
    
    // Configuration
    private let maxActivitiesPerType = 1
    private let defaultActivityDuration: TimeInterval = 8 * 60 * 60 // 8 hours
    
    // MARK: - Initialization
    init() {
        // Initialize with Live Activity availability check
        updateActivityStates()
    }
    
    // MARK: - ServiceProtocol Implementation
    func configure() async throws {
        guard !isConfigured else { return }
        
        // Check if Live Activities are available and enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            AppLogger.warning("Live Activities are not enabled", category: .system)
            isConfigured = true
            return
        }
        
        // Set up notification observers for activity management
        setupNotificationObservers()
        
        isConfigured = true
        AppLogger.info("LiveActivityManager configured successfully", category: .system)
    }
    
    func reset() async {
        await endAllActivities()
        removeNotificationObservers()
        isConfigured = false
        updateActivityStates()
    }
    
    func healthCheck() async -> ServiceHealth {
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        let activeCount = Activity<AirFitActivityAttributes>.activities.count + 
                         Activity<NutritionActivityAttributes>.activities.count +
                         Activity<CoachActivityAttributes>.activities.count
        
        return ServiceHealth(
            status: areActivitiesEnabled ? .healthy : .degraded,
            lastCheckTime: .now,
            responseTime: nil,
            errorMessage: areActivitiesEnabled ? nil : "Live Activities not enabled",
            metadata: [
                "activitiesEnabled": "\(areActivitiesEnabled)",
                "activeCount": "\(activeCount)"
            ]
        )
    }
    
    // MARK: - Workout Live Activities
    
    /// Starts a workout Live Activity with the specified parameters
    func startWorkoutActivity(
        workoutType: String,
        goalCalories: Int? = nil,
        estimatedDuration: TimeInterval? = nil
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        
        // End existing workout activity if any
        await endWorkoutActivity()
        
        let attributes = AirFitActivityAttributes(
            workoutType: workoutType,
            startTime: Date(),
            userGoalCalories: goalCalories,
            estimatedDuration: estimatedDuration
        )
        
        let initialState = AirFitActivityAttributes.AirFitContentState(
            calories: 0,
            activeMinutes: 0,
            currentActivity: "Starting \(workoutType)",
            heartRate: nil,
            isWorkoutActive: true,
            workoutProgress: 0.0,
            currentExercise: nil,
            targetCalories: goalCalories,
            elapsedSeconds: 0,
            intensity: .light,
            zone: nil
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(defaultActivityDuration)
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            
            currentWorkoutActivity = activity
            isWorkoutActivityActive = true
            
            AppLogger.info("Started workout Live Activity: \(workoutType)", category: .health)
            
            // Add subtle haptic feedback for activity start
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            AppLogger.error("Failed to start workout Live Activity", error: error, category: .health)
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    /// Updates the current workout Live Activity with new metrics
    func updateWorkoutActivity(
        calories: Int,
        activeMinutes: Int,
        heartRate: Int? = nil,
        currentActivity: String,
        currentExercise: String? = nil,
        elapsedSeconds: Int,
        intensity: WorkoutIntensity = .moderate,
        zone: HeartRateZone? = nil
    ) async {
        guard let activity = currentWorkoutActivity else {
            AppLogger.warning("Attempted to update workout activity but none is active", category: .health)
            return
        }
        
        // Calculate progress based on goal or time
        let progress: Double
        if let targetCalories = activity.attributes.userGoalCalories, targetCalories > 0 {
            progress = min(1.0, Double(calories) / Double(targetCalories))
        } else if let estimatedDuration = activity.attributes.estimatedDuration {
            progress = min(1.0, Double(elapsedSeconds) / estimatedDuration)
        } else {
            progress = 0.0
        }
        
        let newState = AirFitActivityAttributes.AirFitContentState(
            calories: calories,
            activeMinutes: activeMinutes,
            currentActivity: currentActivity,
            heartRate: heartRate,
            isWorkoutActive: true,
            workoutProgress: progress,
            currentExercise: currentExercise,
            targetCalories: activity.attributes.userGoalCalories,
            elapsedSeconds: elapsedSeconds,
            intensity: intensity,
            zone: zone
        )
        
        let content = ActivityContent(
            state: newState,
            staleDate: Date().addingTimeInterval(defaultActivityDuration)
        )
        
        do {
            await activity.update(content)
        } catch {
            AppLogger.error("Failed to update workout Live Activity", error: error, category: .health)
        }
    }
    
    /// Ends the current workout Live Activity
    func endWorkoutActivity() async {
        guard let activity = currentWorkoutActivity else { return }
        
        // Create final state
        let finalState = activity.content.state
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .default)
        
        currentWorkoutActivity = nil
        isWorkoutActivityActive = false
        
        AppLogger.info("Ended workout Live Activity", category: .health)
    }
    
    // MARK: - Nutrition Live Activities
    
    func startNutritionActivity(dailyGoal: NutritionGoals) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        
        await endNutritionActivity()
        
        let attributes = NutritionActivityAttributes(
            dailyGoal: dailyGoal,
            startDate: Date()
        )
        
        let initialState = NutritionActivityAttributes.NutritionContentState(
            currentCalories: 0,
            currentProtein: 0,
            currentCarbs: 0,
            currentFat: 0,
            mealsLogged: 0,
            lastMealTime: nil,
            isComplete: false
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            
            currentNutritionActivity = activity
            isNutritionActivityActive = true
            
            AppLogger.info("Started nutrition Live Activity", category: .nutrition)
            
        } catch {
            AppLogger.error("Failed to start nutrition Live Activity", error: error, category: .nutrition)
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    func updateNutritionActivity(
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        mealsLogged: Int,
        lastMealTime: Date?
    ) async {
        guard let activity = currentNutritionActivity else { return }
        
        let goalMet = calories >= Int(activity.attributes.dailyGoal.calories)
        
        let newState = NutritionActivityAttributes.NutritionContentState(
            currentCalories: calories,
            currentProtein: protein,
            currentCarbs: carbs,
            currentFat: fat,
            mealsLogged: mealsLogged,
            lastMealTime: lastMealTime,
            isComplete: goalMet
        )
        
        let content = ActivityContent(
            state: newState,
            staleDate: Date().addingTimeInterval(24 * 60 * 60)
        )
        
        do {
            await activity.update(content)
        } catch {
            AppLogger.error("Failed to update nutrition Live Activity", error: error, category: .nutrition)
        }
    }
    
    func endNutritionActivity() async {
        guard let activity = currentNutritionActivity else { return }
        
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .default)
        
        currentNutritionActivity = nil
        isNutritionActivityActive = false
        
        AppLogger.info("Ended nutrition Live Activity", category: .nutrition)
    }
    
    // MARK: - AI Coach Live Activities
    
    func startCoachActivity(
        sessionType: CoachSessionType,
        initialMessage: String
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        
        await endCoachActivity()
        
        let attributes = CoachActivityAttributes(
            sessionType: sessionType,
            startTime: Date()
        )
        
        let initialState = CoachActivityAttributes.CoachContentState(
            lastMessage: initialMessage,
            messageCount: 1,
            sessionActive: true,
            responseWaiting: false,
            urgency: .normal
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(2 * 60 * 60) // 2 hours
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            
            currentCoachActivity = activity
            isCoachActivityActive = true
            
            AppLogger.info("Started AI coach Live Activity: \(sessionType)", category: .ai)
            
        } catch {
            AppLogger.error("Failed to start coach Live Activity", error: error, category: .ai)
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    func updateCoachActivity(
        message: String,
        messageCount: Int,
        isWaitingForResponse: Bool = false,
        urgency: CoachUrgency = .normal
    ) async {
        guard let activity = currentCoachActivity else { return }
        
        let newState = CoachActivityAttributes.CoachContentState(
            lastMessage: message,
            messageCount: messageCount,
            sessionActive: true,
            responseWaiting: isWaitingForResponse,
            urgency: urgency
        )
        
        let content = ActivityContent(
            state: newState,
            staleDate: Date().addingTimeInterval(2 * 60 * 60)
        )
        
        do {
            await activity.update(content)
        } catch {
            AppLogger.error("Failed to update coach Live Activity", error: error, category: .ai)
        }
    }
    
    func endCoachActivity() async {
        guard let activity = currentCoachActivity else { return }
        
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .default)
        
        currentCoachActivity = nil
        isCoachActivityActive = false
        
        AppLogger.info("Ended AI coach Live Activity", category: .ai)
    }
    
    // MARK: - Utility Methods
    
    /// Ends all active Live Activities
    func endAllActivities() async {
        await endWorkoutActivity()
        await endNutritionActivity()
        await endCoachActivity()
    }
    
    /// Updates the internal state based on currently active activities
    private func updateActivityStates() {
        isWorkoutActivityActive = !Activity<AirFitActivityAttributes>.activities.isEmpty
        isNutritionActivityActive = !Activity<NutritionActivityAttributes>.activities.isEmpty
        isCoachActivityActive = !Activity<CoachActivityAttributes>.activities.isEmpty
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .pauseWorkout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handlePauseWorkout() }
        }
        
        NotificationCenter.default.addObserver(
            forName: .endWorkout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleEndWorkout() }
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func handlePauseWorkout() async {
        // Notify the workout system to pause
        NotificationCenter.default.post(name: .workoutPaused, object: nil)
    }
    
    private func handleEndWorkout() async {
        // Notify the workout system to end
        NotificationCenter.default.post(name: .workoutEnded, object: nil)
        await endWorkoutActivity()
    }
}

// MARK: - Supporting Types and Errors

enum LiveActivityError: LocalizedError {
    case notEnabled
    case failedToStart(Error)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notEnabled:
            return "Live Activities are not enabled on this device"
        case .failedToStart(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        case .notFound:
            return "Live Activity not found"
        }
    }
}

// Nutrition-specific types
struct NutritionGoals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct NutritionActivityAttributes: ActivityAttributes {
    public typealias ContentState = NutritionContentState
    
    public struct NutritionContentState: Codable, Hashable {
        let currentCalories: Int
        let currentProtein: Double
        let currentCarbs: Double
        let currentFat: Double
        let mealsLogged: Int
        let lastMealTime: Date?
        let isComplete: Bool
    }
    
    let dailyGoal: NutritionGoals
    let startDate: Date
}

// Coach-specific types
enum CoachSessionType: String, Codable {
    case workout = "Workout Guidance"
    case nutrition = "Nutrition Coaching"
    case recovery = "Recovery Check-in"
    case motivation = "Motivation"
}

enum CoachUrgency: String, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case urgent = "Urgent"
}

struct CoachActivityAttributes: ActivityAttributes {
    public typealias ContentState = CoachContentState
    
    public struct CoachContentState: Codable, Hashable {
        let lastMessage: String
        let messageCount: Int
        let sessionActive: Bool
        let responseWaiting: Bool
        let urgency: CoachUrgency
    }
    
    let sessionType: CoachSessionType
    let startTime: Date
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let workoutPaused = Notification.Name("workoutPaused")
    static let workoutEnded = Notification.Name("workoutEnded")
}

// MARK: - NutritionGoals Codable Conformance

extension NutritionGoals: Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decode(Double.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fat = try container.decode(Double.self, forKey: .fat)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(calories)
        hasher.combine(protein)
        hasher.combine(carbs)
        hasher.combine(fat)
    }
    
    static func == (lhs: NutritionGoals, rhs: NutritionGoals) -> Bool {
        lhs.calories == rhs.calories &&
        lhs.protein == rhs.protein &&
        lhs.carbs == rhs.carbs &&
        lhs.fat == rhs.fat
    }
}