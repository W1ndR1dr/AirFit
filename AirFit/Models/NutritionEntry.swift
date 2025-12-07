import Foundation
import SwiftData

@Model
final class NutritionEntry {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var confidence: String
    var timestamp: Date
    var componentsData: Data?  // JSON-encoded components

    init(
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        confidence: String = "medium",
        timestamp: Date = Date(),
        components: [NutritionComponent] = []
    ) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.confidence = confidence
        self.timestamp = timestamp
        self.componentsData = try? JSONEncoder().encode(components)
    }

    var components: [NutritionComponent] {
        guard let data = componentsData else { return [] }
        return (try? JSONDecoder().decode([NutritionComponent].self, from: data)) ?? []
    }
}

struct NutritionComponent: Codable, Identifiable {
    var id: String { name }
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

extension NutritionEntry {
    static var today: Predicate<NutritionEntry> {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return #Predicate { $0.timestamp >= startOfDay }
    }

    /// Query all entries from the last 90 days for history views
    static var recentHistory: Predicate<NutritionEntry> {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        return #Predicate { $0.timestamp >= cutoff }
    }
}

// MARK: - Date Helpers

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Daily Summary for aggregation

struct DailySummary: Identifiable {
    let date: Date
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let entryCount: Int

    var id: Date { date }

    init(date: Date, entries: [NutritionEntry]) {
        self.date = date
        self.calories = entries.reduce(0) { $0 + $1.calories }
        self.protein = entries.reduce(0) { $0 + $1.protein }
        self.carbs = entries.reduce(0) { $0 + $1.carbs }
        self.fat = entries.reduce(0) { $0 + $1.fat }
        self.entryCount = entries.count
    }
}
