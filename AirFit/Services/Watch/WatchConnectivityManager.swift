import Foundation
import UIKit
import WatchConnectivity

/// Manages Watch connectivity and installation status
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPaired: Bool = false
    @Published var isAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    @Published var isCheckingStatus: Bool = false
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func checkWatchStatus() {
        isCheckingStatus = true
        
        Task {
            // Small delay to show loading state
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                if let session = session {
                    self.isPaired = session.isPaired
                    self.isAppInstalled = session.isWatchAppInstalled
                    self.isReachable = session.isReachable
                }
                self.isCheckingStatus = false
            }
        }
    }
    
    func openWatchApp() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(AppConstants.appStoreId)?mt=8") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let isPaired = session.isPaired
        let isAppInstalled = session.isWatchAppInstalled
        let isReachable = session.isReachable
        
        Task { @MainActor in
            if activationState == .activated {
                self.isPaired = isPaired
                self.isAppInstalled = isAppInstalled
                self.isReachable = isReachable
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let isPaired = session.isPaired
        let isAppInstalled = session.isWatchAppInstalled
        let isReachable = session.isReachable
        
        Task { @MainActor in
            self.isPaired = isPaired
            self.isAppInstalled = isAppInstalled
            self.isReachable = isReachable
        }
    }
}