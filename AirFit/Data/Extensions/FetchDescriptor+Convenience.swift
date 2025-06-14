import SwiftData
import Foundation

// MARK: - FetchDescriptor Convenience Extensions
extension FetchDescriptor where T == User {
    static var activeUser: FetchDescriptor<User> {
        var descriptor = FetchDescriptor<User>()
        descriptor.fetchLimit = 1
        descriptor.sortBy = [SortDescriptor(\.lastActiveAt, order: .reverse)]
        return descriptor
    }
}

extension FetchDescriptor where T == DailyLog {
    static func forDate(_ date: Date) -> FetchDescriptor<DailyLog> {
        let startOfDay = Calendar.current.startOfDay(for: date)
        var descriptor = FetchDescriptor<DailyLog>()
        descriptor.predicate = #Predicate { log in
            log.date == startOfDay
        }
        descriptor.fetchLimit = 1
        return descriptor
    }

    static func dateRange(from start: Date, to end: Date) -> FetchDescriptor<DailyLog> {
        var descriptor = FetchDescriptor<DailyLog>()
        descriptor.predicate = #Predicate { log in
            log.date >= start && log.date <= end
        }
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        return descriptor
    }
}

extension FetchDescriptor where T == FoodEntry {
    static func forMealType(_ mealType: MealType, on date: Date) -> FetchDescriptor<FoodEntry> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<FoodEntry>()
        descriptor.predicate = #Predicate { entry in
            entry.mealType == mealType.rawValue &&
                entry.loggedAt >= startOfDay &&
                entry.loggedAt < endOfDay
        }
        descriptor.sortBy = [SortDescriptor(\.loggedAt)]
        return descriptor
    }

    static func recentEntries(days: Int = 7) -> FetchDescriptor<FoodEntry> {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        var descriptor = FetchDescriptor<FoodEntry>()
        descriptor.predicate = #Predicate { entry in
            entry.loggedAt > cutoffDate
        }
        descriptor.sortBy = [SortDescriptor(\.loggedAt, order: .reverse)]
        return descriptor
    }
}

extension FetchDescriptor where T == Workout {
    static func upcoming(limit: Int = 10) -> FetchDescriptor<Workout> {
        var descriptor = FetchDescriptor<Workout>()
        descriptor.predicate = #Predicate { workout in
            workout.completedDate == nil && workout.plannedDate != nil
        }
        descriptor.sortBy = [SortDescriptor(\.plannedDate)]
        descriptor.fetchLimit = limit
        return descriptor
    }

    static func completed(days: Int = 30) -> FetchDescriptor<Workout> {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        var descriptor = FetchDescriptor<Workout>()
        descriptor.predicate = #Predicate { workout in
            workout.completedDate != nil && workout.completedDate! > cutoffDate
        }
        descriptor.sortBy = [SortDescriptor(\.completedDate, order: .reverse)]
        return descriptor
    }
}

// Template extensions removed - AI-native generation

extension FetchDescriptor where T == ChatSession {
    static var activeChats: FetchDescriptor<ChatSession> {
        var descriptor = FetchDescriptor<ChatSession>()
        descriptor.predicate = #Predicate { session in
            session.isActive == true
        }
        descriptor.sortBy = [SortDescriptor(\.lastMessageDate, order: .reverse)]
        return descriptor
    }

    static var archivedChats: FetchDescriptor<ChatSession> {
        var descriptor = FetchDescriptor<ChatSession>()
        descriptor.predicate = #Predicate { session in
            session.isActive == false
        }
        descriptor.sortBy = [SortDescriptor(\.archivedAt, order: .reverse)]
        return descriptor
    }
}
