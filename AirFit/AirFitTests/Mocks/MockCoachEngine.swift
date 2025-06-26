import Foundation
import SwiftData
import UIKit
@testable import AirFit

@MainActor
final class MockCoachEngine: CoachEngineProtocol, FoodCoachEngineProtocol {
    // MARK: - Mock State
    private(set) var isProcessing = false
    private(set) var currentResponse = ""
    private(set) var error: Error?
    private(set) var activeConversationId: UUID?
    private(set) var streamingTokens: [String] = []
    private(set) var lastFunctionCall: String?

    // MARK: - Mock Behavior Configuration
    var shouldThrowError = false
    var errorToThrow: Error = CoachEngineError.aiServiceUnavailable
    var processMessageResponse = "Mock response"
    var regenerateLastMessageResponse = "Regenerated response"
    var suggestionsToReturn: [String] = ["Mock suggestion 1", "Mock suggestion 2"]
    var streamingDelay: TimeInterval = 0.1
    var shouldSimulateStreaming = false

    // MARK: - Call Recording
    private(set) var processMessageCalls: [(message: String, context: Any?)] = []
    private(set) var regenerateLastMessageCalls = 0
    private(set) var handleFunctionResultCalls: [(functionName: String, result: Any)] = []
    private(set) var generateSuggestionsCalls = 0
    private(set) var cancelStreamingCalls = 0
    private(set) var resetCalls = 0

    // MARK: - Initialization
    init() {
        self.activeConversationId = UUID()
    }

    // MARK: - Main Methods
    func processMessage(_ message: String, context: Any? = nil) async throws -> String {
        processMessageCalls.append((message, context))

        if shouldThrowError {
            throw errorToThrow
        }

        isProcessing = true
        currentResponse = ""

        if shouldSimulateStreaming {
            // Simulate streaming
            let words = processMessageResponse.split(separator: " ")
            for word in words {
                streamingTokens.append(String(word))
                currentResponse += String(word) + " "
                try? await Task.sleep(nanoseconds: UInt64(streamingDelay * 1_000_000_000))
            }
        } else {
            currentResponse = processMessageResponse
        }

        isProcessing = false
        return currentResponse.trimmingCharacters(in: .whitespaces)
    }

    func regenerateLastMessage() async throws -> String {
        regenerateLastMessageCalls += 1

        if shouldThrowError {
            throw errorToThrow
        }

        isProcessing = true
        currentResponse = regenerateLastMessageResponse
        isProcessing = false

        return regenerateLastMessageResponse
    }

    func handleFunctionResult(functionName: String, result: Any) async throws {
        handleFunctionResultCalls.append((functionName, result))

        if shouldThrowError {
            throw errorToThrow
        }

        lastFunctionCall = functionName
    }

    func generateSuggestions(for context: Any? = nil) async -> [String] {
        generateSuggestionsCalls += 1
        return suggestionsToReturn
    }

    func cancelStreaming() {
        cancelStreamingCalls += 1
        isProcessing = false
    }

    // MARK: - Utility Methods
    func reset() {
        resetCalls += 1
        isProcessing = false
        currentResponse = ""
        error = nil
        streamingTokens = []
        lastFunctionCall = nil

        // Clear call history
        processMessageCalls = []
        regenerateLastMessageCalls = 0
        handleFunctionResultCalls = []
        generateSuggestionsCalls = 0
        cancelStreamingCalls = 0
    }

    // MARK: - FoodCoachEngineProtocol Mock State
    var mockParsedItems: [ParsedFoodItem] = []
    var analyzeMealPhotoShouldSucceed = true
    var analyzeMealPhotoItemsToReturn: [ParsedFoodItem] = []
    var searchFoodsShouldSucceed = true
    var searchFoodsResultsToReturn: [ParsedFoodItem] = []
    var searchFoodsCalled = false
    var searchFoodsQuery: String?
    var executeFunctionShouldSucceed = true
    var executeFunctionDataToReturn: [String: SendableValue] = [:]

    // MARK: - Test Helpers
    func simulateError(_ error: Error) {
        self.error = error
    }

    func setActiveConversation(_ id: UUID) {
        self.activeConversationId = id
    }
}

// MARK: - FoodCoachEngineProtocol Implementation
extension MockCoachEngine {
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        processMessageCalls.append((message, context))

        if shouldThrowError {
            throw errorToThrow
        }

        return ["response": .string(processMessageResponse)]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        if !executeFunctionShouldSucceed {
            throw errorToThrow
        }

        return FunctionExecutionResult(
            success: true,
            message: "Mock function executed",
            data: executeFunctionDataToReturn,
            executionTimeMs: 100,
            functionName: functionCall.name
        )
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?, for user: User) async throws -> MealPhotoAnalysisResult {
        if !analyzeMealPhotoShouldSucceed {
            throw errorToThrow
        }

        return MealPhotoAnalysisResult(
            items: analyzeMealPhotoItemsToReturn,
            confidence: 0.85,
            processingTime: 0.5
        )
    }

    func searchFoods(query: String, limit: Int, for user: User) async throws -> [ParsedFoodItem] {
        searchFoodsCalled = true
        searchFoodsQuery = query

        if !searchFoodsShouldSucceed {
            throw errorToThrow
        }

        return searchFoodsResultsToReturn
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        if shouldThrowError {
            throw errorToThrow
        }

        // Return mockParsedItems if set, otherwise create default item
        if !mockParsedItems.isEmpty {
            return mockParsedItems
        }

        return [
            ParsedFoodItem(
                name: "Test Food",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 100,
                proteinGrams: 10,
                carbGrams: 20,
                fatGrams: 5,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                databaseId: nil,
                confidence: 0.9
            )
        ]
    }
}

// MARK: - Extension Methods (for testing specific functionality)
extension MockCoachEngine {
    // Notification-related methods
    func generateReEngagementMessage() async -> String {
        return "Time to get back on track!"
    }

    func generateMorningGreeting(for userName: String?) async -> String {
        return "Good morning\(userName.map { ", \($0)" } ?? "")!"
    }

    func generateWorkoutReminder(workoutType: String?, userName: String?) async -> String {
        return "Time for your \(workoutType ?? "workout")\(userName.map { ", \($0)" } ?? "")!"
    }

    func generateMealReminder(mealType: String, userName: String?) async -> String {
        return "Time for \(mealType)\(userName.map { ", \($0)" } ?? "")!"
    }

    // Food-related methods
    func analyzeMealPhoto(image: Data, context: HealthContextSnapshot?) async throws -> [ParsedFoodItem] {
        if shouldThrowError {
            throw errorToThrow
        }

        return [
            ParsedFoodItem(
                name: "Test Food",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 200,
                proteinGrams: 10,
                carbGrams: 20,
                fatGrams: 5,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                databaseId: nil,
                confidence: 0.9
            )
        ]
    }

    func searchFoods(query: String, limit: Int) async throws -> [FoodSearchResult] {
        if shouldThrowError {
            throw errorToThrow
        }

        return [
            FoodSearchResult(
                name: "Test Food",
                calories: 100,
                protein: 5,
                carbs: 10,
                fat: 2,
                servingSize: "1 cup"
            )
        ]
    }

    // MARK: - CoachEngineProtocol Methods
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        if shouldThrowError {
            throw errorToThrow
        }
        return "Great workout! You completed \(Int((request.workout.duration ?? 0) / 60)) minutes of exercise."
    }

    func processUserMessage(_ text: String, for user: User) async {
        processMessageCalls.append((text, nil))
        isProcessing = true
        currentResponse = processMessageResponse
        isProcessing = false
    }
}
