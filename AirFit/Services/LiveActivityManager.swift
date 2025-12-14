import ActivityKit
import Foundation

/// Manages the Nutrition tracking Live Activity.
/// Start it when the app opens, update as food is logged, end at midnight.
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published private(set) var isRunning = false
    private var currentActivity: Activity<NutritionActivityAttributes>?

    private init() {}

    // MARK: - Lifecycle

    /// Start the Live Activity for today's nutrition tracking.
    func startTracking(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        isTrainingDay: Bool
    ) async {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        // End any existing activity first (properly awaited)
        await endTracking()

        let targets = isTrainingDay
            ? (cal: 2600, protein: 175, carbs: 330, fat: 67)
            : (cal: 2200, protein: 175, carbs: 250, fat: 57)

        let attributes = NutritionActivityAttributes(date: Date())
        let state = NutritionActivityAttributes.ContentState(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            targetCalories: targets.cal,
            targetProtein: targets.protein,
            targetCarbs: targets.carbs,
            targetFat: targets.fat,
            isTrainingDay: isTrainingDay,
            lastUpdated: Date()
        )

        // Mark stale after 4 hours without update
        let staleDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
        let content = ActivityContent(state: state, staleDate: staleDate)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            isRunning = true
            print("Live Activity started")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Live Activity with new totals.
    func update(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        isTrainingDay: Bool
    ) async {
        guard let activity = currentActivity else {
            // Start a new one if none exists
            await startTracking(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                isTrainingDay: isTrainingDay
            )
            return
        }

        let targets = isTrainingDay
            ? (cal: 2600, protein: 175, carbs: 330, fat: 67)
            : (cal: 2200, protein: 175, carbs: 250, fat: 57)

        let state = NutritionActivityAttributes.ContentState(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            targetCalories: targets.cal,
            targetProtein: targets.protein,
            targetCarbs: targets.carbs,
            targetFat: targets.fat,
            isTrainingDay: isTrainingDay,
            lastUpdated: Date()
        )

        let content = ActivityContent(state: state, staleDate: nil)

        // Capture activity ID to avoid sending non-Sendable Activity across actors
        let activityId = activity.id
        await updateActivityById(activityId, content: content)
        print("Live Activity updated: \(calories) cal, \(protein)g protein")
    }

    /// Update activity by ID (nonisolated to avoid Sendable issues)
    private nonisolated func updateActivityById(
        _ id: String,
        content: ActivityContent<NutritionActivityAttributes.ContentState>
    ) async {
        for activity in Activity<NutritionActivityAttributes>.activities where activity.id == id {
            await activity.update(content)
            break
        }
    }

    /// End the Live Activity.
    func endTracking() async {
        guard let activity = currentActivity else { return }

        // Capture activity ID to avoid sending non-Sendable Activity across actors
        let activityId = activity.id
        await endActivityById(activityId)
        currentActivity = nil
        isRunning = false
        print("Live Activity ended")
    }

    /// End activity by ID (nonisolated to avoid Sendable issues)
    private nonisolated func endActivityById(_ id: String) async {
        for activity in Activity<NutritionActivityAttributes>.activities where activity.id == id {
            await activity.end(nil, dismissalPolicy: .immediate)
            break
        }
    }

    /// End all activities (nonisolated to avoid Sendable issues)
    private nonisolated func endAllActivitiesNonisolated() async {
        for activity in Activity<NutritionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// End all nutrition activities (cleanup).
    func endAllActivities() async {
        await endAllActivitiesNonisolated()
        currentActivity = nil
        isRunning = false
    }

    // MARK: - Helpers

    /// Check if there's an active Live Activity from today.
    /// Returns the activity ID if resumed, nil otherwise.
    func resumeExistingActivity() async {
        // Get activity info in nonisolated context
        let activityInfo = await getExistingActivityInfo()

        guard let info = activityInfo else { return }

        if info.isToday {
            // Re-fetch to set currentActivity (safe because we're on MainActor)
            if let existing = Activity<NutritionActivityAttributes>.activities.first(where: { $0.id == info.id }) {
                currentActivity = existing
                isRunning = true
                print("Resumed existing Live Activity")
            }
        } else {
            // Old activity - end it by ID
            await endActivityById(info.id)
        }
    }

    /// Get existing activity info (nonisolated to avoid Sendable issues)
    private nonisolated func getExistingActivityInfo() async -> (id: String, isToday: Bool)? {
        guard let existing = Activity<NutritionActivityAttributes>.activities.first else {
            return nil
        }
        let isToday = Calendar.current.isDateInToday(existing.attributes.date)
        return (existing.id, isToday)
    }
}
