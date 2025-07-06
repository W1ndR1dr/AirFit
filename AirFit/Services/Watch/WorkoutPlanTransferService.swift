import Foundation
import WatchConnectivity

// MARK: - Type-Safe Message Wrappers

/// Type-safe request for workout plan transfers
struct WorkoutTransferMessage: Sendable {
    let planData: Data
    let planId: UUID
    let timestamp: Date
    
    /// Convert to dictionary for WatchConnectivity
    var dictionary: [String: Any] {
        return [
            "type": "plannedWorkout",
            "planData": planData,
            "planId": planId.uuidString,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

/// Type-safe response from watch
struct WorkoutTransferResponse: Sendable {
    let success: Bool
    let errorMessage: String?
    
    /// Initialize from WatchConnectivity reply dictionary
    init?(dictionary: [String: Any]) {
        guard let success = dictionary["success"] as? Bool else {
            return nil
        }
        self.success = success
        self.errorMessage = dictionary["error"] as? String
    }
}

/// # WorkoutPlanTransferService
///
/// ## Purpose
/// Handles direct transfer of AI-generated workout plans from iOS to watchOS.
/// Provides seamless handoff of structured workout data for Apple Watch execution
/// without relying on WorkoutKit framework.
///
/// ## Key Responsibilities
/// - Transfer planned workouts from iOS to watchOS via WatchConnectivity
/// - Queue failed transfers for retry when watch becomes available
/// - Validate workout plans before transfer
/// - Handle transfer errors and provide user feedback
/// - Monitor watch connectivity status
///
/// ## Architecture Benefits
/// - **Direct Communication**: Bypasses problematic WorkoutKit scheduling
/// - **Offline Resilience**: Queues plans when watch unavailable
/// - **Type Safety**: Uses Codable models for reliable serialization
/// - **Service Layer**: Follows SERVICE_LAYER_STANDARDS with proper DI
///
/// ## Usage
/// ```swift
/// let transferService = await container.resolve(WorkoutPlanTransferProtocol.self)
///
/// // Convert AI plan to transfer model
/// let plannedWorkout = PlannedWorkoutData.from(
///     workoutPlan: aiGeneratedPlan,
///     workoutType: .strength,
///     userId: user.id
/// )
///
/// // Send to watch
/// try await transferService.sendWorkoutPlan(plannedWorkout)
/// ```

@MainActor
final class WorkoutPlanTransferService: WorkoutPlanTransferProtocol {
    // MARK: - Properties
    private let session: WCSession
    private let delegateHandler = WorkoutPlanTransferDelegateHandler()
    private var pendingPlans: [PlannedWorkoutData] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "workout-plan-transfer-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor services, configuration happens during DI setup
        true
    }

    // MARK: - Initialization
    init() {
        self.session = WCSession.default

        // Configure JSON encoding for consistency
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }

        // Setup WatchConnectivity session
        if WCSession.isSupported() {
            delegateHandler.configure(with: self)
            session.delegate = delegateHandler
            session.activate()

            _isConfigured = true
            AppLogger.info("\(serviceIdentifier) configured", category: .services)
        } else {
            throw AppError.unknown(message: "WatchConnectivity not supported on this device")
        }
    }

    func reset() async {
        pendingPlans.removeAll()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    nonisolated func healthCheck() async -> ServiceHealth {
        await MainActor.run {
            let isSupported = WCSession.isSupported()
            let sessionState = session.activationState
            let isReachable = session.isReachable

            let status: ServiceHealth.Status
            let errorMessage: String?

            if !isSupported {
                status = .unhealthy
                errorMessage = "WatchConnectivity not supported"
            } else if sessionState != .activated {
                status = .degraded
                errorMessage = "Session not activated: \(sessionState.rawValue)"
            } else if !isReachable {
                status = .degraded
                errorMessage = "Watch not reachable"
            } else {
                status = .healthy
                errorMessage = nil
            }

            return ServiceHealth(
                status: status,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: errorMessage,
                metadata: [
                    "pendingPlans": "\(pendingPlans.count)",
                    "sessionState": "\(sessionState.rawValue)",
                    "isReachable": "\(isReachable)",
                    "watchAppInstalled": "\(session.isWatchAppInstalled)"
                ]
            )
        }
    }

    // MARK: - WorkoutPlanTransferProtocol Implementation

    func sendWorkoutPlan(_ plan: PlannedWorkoutData) async throws {
        AppLogger.info("Sending workout plan to watch: \(plan.name)", category: .services)

        // Validate plan before sending
        try validateWorkoutPlan(plan)

        guard session.activationState == .activated else {
            throw AppError.unknown(message: "WatchConnectivity session not activated")
        }

        guard session.isWatchAppInstalled else {
            throw AppError.unknown(message: "AirFit Watch app not installed")
        }

        guard session.isReachable else {
            // Queue for later when connection is available
            pendingPlans.append(plan)
            AppLogger.warning("Watch not reachable, queuing workout plan: \(plan.name)", category: .services)

            // Post notification for UI feedback
            NotificationCenter.default.post(
                name: .workoutPlanTransferFailed,
                object: nil,
                userInfo: [
                    "planId": plan.id,
                    "error": "Watch not reachable",
                    "queued": true
                ]
            )
            return
        }

        do {
            // Encode workout plan
            let planData = try encoder.encode(plan)

            // Create type-safe message
            let transferMessage = WorkoutTransferMessage(
                planData: planData,
                planId: plan.id,
                timestamp: Date()
            )

            // Send with type-safe error handling
            do {
                let response = try await sendTransferMessage(transferMessage)
                
                if response.success {
                    AppLogger.info("Successfully sent workout plan to watch: \(plan.name)", category: .services)
                    
                    // Post success notification
                    NotificationCenter.default.post(
                        name: .workoutPlanTransferSuccess,
                        object: nil,
                        userInfo: [
                            "planId": plan.id,
                            "planName": plan.name
                        ]
                    )
                } else {
                    let error = AppError.unknown(message: "Watch rejected workout plan: \(response.errorMessage ?? "Unknown error")")
                    AppLogger.error("Watch rejected workout plan", error: error, category: .services)
                    throw error
                }
            } catch {
                // Queue for retry on send error
                pendingPlans.append(plan)
                AppLogger.error("Failed to send workout plan to watch", error: error, category: .services)
                
                // Post failure notification
                NotificationCenter.default.post(
                    name: .workoutPlanTransferFailed,
                    object: nil,
                    userInfo: [
                        "planId": plan.id,
                        "error": error.localizedDescription,
                        "queued": true
                    ]
                )
                
                throw error
            }

        } catch {
            // Add to pending queue on encoding error
            pendingPlans.append(plan)
            AppLogger.error("Failed to encode workout plan", error: error, category: .services)
            throw AppError.unknown(message: "Failed to transfer workout plan: \(error.localizedDescription)")
        }
    }

    func isWatchAvailable() async -> Bool {
        return session.activationState == .activated &&
            session.isReachable &&
            session.isWatchAppInstalled
    }

    func getPendingPlans() async -> [PlannedWorkoutData] {
        return pendingPlans
    }

    func retryPendingTransfers() async throws {
        guard await isWatchAvailable() else {
            AppLogger.warning("Cannot retry transfers - watch not available", category: .services)
            return
        }

        guard !pendingPlans.isEmpty else {
            AppLogger.info("No pending workout plans to retry", category: .services)
            return
        }

        AppLogger.info("Retrying \(pendingPlans.count) pending workout plan transfers", category: .services)

        let plansToRetry = pendingPlans
        pendingPlans.removeAll()

        var failedPlans: [PlannedWorkoutData] = []

        for plan in plansToRetry {
            do {
                try await sendWorkoutPlan(plan)
            } catch {
                failedPlans.append(plan)
                AppLogger.error("Failed to retry workout plan transfer: \(plan.name)", error: error, category: .services)
            }
        }

        // Re-queue any that failed again
        pendingPlans.append(contentsOf: failedPlans)

        if !failedPlans.isEmpty {
            throw AppError.unknown(message: "Failed to transfer \(failedPlans.count) workout plans")
        }
    }

    func cancelPendingPlan(id: UUID) async {
        pendingPlans.removeAll { $0.id == id }
        AppLogger.info("Cancelled pending workout plan transfer: \(id)", category: .services)
    }

    // MARK: - Private Methods
    
    /// Type-safe async wrapper for sendMessage
    private func sendTransferMessage(_ message: WorkoutTransferMessage) async throws -> WorkoutTransferResponse {
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message.dictionary, replyHandler: { @Sendable reply in
                guard let response = WorkoutTransferResponse(dictionary: reply) else {
                    continuation.resume(throwing: AppError.unknown(message: "Invalid response format from watch"))
                    return
                }
                continuation.resume(returning: response)
            }, errorHandler: { @Sendable error in
                // Handle the error asynchronously to avoid capturing self
                continuation.resume(throwing: error)
            })
        }
    }

    private func validateWorkoutPlan(_ plan: PlannedWorkoutData) throws {
        // Validate basic structure
        guard !plan.name.isEmpty else {
            throw AppError.invalidInput(message: "Workout plan must have a name")
        }

        guard !plan.plannedExercises.isEmpty else {
            throw AppError.invalidInput(message: "Workout plan must contain at least one exercise")
        }

        guard plan.estimatedDuration > 0 else {
            throw AppError.invalidInput(message: "Workout plan must have positive duration")
        }

        // Validate exercises
        for exercise in plan.plannedExercises {
            guard !exercise.name.isEmpty else {
                throw AppError.invalidInput(message: "All exercises must have names")
            }

            guard exercise.sets > 0 else {
                throw AppError.invalidInput(message: "All exercises must have at least one set")
            }

            guard exercise.targetReps > 0 else {
                throw AppError.invalidInput(message: "All exercises must have positive target reps")
            }

            guard exercise.restSeconds >= 0 else {
                throw AppError.invalidInput(message: "Rest seconds cannot be negative")
            }
        }

        AppLogger.info("Workout plan validation passed: \(plan.name)", category: .services)
    }

    // MARK: - Session Monitoring

    func handleSessionActivation(activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            AppLogger.error("WCSession activation failed", error: error, category: .services)
        } else {
            AppLogger.info("WCSession activated with state: \(activationState.rawValue)", category: .services)

            // Retry pending transfers when session becomes active
            if activationState == .activated {
                Task {
                    try? await retryPendingTransfers()
                }
            }
        }
    }

    func handleSessionReachabilityChange(isReachable: Bool) {
        AppLogger.info("Watch reachability changed: \(isReachable)", category: .services)

        // Retry pending transfers when watch becomes reachable
        if isReachable {
            Task {
                try? await retryPendingTransfers()
            }
        }
    }
}

// MARK: - WCSessionDelegate Handler

/// Separate delegate handler to manage WCSession callbacks
/// Required because WCSessionDelegate must inherit from NSObject
final class WorkoutPlanTransferDelegateHandler: NSObject, WCSessionDelegate {
    private weak var service: WorkoutPlanTransferService?

    func configure(with service: WorkoutPlanTransferService) {
        self.service = service
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Extract only Sendable data before crossing isolation boundary
        let activationStateValue = activationState
        let errorToPass = error
        
        Task { @MainActor [weak service] in
            await service?.handleSessionActivation(activationState: activationStateValue, error: errorToPass)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        // Extract only Sendable data before crossing isolation boundary
        let isReachable = session.isReachable
        
        Task { @MainActor [weak service] in
            await service?.handleSessionReachabilityChange(isReachable: isReachable)
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        AppLogger.info("WCSession became inactive", category: .services)
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        AppLogger.info("WCSession deactivated - reactivating", category: .services)
        session.activate()
    }
    #endif
}

// MARK: - Error Handling Extensions

extension AppError {
    static func workoutPlanTransferFailed(_ message: String) -> AppError {
        .unknown(message: "Workout plan transfer failed: \(message)")
    }
}
