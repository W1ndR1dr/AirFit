import SwiftUI
import WatchConnectivity

@main
struct AirFitWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            MainWatchView()
                .environmentObject(connectivityManager)
        }
    }
}
