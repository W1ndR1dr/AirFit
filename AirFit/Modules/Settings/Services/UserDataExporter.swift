import Foundation
import SwiftData

/// Service for exporting user data
actor UserDataExporter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Export all user data as JSON
    func exportAllData(for user: User) async throws -> URL {
        let exportData = try await gatherUserData(for: user)
        let jsonData = try JSONEncoder.formatted.encode(exportData)
        
        // Create temporary file
        let fileName = "AirFit_Export_\(DateFormatter.fileNameFormatter.string(from: Date())).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: tempURL)
        
        AppLogger.info("Exported user data: \(ByteCountFormatter().string(fromByteCount: Int64(jsonData.count)))", category: .data)
        
        return tempURL
    }
    
    /// Export data in CSV format
    func exportAsCSV(for user: User, dataType: ExportDataType) async throws -> URL {
        let csvData = try await generateCSV(for: user, dataType: dataType)
        
        let fileName = "AirFit_\(dataType.rawValue)_\(DateFormatter.fileNameFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }
    
    // MARK: - Private Methods
    
    private func gatherUserData(for user: User) async throws -> UserDataExport {
        // Fetch all related data
        let workouts = try await fetchWorkouts(for: user)
        let foodEntries = try await fetchFoodEntries(for: user)
        let dailyLogs = try await fetchDailyLogs(for: user)
        let chatSessions = try await fetchChatSessions(for: user)
        
        return UserDataExport(
            exportDate: Date(),
            appVersion: AppConstants.appVersionString,
            user: UserExportData(from: user),
            workouts: workouts.map(WorkoutExportData.init),
            nutrition: foodEntries.map(FoodEntryExportData.init),
            dailyLogs: dailyLogs.map(DailyLogExportData.init),
            chatHistory: chatSessions.map(ChatSessionExportData.init),
            settings: UserSettingsExport(from: user)
        )
    }
    
    private func fetchWorkouts(for user: User) async throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.user?.id == user.id },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func fetchFoodEntries(for user: User) async throws -> [FoodEntry] {
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.user?.id == user.id },
            sortBy: [SortDescriptor(\.consumedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func fetchDailyLogs(for user: User) async throws -> [DailyLog] {
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.user?.id == user.id },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func fetchChatSessions(for user: User) async throws -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.user?.id == user.id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func generateCSV(for user: User, dataType: ExportDataType) async throws -> String {
        switch dataType {
        case .workouts:
            return try await generateWorkoutsCSV(for: user)
        case .nutrition:
            return try await generateNutritionCSV(for: user)
        case .progress:
            return try await generateProgressCSV(for: user)
        }
    }
    
    private func generateWorkoutsCSV(for user: User) async throws -> String {
        let workouts = try await fetchWorkouts(for: user)
        
        var csv = "Date,Type,Duration,Calories,Exercises,Notes\n"
        
        for workout in workouts {
            let date = DateFormatter.shortFormatter.string(from: workout.startTime)
            let duration = formatDuration(workout.duration)
            let exercises = workout.exercises.map { $0.name }.joined(separator: "; ")
            let notes = workout.notes ?? ""
            
            csv += "\(date),\(workout.type),\(duration),\(workout.totalCalories ?? 0),\"\(exercises)\",\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func generateNutritionCSV(for user: User) async throws -> String {
        let entries = try await fetchFoodEntries(for: user)
        
        var csv = "Date,Time,Food,Calories,Protein,Carbs,Fat,Notes\n"
        
        for entry in entries {
            let date = DateFormatter.shortFormatter.string(from: entry.consumedAt)
            let time = DateFormatter.timeFormatter.string(from: entry.consumedAt)
            let food = entry.name
            let calories = entry.nutritionData?.calories ?? 0
            let protein = entry.nutritionData?.protein ?? 0
            let carbs = entry.nutritionData?.carbs ?? 0
            let fat = entry.nutritionData?.fat ?? 0
            let notes = entry.notes ?? ""
            
            csv += "\(date),\(time),\"\(food)\",\(calories),\(protein),\(carbs),\(fat),\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func generateProgressCSV(for user: User) async throws -> String {
        let logs = try await fetchDailyLogs(for: user)
        
        var csv = "Date,Weight,Body Fat %,Sleep Hours,Steps,Calories In,Calories Out,Mood,Energy,Notes\n"
        
        for log in logs {
            let date = DateFormatter.shortFormatter.string(from: log.date)
            let weight = log.weight ?? 0
            let bodyFat = log.bodyFatPercentage ?? 0
            let sleep = log.sleepHours ?? 0
            let steps = log.steps ?? 0
            let caloriesIn = log.totalCaloriesConsumed ?? 0
            let caloriesOut = log.totalCaloriesBurned ?? 0
            let mood = log.mood ?? ""
            let energy = log.energyLevel ?? 0
            let notes = log.notes ?? ""
            
            csv += "\(date),\(weight),\(bodyFat),\(sleep),\(steps),\(caloriesIn),\(caloriesOut),\"\(mood)\",\(energy),\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3_600
        let minutes = (Int(seconds) % 3_600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Export Data Types
enum ExportDataType: String, CaseIterable {
    case workouts = "Workouts"
    case nutrition = "Nutrition"
    case progress = "Progress"
}

// MARK: - Export Models
struct UserDataExport: Codable {
    let exportDate: Date
    let appVersion: String
    let user: UserExportData
    let workouts: [WorkoutExportData]
    let nutrition: [FoodEntryExportData]
    let dailyLogs: [DailyLogExportData]
    let chatHistory: [ChatSessionExportData]
    let settings: UserSettingsExport
}

struct UserExportData: Codable {
    let id: UUID
    let name: String
    let email: String?
    let createdAt: Date
    let lastActiveAt: Date?
    
    init(from user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.createdAt = user.createdAt
        self.lastActiveAt = user.lastActiveAt
    }
}

struct WorkoutExportData: Codable {
    let id: UUID
    let type: String
    let startTime: Date
    let duration: TimeInterval
    let totalCalories: Int?
    let exercises: [ExerciseExportData]
    let notes: String?
    
    init(from workout: Workout) {
        self.id = workout.id
        self.type = workout.type
        self.startTime = workout.startTime
        self.duration = workout.duration
        self.totalCalories = workout.totalCalories
        self.exercises = workout.exercises.map(ExerciseExportData.init)
        self.notes = workout.notes
    }
}

struct ExerciseExportData: Codable {
    let name: String
    let sets: Int
    let reps: [Int]
    let weight: [Double]
    
    init(from exercise: Exercise) {
        self.name = exercise.name
        self.sets = exercise.sets.count
        self.reps = exercise.sets.map { $0.reps ?? 0 }
        self.weight = exercise.sets.map { $0.weight ?? 0 }
    }
}

struct FoodEntryExportData: Codable {
    let id: UUID
    let name: String
    let consumedAt: Date
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let notes: String?
    
    init(from entry: FoodEntry) {
        self.id = entry.id
        self.name = entry.name
        self.consumedAt = entry.consumedAt
        self.calories = entry.nutritionData?.calories
        self.protein = entry.nutritionData?.protein
        self.carbs = entry.nutritionData?.carbs
        self.fat = entry.nutritionData?.fat
        self.notes = entry.notes
    }
}

struct DailyLogExportData: Codable {
    let date: Date
    let weight: Double?
    let bodyFatPercentage: Double?
    let sleepHours: Double?
    let steps: Int?
    let mood: String?
    let energyLevel: Int?
    let notes: String?
    
    init(from log: DailyLog) {
        self.date = log.date
        self.weight = log.weight
        self.bodyFatPercentage = log.bodyFatPercentage
        self.sleepHours = log.sleepHours
        self.steps = log.steps
        self.mood = log.mood
        self.energyLevel = log.energyLevel
        self.notes = log.notes
    }
}

struct ChatSessionExportData: Codable {
    let id: UUID
    let createdAt: Date
    let messageCount: Int
    let title: String?
    
    init(from session: ChatSession) {
        self.id = session.id
        self.createdAt = session.createdAt
        self.messageCount = session.messages.count
        self.title = session.title
    }
}

struct UserSettingsExport: Codable {
    let preferredUnits: String
    let notificationsEnabled: Bool
    let selectedAIProvider: String?
    
    init(from user: User) {
        self.preferredUnits = user.preferredUnits
        self.notificationsEnabled = user.notificationPreferences?.systemEnabled ?? false
        self.selectedAIProvider = user.selectedAIProvider?.rawValue
    }
}

// MARK: - Formatters
private extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()
    
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private extension JSONEncoder {
    static let formatted: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
