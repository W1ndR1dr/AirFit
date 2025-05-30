import Foundation
@testable import AirFit

// MARK: - MockNutritionService
final class MockNutritionService: NutritionServiceProtocol {
    var shouldThrowError = false
    var mockFoodEntries: [FoodEntry] = []
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        if shouldThrowError {
            throw FoodTrackingError.saveFailed
        }
        mockFoodEntries.append(entry)
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        if shouldThrowError {
            throw FoodTrackingError.networkError
        }
        return mockFoodEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        if shouldThrowError {
            throw FoodTrackingError.saveFailed
        }
        mockFoodEntries.removeAll { $0.id == entry.id }
    }
}

// MARK: - MockCoachEngine
final class MockCoachEngine: CoachEngineProtocol {
    var shouldTimeout = false
    var mockResponse: [String: SendableValue] = [:]
    
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        if shouldTimeout {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        }
        
        return mockResponse.isEmpty ? [
            "foods": SendableValue.array([
                SendableValue.dictionary([
                    "name": SendableValue.string("Apple"),
                    "quantity": SendableValue.double(1.0),
                    "unit": SendableValue.string("medium"),
                    "calories": SendableValue.double(95.0),
                    "protein": SendableValue.double(0.5),
                    "carbs": SendableValue.double(25.0),
                    "fat": SendableValue.double(0.3),
                    "confidence": SendableValue.double(0.9)
                ])
            ])
        ] : mockResponse
    }
    
    func executeFunction(name: String, parameters: [String: SendableValue]) async throws -> [String: SendableValue] {
        return mockResponse.isEmpty ? [
            "success": SendableValue.bool(true),
            "result": SendableValue.string("Function executed successfully")
        ] : mockResponse
    }
}

// MARK: - MockFoodVoiceAdapter
final class MockFoodVoiceAdapter: FoodVoiceAdapterProtocol {
    var shouldFail = false
    var mockTranscription = "I ate an apple"
    
    func startListening() async throws {
        if shouldFail {
            throw FoodTrackingError.voiceRecognitionFailed
        }
    }
    
    func stopListening() async throws -> String {
        if shouldFail {
            throw FoodTrackingError.voiceRecognitionFailed
        }
        return mockTranscription
    }
    
    func isListening() -> Bool {
        return false
    }
}

// MARK: - MockFoodDatabaseService
final class MockFoodDatabaseService: FoodDatabaseServiceProtocol {
    var shouldFail = false
    var mockSearchResults: [FoodSearchResult] = []
    
    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        if shouldFail {
            throw FoodTrackingError.networkError
        }
        
        return mockSearchResults.isEmpty ? [
            FoodSearchResult(
                name: "Apple",
                calories: 95,
                protein: 0.5,
                carbs: 25,
                fat: 0.3,
                servingSize: "1 medium"
            )
        ] : mockSearchResults
    }
    
    func getFoodDetails(id: String) async throws -> FoodSearchResult? {
        if shouldFail {
            throw FoodTrackingError.networkError
        }
        
        return FoodSearchResult(
            name: "Apple",
            calories: 95,
            protein: 0.5,
            carbs: 25,
            fat: 0.3,
            servingSize: "1 medium"
        )
    }
} 