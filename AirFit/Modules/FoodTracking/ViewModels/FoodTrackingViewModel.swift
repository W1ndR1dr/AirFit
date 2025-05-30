import SwiftUI
import SwiftData
import Observation
import Foundation
import UIKit

/// Central business logic coordinator for food tracking.
@MainActor
@Observable
final class FoodTrackingViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    internal let user: User
    private let foodVoiceAdapter: FoodVoiceAdapter
    private let nutritionService: NutritionServiceProtocol?
    private let foodDatabaseService: FoodDatabaseServiceProtocol
    internal let coachEngine: FoodCoachEngineProtocol
    private let coordinator: FoodTrackingCoordinator

    // MARK: - State
    private(set) var isLoading = false
    private(set) var error: Error?

    // Current meal being logged
    var selectedMealType: MealType = .lunch
    var currentDate = Date()

    // Voice input state
    private(set) var isRecording = false
    private(set) var transcribedText = ""
    private(set) var transcriptionConfidence: Float = 0
    private(set) var voiceWaveform: [Float] = []

    // Parsed food items
    private(set) var parsedItems: [ParsedFoodItem] = []
    private(set) var isProcessingAI = false

    // Today's data
    private(set) var todaysFoodEntries: [FoodEntry] = []
    private(set) var todaysNutrition = FoodNutritionSummary()
    private(set) var waterIntakeML: Double = 0

    // Search and suggestions
    private(set) var searchResults: [FoodDatabaseItem] = []
    private(set) var recentFoods: [FoodItem] = []
    private(set) var suggestedFoods: [FoodItem] = []

    // Error handling
    private(set) var currentError: Error?
    
    var hasError: Bool {
        currentError != nil
    }
    
    func clearError() {
        currentError = nil
    }
    
    private func setError(_ error: Error) {
        currentError = error
    }

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        user: User,
        foodVoiceAdapter: FoodVoiceAdapter,
        nutritionService: NutritionServiceProtocol,
        foodDatabaseService: FoodDatabaseServiceProtocol,
        coachEngine: FoodCoachEngineProtocol,
        coordinator: FoodTrackingCoordinator
    ) {
        self.modelContext = modelContext
        self.user = user
        self.foodVoiceAdapter = foodVoiceAdapter
        self.nutritionService = nutritionService
        self.foodDatabaseService = foodDatabaseService
        self.coachEngine = coachEngine
        self.coordinator = coordinator

        setupVoiceCallbacks()
    }

    private func setupVoiceCallbacks() {
        foodVoiceAdapter.onFoodTranscription = { [weak self] text in
            Task { @MainActor in
                self?.transcribedText = text
                await self?.processTranscription()
            }
        }

        foodVoiceAdapter.onError = { [weak self] error in
            Task { @MainActor in
                self?.error = error
            }
        }
    }

    // MARK: - Data Loading
    func loadTodaysData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            todaysFoodEntries = try await nutritionService?.getFoodEntries(
                for: user,
                date: currentDate
            ) ?? []

            todaysNutrition = nutritionService?.calculateNutritionSummary(
                from: todaysFoodEntries
            ) ?? FoodNutritionSummary()

            waterIntakeML = try await nutritionService?.getWaterIntake(
                for: user,
                date: currentDate
            ) ?? 0

            recentFoods = try await nutritionService?.getRecentFoods(
                for: user,
                limit: 10
            ) ?? []

            suggestedFoods = try await generateSmartSuggestions()

        } catch {
            AppLogger.error("Failed to load today's data: \(error)")
            setError(error)
        }
    }

    // MARK: - Voice Input
    func startVoiceInput() async {
        do {
            let hasPermission = try await foodVoiceAdapter.requestPermission()
            guard hasPermission else {
                error = FoodVoiceError.permissionDenied
                return
            }

            coordinator.showSheet(.voiceInput)

        } catch {
            AppLogger.error("Failed to start voice input: \(error)")
            setError(error)
        }
    }

    func startRecording() async {
        guard !isRecording else { return }

        do {
            try await foodVoiceAdapter.startRecording()
            isRecording = true
            transcribedText = ""
            transcriptionConfidence = 0
            voiceWaveform = []

        } catch {
            setError(error)
            isRecording = false
            AppLogger.error("Failed to start recording: \(error)")
        }
    }

    func stopRecording() async {
        guard isRecording else { return }

        isRecording = false

        if let finalText = await foodVoiceAdapter.stopRecording() {
            transcribedText = finalText
            transcriptionConfidence = 1.0

            if !finalText.isEmpty {
                await processTranscription()
            }
        }
    }

    // MARK: - AI Processing
    private func processTranscription() async {
        guard !transcribedText.isEmpty else { return }

        isProcessingAI = true
        defer { isProcessingAI = false }

        do {
            if let localResult = await parseLocalCommand(transcribedText) {
                parsedItems = localResult
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                return
            }

            // TODO: Implement AI parsing in CoachEngine
            let aiResult = try await parseWithLocalFallback(transcribedText)

            parsedItems = aiResult.items

            if !parsedItems.isEmpty {
                coordinator.dismiss()
                coordinator.showFullScreenCover(.confirmation(parsedItems))
            } else {
                setError(FoodTrackingError.noFoodFound)
            }

        } catch {
            setError(error)
            AppLogger.error("Failed to process transcription: \(error)")
        }
    }

    private func parseLocalCommand(_ text: String) async -> [ParsedFoodItem]? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple pattern matching for basic food parsing
        if let match = lowercased.firstMatch(of: /(\d+(?:\.\d+)?)\s*(cups?|cup|tablespoons?|tbsp|teaspoons?|tsp|ounces?|oz|pounds?|lbs?|grams?|g)\s+(?:of\s+)?(.+)/) {
            let quantity = Double(String(match.1)) ?? 1.0
            let unit = String(match.2)
            let foodName = String(match.3).trimmingCharacters(in: .whitespaces)
            
            return [ParsedFoodItem(
                name: foodName,
                brand: nil,
                quantity: quantity,
                unit: unit,
                calories: 100, // Placeholder
                proteinGrams: 5,
                carbGrams: 15,
                fatGrams: 3,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                barcode: nil,
                databaseId: nil,
                confidence: 0.7
            )]
        }
        
        // Fallback: treat entire text as food name
        return [ParsedFoodItem(
            name: text,
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: 100,
            proteinGrams: 5,
            carbGrams: 15,
            fatGrams: 3,
            fiberGrams: nil,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            barcode: nil,
            databaseId: nil,
            confidence: 0.5
        )]
    }

    // MARK: - Barcode Scanning
    func startBarcodeScanning() {
        coordinator.showSheet(.photoCapture)
    }

    func processBarcodeResult(_ barcode: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let product = try await foodDatabaseService.lookupBarcode(barcode) {
                let parsedItem = ParsedFoodItem(
                    name: product.name,
                    brand: product.brand,
                    quantity: product.defaultQuantity,
                    unit: product.defaultUnit,
                    calories: product.caloriesPerServing,
                    proteinGrams: product.proteinPerServing,
                    carbGrams: product.carbsPerServing,
                    fatGrams: product.fatPerServing,
                    fiberGrams: nil,
                    sugarGrams: nil,
                    sodiumMilligrams: nil,
                    barcode: nil,
                    databaseId: product.id,
                    confidence: 1.0
                )

                parsedItems = [parsedItem]
                coordinator.dismiss()
                coordinator.showFullScreenCover(.confirmation(parsedItems))
            } else {
                setError(FoodTrackingError.barcodeNotFound)
            }
        } catch {
            setError(error)
        }
    }

    // MARK: - Food Search
    func searchFoods(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            let results = try await foodDatabaseService.searchFoods(
                query: query,
                limit: 20
            )
            searchResults = results
        } catch {
            AppLogger.error("Food search failed", error: error, category: .data)
            searchResults = []
        }
    }

    func selectSearchResult(_ item: FoodDatabaseItem) {
        let parsedItem = ParsedFoodItem(
            name: item.name,
            brand: item.brand,
            quantity: item.defaultQuantity,
            unit: item.defaultUnit,
            calories: item.caloriesPerServing,
            proteinGrams: item.proteinPerServing,
            carbGrams: item.carbsPerServing,
            fatGrams: item.fatPerServing,
            fiberGrams: nil,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            barcode: nil,
            databaseId: item.id,
            confidence: 1.0
        )

        parsedItems = [parsedItem]
        coordinator.dismiss()
        coordinator.showFullScreenCover(.confirmation(parsedItems))
    }

    // MARK: - Saving Food Entries
    func confirmAndSaveFoodItems(_ items: [ParsedFoodItem]) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let foodItems = items.map { parsedItem in
                FoodItem(
                    name: parsedItem.name,
                    brand: parsedItem.brand,
                    quantity: parsedItem.quantity,
                    unit: parsedItem.unit,
                    calories: parsedItem.calories,
                    proteinGrams: parsedItem.proteinGrams,
                    carbGrams: parsedItem.carbGrams,
                    fatGrams: parsedItem.fatGrams
                )
            }
            
            let entry = FoodEntry(
                loggedAt: currentDate,
                mealType: selectedMealType,
                user: user
            )

            for parsedItem in items {
                let foodItem = FoodItem(
                    name: parsedItem.name,
                    brand: parsedItem.brand,
                    quantity: parsedItem.quantity,
                    unit: parsedItem.unit,
                    calories: parsedItem.calories,
                    proteinGrams: parsedItem.proteinGrams ?? 0,
                    carbGrams: parsedItem.carbGrams ?? 0,
                    fatGrams: parsedItem.fatGrams ?? 0
                )

                foodItem.fiberGrams = parsedItem.fiber
                foodItem.sugarGrams = parsedItem.sugar
                foodItem.sodiumMg = parsedItem.sodium
                foodItem.barcode = parsedItem.barcode

                entry.items.append(foodItem)
            }

            user.foodEntries.append(entry)

            modelContext.insert(entry)
            try modelContext.save()

            await loadTodaysData()

            parsedItems = []
            transcribedText = ""

            coordinator.dismiss()
            HapticManager.notification(.success)

            AppLogger.info("Saved \(items.count) food items", category: .data)

        } catch {
            AppLogger.error("Failed to save food entry: \(error)")
            setError(error)
        }
    }

    // MARK: - Water Tracking
    func logWater(amount: Double, unit: WaterUnit) async {
        do {
            let amountInML = unit.toMilliliters(amount)

            try await nutritionService?.logWaterIntake(
                for: user,
                amountML: amountInML,
                date: currentDate
            )

            waterIntakeML += amountInML

            HapticManager.impact(.light)

        } catch {
            setError(error)
            AppLogger.error("Failed to log water: \(error)")
        }
    }

    // MARK: - Smart Suggestions
    private func generateSmartSuggestions() async throws -> [FoodItem] {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let dayOfWeek = Calendar.current.component(.weekday, from: currentDate)

        let mealHistory = try await nutritionService?.getMealHistory(
            for: user,
            mealType: selectedMealType,
            daysBack: 30
        ) ?? []

        // Simplify the frequent foods calculation to avoid compiler timeout
        var foodFrequency: [String: Int] = [:]
        for entry in mealHistory {
            for item in entry.items {
                foodFrequency[item.name, default: 0] += 1
            }
        }
        
        let frequentFoods = foodFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { (name, _) in
                mealHistory.flatMap { $0.items }.first { $0.name == name }
            }

        _ = hour + dayOfWeek // avoid unused warnings for now
        return Array(frequentFoods)
    }

    // MARK: - Meal Management
    func deleteFoodEntry(_ entry: FoodEntry) async {
        do {
            modelContext.delete(entry)
            try modelContext.save()
            await loadTodaysData()

        } catch {
            setError(error)
            AppLogger.error("Failed to delete food entry: \(error)")
        }
    }

    func duplicateFoodEntry(_ entry: FoodEntry) async {
        do {
            let duplicate = entry.duplicate()
            duplicate.loggedAt = currentDate

            user.foodEntries.append(duplicate)
            modelContext.insert(duplicate)
            try modelContext.save()

            await loadTodaysData()

        } catch {
            setError(error)
            AppLogger.error("Failed to duplicate food entry: \(error)")
        }
    }

    // MARK: - AI Function Execution
    /// Executes a CoachEngine function call with a timeout to avoid hanging tasks.
    private func processAIResult(functionCall: AIFunctionCall) async {
        do {
            let result = try await withTimeout(seconds: 8.0) { [self] in
                try await self.coachEngine.executeFunction(functionCall, for: self.user)
            }
            AppLogger.info("AI function \(result.functionName) executed", category: .ai)
        } catch {
            setError(error)
            AppLogger.error("AI function execution failed", error: error, category: .ai)
        }
    }

    /// Runs an asynchronous operation with a timeout using `withCheckedContinuation`.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var finished = false

            let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
                guard !finished else { return }
                finished = true
                continuation.resume(throwing: FoodTrackingError.aiProcessingTimeout)
            }

            Task {
                do {
                    let result = try await operation()
                    guard !finished else { return }
                    finished = true
                    timer.invalidate()
                    continuation.resume(returning: result)
                } catch {
                    guard !finished else { return }
                    finished = true
                    timer.invalidate()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Public Methods
    
    func setSelectedMealType(_ mealType: MealType) {
        selectedMealType = mealType
    }
    
    func setParsedItems(_ items: [ParsedFoodItem]) {
        parsedItems = items
    }

    // MARK: - Photo Processing
    func processPhotoResult(_ image: UIImage) {
        // This method will be called by PhotoInputView after successful analysis
        // For now, just log that a photo was processed
        AppLogger.info("Photo processed successfully", category: .ai)
    }

    // MARK: - Local Parsing Fallback
    private func parseWithLocalFallback(_ text: String) async throws -> (items: [ParsedFoodItem], confidence: Float) {
        let items = parseSimpleFood(text)
        return (items: items, confidence: 0.7)
    }
    
    private func parseSimpleFood(_ text: String) -> [ParsedFoodItem] {
        // Use the same logic as parseLocalCommand but return the result directly
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple pattern matching for basic food parsing
        if let match = lowercased.firstMatch(of: /(\d+(?:\.\d+)?)\s*(cups?|cup|tablespoons?|tbsp|teaspoons?|tsp|ounces?|oz|pounds?|lbs?|grams?|g)\s+(?:of\s+)?(.+)/) {
            let quantity = Double(String(match.1)) ?? 1.0
            let unit = String(match.2)
            let foodName = String(match.3).trimmingCharacters(in: .whitespaces)
            
            return [ParsedFoodItem(
                name: foodName,
                brand: nil,
                quantity: quantity,
                unit: unit,
                calories: 100, // Placeholder
                proteinGrams: 5,
                carbGrams: 15,
                fatGrams: 3,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                barcode: nil,
                databaseId: nil,
                confidence: 0.7
            )]
        }
        
        // Fallback: treat entire text as food name
        return [ParsedFoodItem(
            name: text,
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: 100,
            proteinGrams: 5,
            carbGrams: 15,
            fatGrams: 3,
            fiberGrams: nil,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            barcode: nil,
            databaseId: nil,
            confidence: 0.5
        )]
    }
}


enum WaterUnit: String, CaseIterable {
    case milliliters = "ml"
    case oz = "oz"
    case cups = "cups"
    case liters = "L"

    func toMilliliters(_ amount: Double) -> Double {
        switch self {
        case .milliliters: return amount
        case .oz: return amount * 29.5735
        case .cups: return amount * 236.588
        case .liters: return amount * 1000
        }
    }
}

// MARK: - Protocols

/// Interface for AI-powered nutrition coaching features.
protocol FoodCoachEngineProtocol: Sendable {
    /// Processes a free-form user message related to nutrition.
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue]

    /// Executes a high-value function call on behalf of the user.
    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult

    /// Analyzes a meal photo and returns detected foods and nutrition data.
    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult
}

