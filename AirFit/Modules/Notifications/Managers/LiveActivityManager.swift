import ActivityKit
import SwiftUI

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    // Active activities
    private var workoutActivity: Activity<WorkoutActivityAttributes>?
    private var mealTrackingActivity: Activity<MealTrackingActivityAttributes>?
    
    private init() {}
    
    // MARK: - Workout Live Activity
    func startWorkoutActivity(
        workoutType: String,
        startTime: Date
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        
        let attributes = WorkoutActivityAttributes(
            workoutType: workoutType,
            startTime: startTime
        )
        
        let initialState = WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            heartRate: 0,
            activeCalories: 0,
            currentExercise: nil
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(30 * 60) // 30 minutes
        )
        
        do {
            workoutActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            
            AppLogger.info("Started workout live activity", category: .ui)
            
        } catch {
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    func updateWorkoutActivity(
        elapsedTime: TimeInterval,
        heartRate: Int,
        activeCalories: Int,
        currentExercise: String?
    ) async {
        guard let activity = workoutActivity else { return }
        
        let updatedState = WorkoutActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            heartRate: heartRate,
            activeCalories: activeCalories,
            currentExercise: currentExercise
        )
        
        let content = ActivityContent(
            state: updatedState,
            staleDate: Date().addingTimeInterval(5 * 60) // 5 minutes
        )
        
        await activity.update(content)
    }
    
    func endWorkoutActivity() async {
        guard let activity = workoutActivity else { return }
        
        let finalState = WorkoutActivityAttributes.ContentState(
            elapsedTime: activity.content.state.elapsedTime,
            heartRate: 0,
            activeCalories: activity.content.state.activeCalories,
            currentExercise: "Workout Complete! 🎉"
        )
        
        let content = ActivityContent(
            state: finalState,
            staleDate: nil
        )
        
        await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(30)))
        workoutActivity = nil
        
        AppLogger.info("Ended workout live activity", category: .ui)
    }
    
    // MARK: - Meal Tracking Live Activity
    func startMealTrackingActivity(mealType: MealType) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        
        let attributes = MealTrackingActivityAttributes(
            mealType: mealType.rawValue,
            targetCalories: 600, // Would be personalized
            targetProtein: 30
        )
        
        let initialState = MealTrackingActivityAttributes.ContentState(
            itemsLogged: 0,
            totalCalories: 0,
            totalProtein: 0,
            lastFoodItem: nil
        )
        
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(2 * 60 * 60) // 2 hours
        )
        
        do {
            mealTrackingActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            
            AppLogger.info("Started meal tracking live activity", category: .ui)
            
        } catch {
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    func updateMealTracking(
        itemsLogged: Int,
        totalCalories: Int,
        totalProtein: Double,
        lastFoodItem: String?
    ) async {
        guard let activity = mealTrackingActivity else { return }
        
        let updatedState = MealTrackingActivityAttributes.ContentState(
            itemsLogged: itemsLogged,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            lastFoodItem: lastFoodItem
        )
        
        let content = ActivityContent(
            state: updatedState,
            staleDate: Date().addingTimeInterval(30 * 60)
        )
        
        await activity.update(content)
    }
    
    func endMealTrackingActivity() async {
        guard let activity = mealTrackingActivity else { return }
        
        await activity.end(dismissalPolicy: .immediate)
        mealTrackingActivity = nil
        
        AppLogger.info("Ended meal tracking live activity", category: .ui)
    }
    
    // MARK: - Activity Management
    func endAllActivities() async {
        await endWorkoutActivity()
        await endMealTrackingActivity()
    }
    
    func observePushTokenUpdates() {
        Task {
            for await activity in Activity<WorkoutActivityAttributes>.activityUpdates {
                if let pushToken = activity.pushToken {
                    // Send token to server
                    await sendPushTokenToServer(pushToken)
                }
            }
        }
    }
    
    private func sendPushTokenToServer(_ token: Data) async {
        // Implementation would send to backend
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        AppLogger.info("Live activity push token: \(tokenString)", category: .general)
    }
}

// MARK: - Activity Attributes
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let elapsedTime: TimeInterval
        let heartRate: Int
        let activeCalories: Int
        let currentExercise: String?
    }
    
    let workoutType: String
    let startTime: Date
}

struct MealTrackingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let itemsLogged: Int
        let totalCalories: Int
        let totalProtein: Double
        let lastFoodItem: String?
    }
    
    let mealType: String
    let targetCalories: Int
    let targetProtein: Double
}

// MARK: - Errors
enum LiveActivityError: LocalizedError {
    case notEnabled
    case failedToStart(Error)
    
    var errorDescription: String? {
        switch self {
        case .notEnabled:
            return "Live Activities are not enabled"
        case .failedToStart(let error):
            return "Failed to start activity: \(error.localizedDescription)"
        }
    }
}
