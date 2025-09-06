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
    
    /// Integration with centralized watch status management
    private let watchStatusStore = WatchStatusStore.shared
    
    /// Transfer attempt tracking
    private var transferAttempts: [UUID: Int] = [:]
    private let maxDirectRetries = 3

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
            // Use centralized queue management
            watchStatusStore.queuePlan(plan, reason: .watchUnavailable)
            AppLogger.warning("Watch not reachable, queuing workout plan in WatchStatusStore: \(plan.name)", category: .services)

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
                // Determine appropriate queue reason based on error type
                let queueReason: QueueReason
                if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                    queueReason = .networkError
                } else if error.localizedDescription.contains("rejected") {
                    queueReason = .watchRejected
                } else {
                    queueReason = .transferFailed
                }
                
                // Use centralized queue management
                watchStatusStore.queuePlan(plan, reason: queueReason)
                AppLogger.error("Failed to send workout plan to watch, queued for retry", error: error, category: .services)
                
                // Post failure notification
                NotificationCenter.default.post(
                    name: .workoutPlanTransferFailed,
                    object: nil,
                    userInfo: [
                        "planId": plan.id,
                        "error": error.localizedDescription,
                        "queued": true,
                        "queueReason": queueReason.rawValue
                    ]
                )
                
                throw error
            }

        } catch {
            // Use centralized queue management for encoding errors
            watchStatusStore.queuePlan(plan, reason: .encodingError)
            AppLogger.error("Failed to encode workout plan, queued for retry", error: error, category: .services)
            throw AppError.unknown(message: "Failed to transfer workout plan: \(error.localizedDescription)")
        }
    }

    func isWatchAvailable() async -> Bool {
        return session.activationState == .activated &&
            session.isReachable &&
            session.isWatchAppInstalled
    }

    func getPendingPlans() async -> [PlannedWorkoutData] {
        // Combine local pending plans with centralized queue
        let centralizedPlans = watchStatusStore.getQueuedPlans().map(\.plan)
        return pendingPlans + centralizedPlans
    }

    func retryPendingTransfers() async throws {
        guard await isWatchAvailable() else {
            AppLogger.warning("Cannot retry transfers - watch not available", category: .services)
            return
        }

        // Process both local pending plans and centralized queue
        let localPendingCount = pendingPlans.count
        let centralizedQueueCount = watchStatusStore.queuedPlansCount

        guard localPendingCount > 0 || centralizedQueueCount > 0 else {
            AppLogger.info("No pending workout plans to retry", category: .services)
            return
        }

        AppLogger.info("Retrying \(localPendingCount) local + \(centralizedQueueCount) centralized workout plan transfers", category: .services)

        // Process local pending plans first (legacy support)
        if !pendingPlans.isEmpty {
            let plansToRetry = pendingPlans
            pendingPlans.removeAll()
            
            for plan in plansToRetry {
                do {
                    try await sendWorkoutPlan(plan)
                } catch {
                    // Failed plans will be automatically queued by sendWorkoutPlan
                    AppLogger.error("Failed to retry local pending workout plan: \(plan.name)", error: error, category: .services)
                }
            }
        }
        
        // Process centralized queue using enhanced retry logic
        await watchStatusStore.processQueueWithRetry { [weak self] plan in
            guard let self = self else { return }
            try await self.directTransfer(plan)
        }
    }
    
    /// Direct transfer without additional queueing (for centralized queue processing)
    private func directTransfer(_ plan: PlannedWorkoutData) async throws {
        AppLogger.info("Direct transfer attempt for: \(plan.name)", category: .services)
        
        // Validate plan before sending
        try validateWorkoutPlan(plan)
        
        guard session.activationState == .activated else {
            throw AppError.unknown(message: "WatchConnectivity session not activated")
        }
        
        guard session.isWatchAppInstalled else {
            throw AppError.unknown(message: "AirFit Watch app not installed")
        }
        
        guard session.isReachable else {
            throw AppError.unknown(message: "Watch not reachable")
        }
        
        // Encode and send
        let planData = try encoder.encode(plan)
        let transferMessage = WorkoutTransferMessage(
            planData: planData,
            planId: plan.id,
            timestamp: Date()
        )
        
        let response = try await sendTransferMessage(transferMessage)
        
        guard response.success else {
            throw AppError.unknown(message: response.errorMessage ?? "Watch rejected workout plan")
        }
        
        AppLogger.info("Direct transfer successful for: \(plan.name)", category: .services)
    }

    func cancelPendingPlan(id: UUID) async {
        // Remove from both local and centralized storage
        pendingPlans.removeAll { $0.id == id }
        watchStatusStore.removePlan(id: id)
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
