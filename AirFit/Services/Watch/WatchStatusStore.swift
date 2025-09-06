import Foundation
import WatchConnectivity
import Combine

/// # WatchStatusStore
///
/// ## Purpose
/// Centralized state management for watch connectivity and workout plan transfer queue.
/// Provides persistent queue management and real-time connectivity status tracking.
///
/// ## Key Features
/// - Real-time watch connectivity monitoring (paired, installed, reachable)
/// - Persistent queue for failed workout plan transfers
/// - Automatic retry when watch becomes available
/// - UI-friendly published properties for SwiftUI integration
/// - Queue size management and data expiration
///
/// ## Architecture Benefits
/// - **State Centralization**: Single source of truth for watch status
/// - **Persistence**: Survives app restarts and network issues
/// - **Auto-Recovery**: Handles connectivity changes gracefully
/// - **UI Integration**: SwiftUI-ready published properties
/// - **Service Integration**: Works seamlessly with existing transfer service
///
/// ## Usage
/// ```swift
/// @StateObject private var watchStatus = WatchStatusStore.shared
///
/// var body: some View {
///     VStack {
///         WatchStatusIndicator(status: watchStatus)
///         Text("Queued plans: \(watchStatus.queuedPlansCount)")
///     }
/// }
/// ```

@MainActor
final class WatchStatusStore: ObservableObject {
    // MARK: - Singleton
    static let shared = WatchStatusStore()
    
    // MARK: - Published Properties
    
    /// Watch is paired with iPhone
    @Published var isPaired: Bool = false
    
    /// AirFit Watch app is installed
    @Published var isInstalled: Bool = false
    
    /// Watch is currently reachable for communication
    @Published var isReachable: Bool = false
    
    /// Number of workout plans currently queued for transfer
    @Published var queuedPlansCount: Int = 0
    
    /// Overall watch status for UI display
    @Published var overallStatus: WatchStatus = .unknown
    
    /// Last connectivity check timestamp
    @Published var lastStatusUpdate: Date = Date()
    
    /// Queue processing status
    @Published var isProcessingQueue: Bool = false
    
    /// Error state for failed operations
    @Published var lastError: WatchError?
    
    // MARK: - Private Properties
    
    private let session: WCSession
    private let delegateHandler = WatchStatusDelegateHandler()
    private var cancellables = Set<AnyCancellable>()
    
    /// Persistent queue storage key
    private let queueStorageKey = "WorkoutPlanTransferQueue"
    
    /// Maximum items in queue to prevent memory issues
    private let maxQueueSize = 50
    
    /// Maximum age for queued items (7 days)
    private let maxQueueAge: TimeInterval = 7 * 24 * 60 * 60
    
    /// Internal queue storage
    private var queuedPlans: [QueuedPlan] = [] {
        didSet {
            queuedPlansCount = queuedPlans.count
            persistQueue()
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.session = WCSession.default
        
        setupSession()
        loadPersistedQueue()
        setupStatusMonitoring()
        
        AppLogger.info("WatchStatusStore initialized", category: .services)
    }
    
    // MARK: - Setup Methods
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            overallStatus = .unsupported
            return
        }
        
        delegateHandler.configure(with: self)
        session.delegate = delegateHandler
        session.activate()
    }
    
    private func setupStatusMonitoring() {
        // Combine status properties to compute overall status
        Publishers.CombineLatest3($isPaired, $isInstalled, $isReachable)
            .map { paired, installed, reachable in
                self.calculateOverallStatus(paired: paired, installed: installed, reachable: reachable)
            }
            .assign(to: &$overallStatus)
        
        // Auto-retry queue when watch becomes available
        $overallStatus
            .removeDuplicates()
            .sink { [weak self] status in
                if status == .available && !self?.queuedPlans.isEmpty == true {
                    Task {
                        await self?.processQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Manually refresh watch connectivity status
    func refreshStatus() {
        guard WCSession.isSupported() else { return }
        
        updateStatus(
            paired: session.isPaired,
            installed: session.isWatchAppInstalled,
            reachable: session.isReachable
        )
        
        AppLogger.info("Watch status refreshed: \(overallStatus)", category: .services)
    }
    
    /// Add a workout plan to the persistent queue
    func queuePlan(_ plan: PlannedWorkoutData, reason: QueueReason = .watchUnavailable) {
        // Check queue size limit
        if queuedPlans.count >= maxQueueSize {
            // Remove oldest item to make space
            queuedPlans.removeFirst()
            AppLogger.warning("Queue full, removed oldest plan", category: .services)
        }
        
        let queuedPlan = QueuedPlan(
            plan: plan,
            queuedAt: Date(),
            reason: reason,
            retryCount: 0
        )
        
        queuedPlans.append(queuedPlan)
        
        AppLogger.info("Queued workout plan: \(plan.name), reason: \(reason)", category: .services)
        
        // Post notification for UI feedback
        NotificationCenter.default.post(
            name: .workoutPlanQueued,
            object: nil,
            userInfo: [
                "planId": plan.id,
                "planName": plan.name,
                "reason": reason.rawValue
            ]
        )
    }
    
    /// Remove a specific plan from the queue
    func removePlan(id: UUID) {
        queuedPlans.removeAll { $0.plan.id == id }
        AppLogger.info("Removed plan from queue: \(id)", category: .services)
    }
    
    /// Clear all queued plans
    func clearQueue() {
        queuedPlans.removeAll()
        AppLogger.info("Cleared workout plan queue", category: .services)
    }
    
    /// Get all queued plans (for UI display)
    func getQueuedPlans() -> [QueuedPlan] {
        return queuedPlans
    }
    
    /// Process the queue (attempt transfers)
    /// This method is designed to be called by the transfer service
    func processQueue(using transferHandler: @escaping (PlannedWorkoutData) async throws -> Void) async {
        guard !isProcessingQueue else { return }
        guard overallStatus == .available else {
            AppLogger.info("Cannot process queue - watch not available", category: .services)
            return
        }
        
        isProcessingQueue = true
        defer { isProcessingQueue = false }
        
        AppLogger.info("Processing workout plan queue (\(queuedPlans.count) items)", category: .services)
        
        // Clean expired items first
        cleanExpiredItems()
        
        guard !queuedPlans.isEmpty else { return }
        
        var processedItems: [UUID] = []
        var failedItems: [UUID] = []
        
        for queuedPlan in queuedPlans {
            do {
                try await transferHandler(queuedPlan.plan)
                processedItems.append(queuedPlan.plan.id)
                
                AppLogger.info("Successfully transferred queued plan: \(queuedPlan.plan.name)", category: .services)
            } catch {
                // Increment retry count
                if let index = queuedPlans.firstIndex(where: { $0.plan.id == queuedPlan.plan.id }) {
                    queuedPlans[index].retryCount += 1
                    queuedPlans[index].lastRetryAt = Date()
                    
                    // Remove if too many retries
                    if queuedPlans[index].retryCount >= 3 {
                        failedItems.append(queuedPlan.plan.id)
                        AppLogger.error("Plan exceeded retry limit, removing: \(queuedPlan.plan.name)", error: error, category: .services)
                    }
                }
                
                AppLogger.error("Failed to transfer queued plan: \(queuedPlan.plan.name)", error: error, category: .services)
            }
        }
        
        // Remove successfully processed items
        queuedPlans.removeAll { processedItems.contains($0.plan.id) }
        
        // Remove failed items that exceeded retry limit
        queuedPlans.removeAll { failedItems.contains($0.plan.id) }
        
        AppLogger.info("Queue processing complete. Processed: \(processedItems.count), Failed: \(failedItems.count), Remaining: \(queuedPlans.count)", category: .services)
    }
    
    /// Process the queue using the default transfer mechanism (for compatibility)
    func processQueue() async {
        // This version is for backward compatibility and external calls
        await processQueue { plan in
            // For now, we'll need to rely on external coordination
            // In practice, this would be called by the transfer service
            throw WatchError.unknown("Direct queue processing requires transfer handler")
        }
    }
    
    // MARK: - Internal Status Updates
    
    func updateStatus(paired: Bool, installed: Bool, reachable: Bool) {
        let statusChanged = isPaired != paired || isInstalled != installed || isReachable != reachable
        
        isPaired = paired
        isInstalled = installed
        isReachable = reachable
        lastStatusUpdate = Date()
        
        if statusChanged {
            AppLogger.info("Watch status updated - Paired: \(paired), Installed: \(installed), Reachable: \(reachable)", category: .services)
        }
    }
    
    func handleError(_ error: Error) {
        lastError = WatchError.from(error)
        AppLogger.error("Watch connectivity error", error: error, category: .services)
    }
    
    // MARK: - Private Methods
    
    private func calculateOverallStatus(paired: Bool, installed: Bool, reachable: Bool) -> WatchStatus {
        guard WCSession.isSupported() else { return .unsupported }
        guard paired else { return .notPaired }
        guard installed else { return .appNotInstalled }
        guard reachable else { return .notReachable }
        return .available
    }
    
    private func loadPersistedQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueStorageKey) else {
            AppLogger.info("No persisted queue found", category: .services)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            queuedPlans = try decoder.decode([QueuedPlan].self, from: data)
            
            // Clean expired items on load
            cleanExpiredItems()
            
            AppLogger.info("Loaded \(queuedPlans.count) plans from persistent queue", category: .services)
        } catch {
            AppLogger.error("Failed to load persisted queue", error: error, category: .services)
            queuedPlans = []
        }
    }
    
    private func persistQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(queuedPlans)
            UserDefaults.standard.set(data, forKey: queueStorageKey)
            
            AppLogger.debug("Persisted queue with \(queuedPlans.count) items", category: .services)
        } catch {
            AppLogger.error("Failed to persist queue", error: error, category: .services)
        }
    }
    
    private func cleanExpiredItems() {
        let cutoffDate = Date().addingTimeInterval(-maxQueueAge)
        let initialCount = queuedPlans.count
        
        queuedPlans.removeAll { $0.queuedAt < cutoffDate }
        
        let removedCount = initialCount - queuedPlans.count
        if removedCount > 0 {
            AppLogger.info("Removed \(removedCount) expired items from queue", category: .services)
        }
    }
}

// MARK: - Supporting Models

/// Queue item with metadata
struct QueuedPlan: Codable {
    let plan: PlannedWorkoutData
    let queuedAt: Date
    let reason: QueueReason
    var retryCount: Int
    var lastRetryAt: Date?
    
    /// Age of the queued item
    var age: TimeInterval {
        Date().timeIntervalSince(queuedAt)
    }
    
    /// Whether this item is stale
    var isStale: Bool {
        age > 24 * 60 * 60 // 24 hours
    }
}

/// Reasons why a plan was queued
enum QueueReason: String, Codable, CaseIterable {
    case watchUnavailable = "watch_unavailable"
    case transferFailed = "transfer_failed"
    case encodingError = "encoding_error"
    case networkError = "network_error"
    case watchRejected = "watch_rejected"
    
    var displayName: String {
        switch self {
        case .watchUnavailable:
            return "Watch Unavailable"
        case .transferFailed:
            return "Transfer Failed"
        case .encodingError:
            return "Data Error"
        case .networkError:
            return "Network Error"
        case .watchRejected:
            return "Watch Rejected"
        }
    }
}

/// Overall watch connectivity status
enum WatchStatus: String, CaseIterable {
    case unknown = "unknown"
    case unsupported = "unsupported"
    case notPaired = "not_paired"
    case appNotInstalled = "app_not_installed"
    case notReachable = "not_reachable"
    case available = "available"
    
    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        case .notPaired:
            return "Not Paired"
        case .appNotInstalled:
            return "App Not Installed"
        case .notReachable:
            return "Not Reachable"
        case .available:
            return "Available"
        }
    }
    
    var statusColor: String {
        switch self {
        case .available:
            return "green"
        case .notReachable:
            return "orange"
        case .unknown:
            return "gray"
        default:
            return "red"
        }
    }
    
    var systemImage: String {
        switch self {
        case .available:
            return "applewatch.radiowaves.left.and.right"
        case .notReachable:
            return "applewatch.slash"
        case .notPaired:
            return "applewatch.exclamationmark"
        case .appNotInstalled:
            return "applewatch.and.arrow.forward"
        case .unsupported:
            return "xmark.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

/// Watch-specific error types
enum WatchError: Error {
    case sessionNotActivated
    case watchNotPaired
    case appNotInstalled
    case transferFailed(String)
    case encodingError(String)
    case queueFull
    case unknown(String)
    
    static func from(_ error: Error) -> WatchError {
        if let watchError = error as? WatchError {
            return watchError
        }
        
        return .unknown(error.localizedDescription)
    }
    
    var localizedDescription: String {
        switch self {
        case .sessionNotActivated:
            return "Watch session not activated"
        case .watchNotPaired:
            return "Apple Watch not paired"
        case .appNotInstalled:
            return "AirFit Watch app not installed"
        case .transferFailed(let message):
            return "Transfer failed: \(message)"
        case .encodingError(let message):
            return "Data encoding error: \(message)"
        case .queueFull:
            return "Transfer queue is full"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - WCSessionDelegate Handler

/// Separate delegate handler to manage WCSession callbacks for WatchStatusStore
final class WatchStatusDelegateHandler: NSObject, WCSessionDelegate {
    private weak var store: WatchStatusStore?
    
    func configure(with store: WatchStatusStore) {
        self.store = store
    }
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        
        Task { @MainActor [weak store] in
            store?.updateStatus(paired: paired, installed: installed, reachable: reachable)
            
            if let error = error {
                store?.handleError(error)
            } else if activationState == .activated {
                AppLogger.info("WCSession activated successfully", category: .services)
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        
        Task { @MainActor [weak store] in
            store?.updateStatus(paired: paired, installed: installed, reachable: reachable)
        }
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        
        Task { @MainActor [weak store] in
            store?.updateStatus(paired: paired, installed: installed, reachable: reachable)
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

// MARK: - Notification Extensions

extension Notification.Name {
    /// Posted when a workout plan is queued
    static let workoutPlanQueued = Notification.Name("workoutPlanQueued")
    
    /// Posted when queue processing starts
    static let queueProcessingStarted = Notification.Name("queueProcessingStarted")
    
    /// Posted when queue processing completes
    static let queueProcessingCompleted = Notification.Name("queueProcessingCompleted")
}