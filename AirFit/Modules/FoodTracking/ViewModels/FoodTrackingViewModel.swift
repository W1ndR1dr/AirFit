import SwiftUI
import SwiftData
import Observation

/// Central business logic coordinator for food tracking.
@MainActor
@Observable
final class FoodTrackingViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let foodVoiceAdapter: FoodVoiceAdapter
    private var nutritionService: NutritionServiceProtocol?
    private let foodDatabaseService: FoodDatabaseServiceProtocol
    private let coachEngine: CoachEngine
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
        nutritionService: NutritionServiceProtocol?,
        foodDatabaseService: FoodDatabaseServiceProtocol,
        coachEngine: CoachEngine,
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

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // First try local command parsing for simple cases (fast path)
            if let localResult = await parseLocalCommand(transcribedText) {
                parsedItems = localResult
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                logPerformance(startTime: startTime, method: "local", itemCount: localResult.count)
                return
            }

            // Adaptive confidence threshold based on user history
            let adaptiveThreshold = await calculateAdaptiveConfidenceThreshold()
            
            // Use direct function call for AI parsing with advanced features
            let functionCall = AIFunctionCall(
                name: "parseAndLogComplexNutrition",
                arguments: [
                    "naturalLanguageInput": AIAnyCodable(transcribedText),
                    "mealType": AIAnyCodable(selectedMealType.rawValue),
                    "confidenceThreshold": AIAnyCodable(adaptiveThreshold),
                    "includeAlternatives": AIAnyCodable(true) // Always include alternatives for better UX
                ]
            )

            // Execute with timeout (target: <5s for AI parsing)
            let result = try await withTimeout(seconds: 8.0) { [self] in
                try await self.coachEngine.executeFunction(functionCall, for: self.user)
            }

            // Convert function result to ParsedFoodItem array with advanced processing
            if result.success, let data = result.data {
                let (primaryItems, alternatives) = try convertFunctionResultWithAlternatives(data)
                
                // Intelligent confidence-based routing
                await handleAIParsingResult(
                    primaryItems: primaryItems,
                    alternatives: alternatives,
                    confidence: extractFloat(from: data["confidence"]) ?? 0.8,
                    adaptiveThreshold: adaptiveThreshold,
                    startTime: startTime
                )
            } else {
                // Intelligent fallback with suggestions
                await handleParsingFailure(originalText: transcribedText, startTime: startTime)
            }

        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.error("AI processing failed after \(Int(duration * 1000))ms: \(error)")
            
            // Intelligent error recovery
            await handleIntelligentErrorRecovery(error: error, originalText: transcribedText)
        }
    }

    private func calculateAdaptiveConfidenceThreshold() async -> Double {
        // Base threshold
        var threshold = 0.7
        
        // Adjust based on user's historical accuracy
        let recentEntries = try? await nutritionService?.getRecentFoods(for: user, limit: 20) ?? []
        let recentCount = recentEntries?.count ?? 0
        
        if recentCount > 10 {
            // User has experience - can handle lower confidence items
            threshold = 0.6
        } else if recentCount < 5 {
            // New user - require higher confidence
            threshold = 0.8
        }
        
        // Adjust based on complexity of input
        let wordCount = transcribedText.components(separatedBy: .whitespacesAndNewlines).count
        if wordCount > 10 {
            // Complex description - lower threshold to capture more possibilities
            threshold -= 0.1
        } else if wordCount < 3 {
            // Simple description - higher threshold for accuracy
            threshold += 0.1
        }
        
        return max(0.5, min(0.9, threshold))
    }

    private func convertFunctionResultWithAlternatives(_ data: [String: SendableValue]) throws -> ([ParsedFoodItem], [ParsedFoodItem]) {
        // Convert primary items
        let primaryItems = try convertFunctionResultToParsedItems(data)
        
        // Convert alternatives if available
        var alternatives: [ParsedFoodItem] = []
        if let alternativesValue = data["alternatives"],
           case .array(let alternativesArray) = alternativesValue {
            
            for altValue in alternativesArray {
                guard case .string(let altText) = altValue else { continue }
                
                // Create alternative parsed items with lower confidence
                let altItem = ParsedFoodItem(
                    name: altText,
                    brand: nil,
                    quantity: 1.0,
                    unit: "serving",
                    calories: 0, // Will be estimated
                    proteinGrams: nil,
                    carbGrams: nil,
                    fatGrams: nil,
                    confidence: 0.6 // Lower confidence for alternatives
                )
                alternatives.append(altItem)
            }
        }
        
        return (primaryItems, alternatives)
    }

    private func handleAIParsingResult(
        primaryItems: [ParsedFoodItem],
        alternatives: [ParsedFoodItem],
        confidence: Float,
        adaptiveThreshold: Double,
        startTime: CFAbsoluteTime
    ) async {
        let highConfidenceItems = primaryItems.filter { $0.confidence >= Float(adaptiveThreshold) }
        let lowConfidenceItems = primaryItems.filter { $0.confidence < Float(adaptiveThreshold) }
        
        if highConfidenceItems.isEmpty && lowConfidenceItems.isEmpty {
            // No items met threshold - show alternatives or fallback
            await handleLowConfidenceScenario(alternatives: alternatives, originalText: transcribedText)
        } else if lowConfidenceItems.isEmpty {
            // All items high confidence - proceed directly
            parsedItems = highConfidenceItems
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            logPerformance(startTime: startTime, method: "ai-high-confidence", itemCount: highConfidenceItems.count)
        } else {
            // Mixed confidence - show confirmation with alternatives
            parsedItems = primaryItems
            
            // Store alternatives for user to choose from
            if !alternatives.isEmpty {
                // TODO: Implement alternative selection UI
                AppLogger.info("AI parsing found \(alternatives.count) alternatives for low-confidence items")
            }
            
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            logPerformance(startTime: startTime, method: "ai-mixed-confidence", itemCount: primaryItems.count)
        }
    }

    private func handleLowConfidenceScenario(alternatives: [ParsedFoodItem], originalText: String) async {
        if !alternatives.isEmpty {
            // Show alternatives for user selection
            parsedItems = alternatives
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            AppLogger.info("Showing \(alternatives.count) alternative interpretations")
        } else {
            // Intelligent fallback with suggestions
            await provideFallbackSuggestions(originalText: originalText)
        }
    }

    private func handleParsingFailure(originalText: String, startTime: CFAbsoluteTime) async {
        AppLogger.warning("AI parsing failed for: '\(originalText.prefix(50))'")
        
        // Try to extract any recognizable food words
        let foodKeywords = extractFoodKeywords(from: originalText)
        
        if !foodKeywords.isEmpty {
            // Create suggestions based on keywords
            let suggestions = await generateKeywordBasedSuggestions(keywords: foodKeywords)
            if !suggestions.isEmpty {
                parsedItems = suggestions
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                logPerformance(startTime: startTime, method: "keyword-fallback", itemCount: suggestions.count)
                return
            }
        }
        
        // Final fallback - show search interface
        await provideFallbackSuggestions(originalText: originalText)
    }

    private func handleIntelligentErrorRecovery(error: Error, originalText: String) async {
        if error is TimeoutError {
            // Timeout - try simpler parsing
            await trySimplifiedParsing(originalText: originalText)
        } else {
            // Other errors - provide helpful guidance
            setError(FoodTrackingError.aiProcessingFailed(suggestion: generateErrorSuggestion(for: originalText)))
        }
    }

    private func trySimplifiedParsing(originalText: String) async {
        // Extract just the main food items without detailed nutrition
        let simplifiedItems = extractBasicFoodItems(from: originalText)
        
        if !simplifiedItems.isEmpty {
            parsedItems = simplifiedItems
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            AppLogger.info("Used simplified parsing fallback for \(simplifiedItems.count) items")
        } else {
            setError(FoodTrackingError.aiProcessingTimeout)
        }
    }

    private func extractFoodKeywords(from text: String) -> [String] {
        let commonFoods = [
            "chicken", "beef", "pork", "fish", "salmon", "tuna",
            "rice", "pasta", "bread", "potato", "sweet potato",
            "apple", "banana", "orange", "berries", "grapes",
            "broccoli", "spinach", "carrots", "tomato", "lettuce",
            "cheese", "milk", "yogurt", "eggs", "butter",
            "salad", "soup", "sandwich", "pizza", "burger"
        ]
        
        let lowercased = text.lowercased()
        return commonFoods.filter { lowercased.contains($0) }
    }

    private func generateKeywordBasedSuggestions(keywords: [String]) async -> [ParsedFoodItem] {
        var suggestions: [ParsedFoodItem] = []
        
        for keyword in keywords.prefix(3) { // Limit to top 3 suggestions
            if let dbItem = try? await foodDatabaseService.searchCommonFood(keyword) {
                let suggestion = ParsedFoodItem(
                    name: dbItem.name,
                    brand: dbItem.brand,
                    quantity: 1,
                    unit: dbItem.defaultUnit,
                    calories: dbItem.caloriesPerServing,
                    proteinGrams: dbItem.proteinPerServing,
                    carbGrams: dbItem.carbsPerServing,
                    fatGrams: dbItem.fatPerServing,
                    confidence: 0.7 // Medium confidence for keyword matches
                )
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }

    private func extractBasicFoodItems(from text: String) -> [ParsedFoodItem] {
        let keywords = extractFoodKeywords(from: text)
        
        return keywords.prefix(2).map { keyword in
            ParsedFoodItem(
                name: keyword.capitalized,
                brand: nil,
                quantity: 1,
                unit: "serving",
                calories: 100, // Rough estimate
                proteinGrams: 5,
                carbGrams: 10,
                fatGrams: 3,
                confidence: 0.5 // Low confidence for basic extraction
            )
        }
    }

    private func provideFallbackSuggestions(originalText: String) async {
        // Show manual search interface with the original text as query
        coordinator.showSheet(.foodSearch)
        
        // Pre-populate search with cleaned text
        let cleanedQuery = originalText
            .replacingOccurrences(of: "i had ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "i ate ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "log ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // TODO: Pass cleanedQuery to search interface
        AppLogger.info("Falling back to manual search with query: '\(cleanedQuery)'")
    }

    private func generateErrorSuggestion(for text: String) -> String {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        
        if wordCount > 15 {
            return "Try describing your meal more simply, focusing on the main ingredients."
        } else if wordCount < 2 {
            return "Try providing more details about what you ate, like 'grilled chicken with rice'."
        } else if text.contains("restaurant") || text.contains("takeout") {
            return "For restaurant meals, try describing the dish name and main ingredients."
        } else {
            return "Try speaking more clearly or describing your meal differently."
        }
    }

    private func logPerformance(startTime: CFAbsoluteTime, method: String, itemCount: Int) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let durationMs = Int(duration * 1000)
        AppLogger.info("Food parsing (\(method)): \(durationMs)ms, \(itemCount) items", category: .performance)
        
        // Log performance metrics for monitoring
        if method == "ai" && duration > 5.0 {
            AppLogger.warning("AI parsing exceeded 5s target: \(durationMs)ms", category: .performance)
        }
    }

    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }

    private func convertFunctionResultToParsedItems(_ data: [String: SendableValue]) throws -> [ParsedFoodItem] {
        guard let itemsValue = data["items"],
              case .array(let itemsArray) = itemsValue else {
            throw FoodTrackingError.noFoodsDetected
        }

        var parsedItems: [ParsedFoodItem] = []

        for itemValue in itemsArray {
            guard case .dictionary(let itemDict) = itemValue else { continue }

            let name = extractString(from: itemDict["name"]) ?? "Unknown Food"
            let quantityString = extractString(from: itemDict["quantity"]) ?? "1 serving"
            let calories = extractDouble(from: itemDict["calories"]) ?? 0
            let protein = extractDouble(from: itemDict["protein"]) ?? 0
            let carbs = extractDouble(from: itemDict["carbs"]) ?? 0
            let fat = extractDouble(from: itemDict["fat"]) ?? 0

            // Parse quantity and unit from quantity string (e.g., "1 cup", "150g")
            let (quantity, unit) = parseQuantityAndUnit(quantityString)

            let parsedItem = ParsedFoodItem(
                name: name,
                brand: nil, // AI function doesn't currently return brand info
                quantity: quantity,
                unit: unit,
                calories: calories,
                proteinGrams: protein,
                carbGrams: carbs,
                fatGrams: fat,
                confidence: extractFloat(from: data["confidence"]) ?? 0.8
            )

            parsedItems.append(parsedItem)
        }

        if parsedItems.isEmpty {
            throw FoodTrackingError.noFoodsDetected
        }

        return parsedItems
    }

    private func parseQuantityAndUnit(_ quantityString: String) -> (Double, String) {
        let components = quantityString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        
        if components.count >= 2,
           let quantity = Double(components[0]) {
            let unit = components.dropFirst().joined(separator: " ")
            return (quantity, unit)
        }
        
        // Fallback: try to extract number from beginning
        let scanner = Scanner(string: quantityString)
        if let quantity = scanner.scanDouble() {
            let remaining = String(quantityString.dropFirst(scanner.currentIndex.utf16Offset(in: quantityString)))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (quantity, remaining.isEmpty ? "serving" : remaining)
        }
        
        return (1.0, "serving")
    }

    // Helper methods for extracting values from SendableValue
    private func extractString(from value: SendableValue?) -> String? {
        guard let value = value else { return nil }
        switch value {
        case .string(let str): return str
        default: return nil
        }
    }

    private func extractDouble(from value: SendableValue?) -> Double? {
        guard let value = value else { return nil }
        switch value {
        case .double(let double): return double
        case .int(let int): return Double(int)
        default: return nil
        }
    }

    private func extractFloat(from value: SendableValue?) -> Float? {
        guard let value = value else { return nil }
        switch value {
        case .double(let double): return Float(double)
        case .int(let int): return Float(int)
        default: return nil
        }
    }

    private func parseLocalCommand(_ text: String) async -> [ParsedFoodItem]? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Simple pattern matching for basic food commands
        if lowercased.hasPrefix("i had ") || lowercased.hasPrefix("ate ") || lowercased.hasPrefix("log ") {
            let foodName = lowercased
                .replacingOccurrences(of: "i had ", with: "")
                .replacingOccurrences(of: "ate ", with: "")
                .replacingOccurrences(of: "log ", with: "")
                .replacingOccurrences(of: "an ", with: "")
                .replacingOccurrences(of: "a ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let dbItem = try? await foodDatabaseService.searchCommonFood(foodName) {
                return [ParsedFoodItem(
                    name: dbItem.name,
                    brand: dbItem.brand,
                    quantity: 1,
                    unit: dbItem.defaultUnit,
                    calories: dbItem.caloriesPerServing,
                    proteinGrams: dbItem.proteinPerServing,
                    carbGrams: dbItem.carbsPerServing,
                    fatGrams: dbItem.fatPerServing,
                    confidence: 0.9
                )]
            }
        }

        return nil
    }

    // MARK: - Photo Capture
    func startPhotoCapture() {
        coordinator.showSheet(.photoCapture)
    }

    func processPhotoResult(_ image: UIImage) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Use Vision framework and AI to analyze the meal photo
            let recognizedItems = try await analyzeMealPhoto(image)
            
            if !recognizedItems.isEmpty {
                parsedItems = recognizedItems
                coordinator.dismiss()
                coordinator.showFullScreenCover(.confirmation(parsedItems))
            } else {
                setError(FoodTrackingError.noFoodsDetected)
            }
        } catch {
            setError(error)
        }
    }
    
    private func analyzeMealPhoto(_ image: UIImage) async throws -> [ParsedFoodItem] {
        // Use AI to analyze the photo and identify food items
        // This would integrate with Vision framework and AI analysis
        // For now, return empty array as placeholder
        return []
    }

    // MARK: - Food Search
    func searchFoods(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            searchResults = try await foodDatabaseService.searchFoods(
                query: query,
                limit: 20
            )
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
            let foodEntry = FoodEntry(
                loggedAt: currentDate,
                mealType: selectedMealType,
                rawTranscript: transcribedText.isEmpty ? nil : transcribedText
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

                foodEntry.items.append(foodItem)
            }

            user.foodEntries.append(foodEntry)

            modelContext.insert(foodEntry)
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

        // Break down the complex expression into simpler steps
        let allItems = mealHistory.flatMap { $0.items }
        
        var itemCounts: [String: Int] = [:]
        for item in allItems {
            itemCounts[item.name, default: 0] += 1
        }
        
        let sortedItems = itemCounts.sorted { $0.value > $1.value }
        let topItems = Array(sortedItems.prefix(5))
        
        let frequentFoods = topItems.compactMap { (name, _) in
            allItems.first { $0.name == name }
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

    // MARK: - Public Methods
    
    func setSelectedMealType(_ mealType: MealType) {
        selectedMealType = mealType
    }
    
    func setParsedItems(_ items: [ParsedFoodItem]) {
        parsedItems = items
    }

    func setNutritionService(_ service: NutritionServiceProtocol) async {
        self.nutritionService = service
        // Load data once service is available
        await loadTodaysData()
    }
}

// MARK: - Supporting Types
struct ParsedFoodItem: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var brand: String?
    var quantity: Double
    var unit: String
    var calories: Double
    var proteinGrams: Double?
    var carbGrams: Double?
    var fatGrams: Double?
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var barcode: String?
    var databaseId: String?
    var confidence: Float
}

struct FoodNutritionSummary: Sendable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0

    var calorieGoal: Double = 2000
    var proteinGoal: Double = 50
    var carbGoal: Double = 250
    var fatGoal: Double = 65

    var calorieProgress: Double { calories / calorieGoal }
    var proteinProgress: Double { protein / proteinGoal }
    var carbProgress: Double { carbs / carbGoal }
    var fatProgress: Double { fat / fatGoal }
}

enum FoodTrackingError: LocalizedError {
    case noFoodsDetected
    case photoAnalysisFailed
    case saveFailed
    case aiProcessingTimeout
    case aiProcessingFailed(suggestion: String)

    var errorDescription: String? {
        switch self {
        case .noFoodsDetected:
            return "No foods detected in your description"
        case .photoAnalysisFailed:
            return "Unable to analyze the photo. Please try again or add foods manually."
        case .saveFailed:
            return "Failed to save food entry"
        case .aiProcessingTimeout:
            return "AI processing took too long. Please try again with a simpler description."
        case .aiProcessingFailed(let suggestion):
            return "AI processing failed. Suggestion: \(suggestion)"
        }
    }
}

struct TimeoutError: Error {
    let message = "Operation timed out"
}

enum WaterUnit: String, CaseIterable {
    case ml = "ml"
    case oz = "oz"
    case cups = "cups"
    case liters = "L"

    func toMilliliters(_ amount: Double) -> Double {
        switch self {
        case .ml: return amount
        case .oz: return amount * 29.5735
        case .cups: return amount * 236.588
        case .liters: return amount * 1000
        }
    }
}

