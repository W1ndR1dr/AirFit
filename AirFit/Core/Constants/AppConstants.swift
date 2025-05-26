import Foundation
import SwiftUI

enum AppConstants {
    // MARK: - App Info
    static let appName = "AirFit"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Layout
    enum Layout {
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let defaultCornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
        static let defaultSpacing: CGFloat = 12
    }

    // MARK: - Animation
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let shortDuration: Double = 0.2
        static let longDuration: Double = 0.5
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }

    // MARK: - Networking
    enum API {
        static let timeoutInterval: TimeInterval = 30
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 2
    }

    // MARK: - Storage
    enum Storage {
        static let userDefaultsSuiteName = "group.com.airfit.app"
        static let keychainServiceName = "com.airfit.app"
        static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: - Health
    enum Health {
        static let maxDaysToSync = 30
        static let updateInterval: TimeInterval = 3600 // 1 hour
    }

    // MARK: - Validation
    enum Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 128
        static let minAge = 13
        static let maxAge = 120
        static let minWeight: Double = 20 // kg
        static let maxWeight: Double = 300 // kg
        static let minHeight: Double = 50 // cm
        static let maxHeight: Double = 300 // cm
    }
}
