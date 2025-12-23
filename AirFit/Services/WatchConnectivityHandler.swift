import Foundation
@preconcurrency import WatchConnectivity
import SwiftData

/// Sendable wrapper for WatchConnectivity dictionaries
private final class SendableResponse: @unchecked Sendable {
    let value: [String: Any]
    init(_ value: [String: Any]) { self.value = value }
}

/// iPhone-side handler for WatchConnectivity.
/// Receives voice logs from Watch, sends context updates.
final class WatchConnectivityHandler: NSObject, ObservableObject, @unchecked Sendable {
    @MainActor static let shared = WatchConnectivityHandler()

    // MARK: - Dependencies

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()
    private let readinessEngine = ReadinessEngine()

    // MARK: - State

    @MainActor @Published private(set) var isWatchReachable: Bool = false
    @MainActor @Published private(set) var lastHRRSessionData: Data?

    private var session: WCSession?
    @MainActor private weak var modelContext: ModelContext?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] WCSession not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    /// Configure with SwiftData context for nutrition logging
    @MainActor func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Push macro update to Watch
    func sendMacroUpdate(_ macros: MacroProgressData) {
        guard let session, session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(macros)
            session.sendMessage(
                ["type": "macroUpdate", "data": data],
                replyHandler: nil,
                errorHandler: { error in
                    print("[WatchConnectivity] Macro update failed: \(error)")
                }
            )
        } catch {
            print("[WatchConnectivity] Failed to encode macros: \(error)")
        }
    }

    /// Push readiness update to Watch
    func sendReadinessUpdate(_ readiness: ReadinessDataPayload) {
        guard let session, session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(readiness)
            session.sendMessage(
                ["type": "readinessUpdate", "data": data],
                replyHandler: nil,
                errorHandler: { error in
                    print("[WatchConnectivity] Readiness update failed: \(error)")
                }
            )
        } catch {
            print("[WatchConnectivity] Failed to encode readiness: \(error)")
        }
    }

    /// Push volume update to Watch
    func sendVolumeUpdate(_ volume: VolumeProgressData) {
        guard let session, session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(volume)
            session.sendMessage(
                ["type": "volumeUpdate", "data": data],
                replyHandler: nil,
                errorHandler: { error in
                    print("[WatchConnectivity] Volume update failed: \(error)")
                }
            )
        } catch {
            print("[WatchConnectivity] Failed to encode volume: \(error)")
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func handleContextRequest() async -> SendableResponse {
        var response: [String: Any] = [:]

        // Build macro progress
        if let context = modelContext {
            let macros = await buildMacroProgress(context: context)
            if let data = try? JSONEncoder().encode(macros) {
                response["macros"] = data
            }
        }

        // Build readiness data
        let readiness = await buildReadinessData()
        if let data = try? JSONEncoder().encode(readiness) {
            response["readiness"] = data
        }

        // Build volume progress (from API)
        let volume = await buildVolumeProgress()
        if let data = try? JSONEncoder().encode(volume) {
            response["volume"] = data
        }

        return SendableResponse(response)
    }

    @MainActor
    private func handleFoodLog(transcript: String) async -> SendableResponse {
        do {
            // Parse the food using the server's nutrition endpoint
            let parsed = try await apiClient.parseNutrition(transcript)

            // Add to SwiftData
            guard let context = modelContext else {
                return SendableResponse(["success": false, "message": "No database context"])
            }

            let entry = NutritionEntry(
                name: parsed.name ?? transcript,
                calories: parsed.calories ?? 0,
                protein: parsed.protein ?? 0,
                carbs: parsed.carbs ?? 0,
                fat: parsed.fat ?? 0,
                confidence: parsed.confidence ?? "low"
            )
            context.insert(entry)
            try context.save()

            // Push updated macros to Watch
            let macros = await buildMacroProgress(context: context)
            sendMacroUpdate(macros)

            return SendableResponse(["success": true, "message": "Logged: \(parsed.name ?? transcript)"])
        } catch {
            print("[WatchConnectivity] Food log parsing failed: \(error)")
            return SendableResponse(["success": false, "message": "Failed to parse: \(transcript)"])
        }
    }

    @MainActor
    private func handleHRRSession(data: Data) {
        // Store for AI context injection
        lastHRRSessionData = data

        // Could also decode and trigger insights generation
        // For now, just store it
    }

    // MARK: - Data Building

    @MainActor
    private func buildMacroProgress(context: ModelContext) async -> MacroProgressData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= today
            }
        )

        let entries = (try? context.fetch(descriptor)) ?? []

        let calories = entries.reduce(0) { $0 + $1.calories }
        let protein = entries.reduce(0) { $0 + $1.protein }
        let carbs = entries.reduce(0) { $0 + $1.carbs }
        let fat = entries.reduce(0) { $0 + $1.fat }

        // TODO: Get targets from profile/settings
        let isTrainingDay = calendar.isDateInWeekend(Date()) == false

        return MacroProgressData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            targetCalories: isTrainingDay ? 2600 : 2200,
            targetProtein: 175,
            targetCarbs: isTrainingDay ? 330 : 250,
            targetFat: 67,
            isTrainingDay: isTrainingDay,
            lastUpdated: Date()
        )
    }

    private func buildReadinessData() async -> ReadinessDataPayload {
        let assessment = await readinessEngine.getReadinessAssessment()

        return ReadinessDataPayload(
            category: assessment.category.rawValue,
            positiveCount: assessment.positiveCount,
            totalCount: assessment.totalCount,
            hrvDeviation: nil,  // Could extract from indicators
            sleepHours: nil,
            rhrDeviation: nil,
            isBaselineReady: assessment.isBaselineReady,
            lastUpdated: Date()
        )
    }

    private func buildVolumeProgress() async -> VolumeProgressData {
        do {
            let setTracker = try await apiClient.getSetTracker(days: 7)
            let muscleGroups = setTracker.muscle_groups.map { (name, data) in
                VolumeProgressData.MuscleGroupVolumeData(
                    name: name,
                    currentSets: data.current,
                    targetSets: data.max,  // Use max as target
                    status: data.status
                )
            }
            .sorted { $0.name < $1.name }  // Consistent ordering
            return VolumeProgressData(
                muscleGroups: muscleGroups,
                lastUpdated: Date()
            )
        } catch {
            print("[WatchConnectivity] Failed to fetch set tracker: \(error)")
            return VolumeProgressData(muscleGroups: [], lastUpdated: Date())
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityHandler: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = false
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = false
        }
        // Reactivate session on main thread
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = isReachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Capture values before entering task
        let messageType = message["type"] as? String
        let transcript = message["transcript"] as? String
        let hrrData = message["data"] as? Data

        // Mark handler as safe to use across isolation - Apple's WCSession API is thread-safe
        nonisolated(unsafe) let reply = replyHandler

        // Use MainActor Task to stay in the same isolation context as our handler methods
        // This avoids Sendable issues by not crossing actor boundaries with [String: Any]
        Task { @MainActor in
            guard let type = messageType else {
                reply([:])
                return
            }

            var response: [String: Any]

            switch type {
            case "contextRequest":
                response = await self.handleContextRequest().value

            case "foodLog":
                if let transcript {
                    response = await self.handleFoodLog(transcript: transcript).value
                } else {
                    response = ["success": false, "message": "No transcript"]
                }

            case "hrrSession":
                if let data = hrrData {
                    self.handleHRRSession(data: data)
                }
                response = ["success": true]

            default:
                response = [:]
            }

            // Reply from MainActor - WCSession handles the dispatch internally
            reply(response)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        // Capture values before entering task
        let messageType = message["type"] as? String
        let hrrData = message["data"] as? Data

        Task { @MainActor in
            guard let type = messageType else { return }

            if type == "hrrSession", let data = hrrData {
                self.handleHRRSession(data: data)
            }
        }
    }
}

// MARK: - Payload Types (for Watch communication)

struct MacroProgressData: Codable, Sendable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let targetCalories: Int
    let targetProtein: Int
    let targetCarbs: Int
    let targetFat: Int
    let isTrainingDay: Bool
    let lastUpdated: Date
}

struct ReadinessDataPayload: Codable, Sendable {
    let category: String
    let positiveCount: Int
    let totalCount: Int
    let hrvDeviation: Double?
    let sleepHours: Double?
    let rhrDeviation: Double?
    let isBaselineReady: Bool
    let lastUpdated: Date
}

struct VolumeProgressData: Codable, Sendable {
    let muscleGroups: [MuscleGroupVolumeData]
    let lastUpdated: Date

    struct MuscleGroupVolumeData: Codable, Sendable {
        let name: String
        let currentSets: Int
        let targetSets: Int
        let status: String
    }
}
