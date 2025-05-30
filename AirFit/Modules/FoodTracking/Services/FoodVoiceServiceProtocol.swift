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
    /// Retrieves all `FoodEntry` objects for the specified date.
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry]

    /// Calculates a nutrition summary from a set of entries.
    nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary

    /// Returns the amount of water consumed on a given day in milliliters.
    func getWaterIntake(for user: User, date: Date) async throws -> Double

    /// Retrieves the most recent foods logged by the user.
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem]

    /// Logs water intake for a user at the specified date.
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws

    /// Returns the meal history for a particular meal type.
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry]

    /// Nutrition targets derived from the onboarding profile.
    func getTargets(from profile: OnboardingProfile?) -> NutritionTargets

    /// Convenience helper to generate today's summary.
    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary
}

// MARK: - Food Database Service Protocol
protocol FoodDatabaseServiceProtocol: Sendable {
    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem?
    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem?
    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem]
}

