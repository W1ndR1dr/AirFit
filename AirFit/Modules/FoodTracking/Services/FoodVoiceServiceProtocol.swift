import Foundation
import SwiftData

/// Abstraction for food-specific voice operations.
@MainActor
protocol FoodVoiceServiceProtocol: Sendable {
    /// Indicates whether recording is currently active.
    var isRecording: Bool { get }
    /// Indicates whether streaming transcription is active.
    var isTranscribing: Bool { get }
    /// Last fully transcribed text.
    var transcribedText: String { get }
    /// Waveform samples for UI visualization.
    var voiceWaveform: [Float] { get }

    /// Request microphone permission.
    func requestPermission() async throws -> Bool
    /// Start voice recording.
    func startRecording() async throws
    /// Stop voice recording and return processed transcription.
    func stopRecording() async -> String?

    /// Callback when a food transcription is available.
    var onFoodTranscription: ((String) -> Void)? { get set }
    /// Error callback.
    var onError: ((Error) -> Void)? { get set }
}

/// Errors that can occur in `FoodVoiceAdapter` operations.
enum FoodVoiceError: LocalizedError {
    case voiceInputManagerUnavailable
    case transcriptionFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .voiceInputManagerUnavailable:
            return "Voice input manager from Module 13 is not available"
        case .transcriptionFailed:
            return "Failed to transcribe voice input"
        case .permissionDenied:
            return "Microphone permission was denied"
        }
    }
}

// MARK: - Nutrition Service Protocol
protocol NutritionServiceProtocol: Sendable {
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry]
    func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary
    func getWaterIntake(for user: User, date: Date) async throws -> Double
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem]
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry]
}

// MARK: - Food Database Service Protocol
protocol FoodDatabaseServiceProtocol: Sendable {
    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem?
    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem?
    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem]
}

// MARK: - Supporting Types
struct FoodDatabaseItem: Identifiable, Sendable {
    let id: String
    let name: String
    let brand: String?
    let defaultQuantity: Double
    let defaultUnit: String
    let servingUnit: String
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct NutritionContext: Sendable {
    let userPreferences: NutritionPreferences?
    let recentMeals: [FoodItem]
    let timeOfDay: Date
}

// MARK: - Food Voice Error
