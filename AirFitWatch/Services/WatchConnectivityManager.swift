import Foundation
import WatchConnectivity
import Combine

/// Manages WatchConnectivity session for iPhone <-> Watch communication.
/// Handles bidirectional data sync for macros, readiness, volume, and voice logging.
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published State

    @Published private(set) var isPhoneReachable: Bool = false
    @Published private(set) var lastSyncDate: Date?

    // Cached data for complications and UI
    @Published var macroProgress: MacroProgress = .placeholder
    @Published var readinessData: ReadinessData = .placeholder
    @Published var volumeProgress: VolumeProgress = .placeholder
    @Published var hrrSessionData: HRRSessionData = .placeholder

    // Voice logging state
    @Published var pendingVoiceLogs: [String] = []
    @Published var lastVoiceLogResult: String?

    // MARK: - Private Properties

    private var session: WCSession?
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization

    private override init() {
        super.init()
        setupSession()
        loadCachedData()
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] WCSession not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Public API

    /// Request context update from iPhone
    func requestContextUpdate() {
        guard let session, session.isReachable else {
            print("[WatchConnectivity] Phone not reachable for context request")
            return
        }

        session.sendMessage(
            ["type": "contextRequest"],
            replyHandler: { [weak self] response in
                Task { @MainActor in
                    self?.processContextResponse(response)
                }
            },
            errorHandler: { error in
                print("[WatchConnectivity] Context request failed: \(error)")
            }
        )
    }

    /// Send voice-logged food to iPhone for processing
    func sendFoodLog(_ transcript: String) {
        guard let session else {
            pendingVoiceLogs.append(transcript)
            saveCache()
            return
        }

        if session.isReachable {
            session.sendMessage(
                ["type": "foodLog", "transcript": transcript],
                replyHandler: { [weak self] response in
                    Task { @MainActor in
                        if let success = response["success"] as? Bool, success {
                            self?.lastVoiceLogResult = response["message"] as? String ?? "Logged successfully"
                            // Request updated macros
                            self?.requestContextUpdate()
                        } else {
                            self?.lastVoiceLogResult = "Failed to log"
                        }
                    }
                },
                errorHandler: { [weak self] error in
                    print("[WatchConnectivity] Food log send failed: \(error)")
                    Task { @MainActor in
                        self?.pendingVoiceLogs.append(transcript)
                        self?.saveCache()
                    }
                }
            )
        } else {
            // Queue for later
            pendingVoiceLogs.append(transcript)
            saveCache()
        }
    }

    /// Send HRR session data to iPhone for AI context
    func sendHRRSessionData(_ data: HRRSessionData) {
        guard let session, session.isReachable else { return }

        do {
            let encoded = try JSONEncoder().encode(data)
            session.sendMessage(
                ["type": "hrrSession", "data": encoded],
                replyHandler: nil,
                errorHandler: { error in
                    print("[WatchConnectivity] HRR session send failed: \(error)")
                }
            )
        } catch {
            print("[WatchConnectivity] Failed to encode HRR data: \(error)")
        }
    }

    // MARK: - Private Methods

    private func processContextResponse(_ response: [String: Any]) {
        // Parse macro progress
        if let macroData = response["macros"] as? Data {
            if let macros = try? JSONDecoder().decode(MacroProgress.self, from: macroData) {
                self.macroProgress = macros
            }
        }

        // Parse readiness data
        if let readinessRaw = response["readiness"] as? Data {
            if let readiness = try? JSONDecoder().decode(ReadinessData.self, from: readinessRaw) {
                self.readinessData = readiness
            }
        }

        // Parse volume progress
        if let volumeData = response["volume"] as? Data {
            if let volume = try? JSONDecoder().decode(VolumeProgress.self, from: volumeData) {
                self.volumeProgress = volume
            }
        }

        lastSyncDate = Date()
        saveCache()
    }

    private func flushPendingVoiceLogs() {
        guard !pendingVoiceLogs.isEmpty else { return }

        let logsToSend = pendingVoiceLogs
        pendingVoiceLogs.removeAll()

        for log in logsToSend {
            sendFoodLog(log)
        }
    }

    // MARK: - Caching

    private func loadCachedData() {
        if let data = userDefaults.data(forKey: "cachedMacros"),
           let macros = try? JSONDecoder().decode(MacroProgress.self, from: data) {
            self.macroProgress = macros
        }

        if let data = userDefaults.data(forKey: "cachedReadiness"),
           let readiness = try? JSONDecoder().decode(ReadinessData.self, from: data) {
            self.readinessData = readiness
        }

        if let data = userDefaults.data(forKey: "cachedVolume"),
           let volume = try? JSONDecoder().decode(VolumeProgress.self, from: data) {
            self.volumeProgress = volume
        }

        if let pending = userDefaults.stringArray(forKey: "pendingVoiceLogs") {
            self.pendingVoiceLogs = pending
        }
    }

    private func saveCache() {
        if let data = try? JSONEncoder().encode(macroProgress) {
            userDefaults.set(data, forKey: "cachedMacros")
        }
        if let data = try? JSONEncoder().encode(readinessData) {
            userDefaults.set(data, forKey: "cachedReadiness")
        }
        if let data = try? JSONEncoder().encode(volumeProgress) {
            userDefaults.set(data, forKey: "cachedVolume")
        }
        userDefaults.set(pendingVoiceLogs, forKey: "pendingVoiceLogs")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            if session.isReachable {
                self.requestContextUpdate()
                self.flushPendingVoiceLogs()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            if session.isReachable {
                self.requestContextUpdate()
                self.flushPendingVoiceLogs()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            guard let type = message["type"] as? String else { return }

            switch type {
            case "macroUpdate":
                if let data = message["data"] as? Data,
                   let macros = try? JSONDecoder().decode(MacroProgress.self, from: data) {
                    self.macroProgress = macros
                    self.saveCache()
                }

            case "readinessUpdate":
                if let data = message["data"] as? Data,
                   let readiness = try? JSONDecoder().decode(ReadinessData.self, from: data) {
                    self.readinessData = readiness
                    self.saveCache()
                }

            case "volumeUpdate":
                if let data = message["data"] as? Data,
                   let volume = try? JSONDecoder().decode(VolumeProgress.self, from: data) {
                    self.volumeProgress = volume
                    self.saveCache()
                }

            default:
                print("[WatchConnectivity] Unknown message type: \(type)")
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            self.processContextResponse(applicationContext)
        }
    }
}
