import Foundation
import SwiftData

@Model
final class WaterEntry {
    var id: UUID
    var amount: Int  // ounces
    var timestamp: Date

    init(amount: Int, timestamp: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}

extension WaterEntry {
    static var today: Predicate<WaterEntry> {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return #Predicate { $0.timestamp >= startOfDay }
    }

    static var recentHistory: Predicate<WaterEntry> {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return #Predicate { $0.timestamp >= cutoff }
    }
}
