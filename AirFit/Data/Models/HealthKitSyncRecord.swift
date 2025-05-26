import SwiftData
import Foundation

@Model
final class HealthKitSyncRecord: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var dataType: String // HKQuantityType identifier
    var lastSyncDate: Date
    var syncDirection: String // "read", "write", "both"
    var recordCount: Int
    var success: Bool
    var errorMessage: String?

    // MARK: - Relationships
    var user: User?

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        dataType: String,
        syncDirection: SyncDirection,
        user: User? = nil
    ) {
        self.id = id
        self.dataType = dataType
        self.lastSyncDate = Date()
        self.syncDirection = syncDirection.rawValue
        self.recordCount = 0
        self.success = true
        self.user = user
    }

    // MARK: - Methods
    func recordSync(count: Int, success: Bool, error: String? = nil) {
        self.lastSyncDate = Date()
        self.recordCount = count
        self.success = success
        self.errorMessage = error
    }
}

enum SyncDirection: String, Sendable {
    case read
    case write
    case both
}
