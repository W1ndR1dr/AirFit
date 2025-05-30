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
    let coordinator: FoodTrackingCoordinator // Made public for NutritionSearchView

    // MARK: - State
    private(set) var isLoading = false
    // private(set) var error: Error? // Replaced by currentError

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
        AppLogger.error("FoodTrackingViewModel Error: \(error.localizedDescription)", category: .ui)
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
    
    // MARK: - Convenience Initializer for Previews/Testing
    convenience init(
        nutritionService: NutritionServiceProtocol,
        coachEngine: CoachEngine,
        voiceAdapter: FoodVoiceAdapter
    ) {
        // Create mock dependencies for previews
        let container = try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        
        let user = User(
            id: UUID(),
            createdAt: Date(),
            lastActiveAt: Date(),
            email: "test@example.com",
            name: "Test User",
            preferredUnits: .metric
        )
        context.insert(user)
        
        let coordinator = FoodTrackingCoordinator()
        let foodDatabaseService = MockFoodDatabaseService()
        
        self.init(
            modelContext: context,
            user: user,
            foodVoiceAdapter: voiceAdapter,
            nutritionService: nutritionService,
            foodDatabaseService: foodDatabaseService,
            coachEngine: coachEngine,
            coordinator: coordinator
        )
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
                self?.setError(error)
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
            
            // Ensure goals are set in todaysNutrition
            if let profile = user.onboardingProfile, let targets = nutritionService?.getTargets(from: profile) {
                todaysNutrition.calorieGoal = targets.calories
                todaysNutrition.proteinGoal = targets.protein
                todaysNutrition.carbGoal = targets.carbs
                todaysNutrition.fatGoal = targets.fat
            }


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
            AppLogger.error("Failed to load today's data: \(error.localizedDescription)", category: .data)
            setError(error)
        }
    }

    // MARK: - Voice Input
    func startVoiceInput() async {
        do {
            let hasPermission = try await foodVoiceAdapter.requestPermission()
            guard hasPermission else {
                setError(FoodVoiceError.permissionDenied)
                return
            }

            coordinator.showSheet(.voiceInput)

        } catch {
            AppLogger.error("Failed to start voice input: \(error.localizedDescription)", category: .ui)
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
            AppLogger.error("Failed to start recording: \(error.localizedDescription)", category: .ui)
        }
    }

    func stopRecording() async {
        guard isRecording else { return }

        isRecording = false

        if let finalText = await foodVoiceAdapter.stopRecording() {
            transcribedText = finalText
            transcriptionConfidence = 1.0 // Assuming final transcription has high confidence

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
            if let localResult = await parseLocalCommand(transcribedText) {
                parsedItems = localResult
                coordinator.dismiss() // Dismiss voice input sheet
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                logPerformance(startTime: startTime, method: "local", itemCount: localResult.count)
                return
            }

            let adaptiveThreshold = await calculateAdaptiveConfidenceThreshold()
            
            let functionCall = AIFunctionCall(
                name: "parseAndLogComplexNutrition",
                arguments: [
                    "naturalLanguageInput": AIAnyCodable(transcribedText),
                    "mealType": AIAnyCodable(selectedMealType.rawValue),
                    "confidenceThreshold": AIAnyCodable(adaptiveThreshold),
                    "includeAlternatives": AIAnyCodable(true)
                ]
            )

            let result = try await withTimeout(seconds: 8.0) { [self] in
                try await self.coachEngine.executeFunction(functionCall, for: self.user)
            }

            if result.success, let data = result.data {
                let (primaryItems, alternatives) = try convertFunctionResultWithAlternatives(data)
                await handleAIParsingResult(
                    primaryItems: primaryItems,
                    alternatives: alternatives,
                    confidence: extractFloat(from: data["confidence"]) ?? 0.8,
                    adaptiveThreshold: adaptiveThreshold,
                    startTime: startTime
                )
            } else {
                await handleParsingFailure(originalText: transcribedText, startTime: startTime)
            }

        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.error("AI processing failed after \(Int(duration * 1000))ms: \(error.localizedDescription)", category: .ai)
            await handleIntelligentErrorRecovery(error: error, originalText: transcribedText)
        }
    }

    private func calculateAdaptiveConfidenceThreshold() async -> Double {
        var threshold = 0.7
        
        let recentEntries = try? await nutritionService?.getRecentFoods(for: user, limit: 20) ?? []
        let recentCount = recentEntries?.count ?? 0
        
        if recentCount > 10 { threshold = 0.6 }
        else if recentCount < 5 { threshold = 0.8 }
        
        let wordCount = transcribedText.components(separatedBy: .whitespacesAndNewlines).count
        if wordCount > 10 { threshold -= 0.1 }
        else if wordCount < 3 { threshold += 0.1 }
        
        return max(0.5, min(0.9, threshold))
    }

    private func convertFunctionResultWithAlternatives(_ data: [String: SendableValue]) throws -> ([ParsedFoodItem], [ParsedFoodItem]) {
        let primaryItems = try convertFunctionResultToParsedItems(data)
        var alternatives: [ParsedFoodItem] = []

        if let alternativesValue = data["alternatives"], case .array(let alternativesArray) = alternativesValue {
            for altValue in alternativesArray {
                guard case .string(let altText) = altValue else { continue }
                alternatives.append(ParsedFoodItem(
                    name: altText, quantity: 1.0, unit: "serving", calories: 0, confidence: 0.6
                ))
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
        
        if primaryItems.isEmpty { // Check primaryItems directly
            await handleLowConfidenceScenario(alternatives: alternatives, originalText: transcribedText)
        } else {
             parsedItems = primaryItems // Use all primary items, confirmation view handles confidence display
             coordinator.dismiss() // Dismiss voice input sheet
             coordinator.showFullScreenCover(.confirmation(parsedItems))
             logPerformance(startTime: startTime, method: "ai-parsed", itemCount: primaryItems.count)
        }
    }


    private func handleLowConfidenceScenario(alternatives: [ParsedFoodItem], originalText: String) async {
        if !alternatives.isEmpty {
            parsedItems = alternatives // Show alternatives if primary parsing failed or was empty
            coordinator.dismiss() // Dismiss voice input sheet
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            AppLogger.info("Showing \(alternatives.count) alternative interpretations for: '\(originalText.prefix(50))'", category: .ai)
        } else {
            await provideFallbackSuggestions(originalText: originalText)
        }
    }

    private func handleParsingFailure(originalText: String, startTime: CFAbsoluteTime) async {
        AppLogger.warning("AI parsing failed for: '\(originalText.prefix(50))'", category: .ai)
        let foodKeywords = extractFoodKeywords(from: originalText)
        
        if !foodKeywords.isEmpty {
            let suggestions = await generateKeywordBasedSuggestions(keywords: foodKeywords)
            if !suggestions.isEmpty {
                parsedItems = suggestions
                coordinator.dismiss() // Dismiss voice input sheet
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                logPerformance(startTime: startTime, method: "keyword-fallback", itemCount: suggestions.count)
                return
            }
        }
        await provideFallbackSuggestions(originalText: originalText)
    }

    private func handleIntelligentErrorRecovery(error: Error, originalText: String) async {
        if error is TimeoutError {
            await trySimplifiedParsing(originalText: originalText)
        } else {
            setError(FoodTrackingError.aiProcessingFailed(suggestion: generateErrorSuggestion(for: originalText)))
        }
    }

    private func trySimplifiedParsing(originalText: String) async {
        let simplifiedItems = extractBasicFoodItems(from: originalText)
        if !simplifiedItems.isEmpty {
            parsedItems = simplifiedItems
            coordinator.dismiss() // Dismiss voice input sheet
            coordinator.showFullScreenCover(.confirmation(parsedItems))
            AppLogger.info("Used simplified parsing fallback for \(simplifiedItems.count) items", category: .ai)
        } else {
            setError(FoodTrackingError.aiProcessingTimeout)
        }
    }

    private func extractFoodKeywords(from text: String) -> [String] {
        let commonFoods = [
            "chicken", "beef", "pork", "fish", "salmon", "tuna", "rice", "pasta", "bread", "potato",
            "apple", "banana", "orange", "berries", "broccoli", "spinach", "carrots", "salad", "egg"
        ]
        let lowercased = text.lowercased()
        return commonFoods.filter { lowercased.contains($0) }
    }

    private func generateKeywordBasedSuggestions(keywords: [String]) async -> [ParsedFoodItem] {
        var suggestions: [ParsedFoodItem] = []
        for keyword in keywords.prefix(3) {
            if let dbItem = try? await foodDatabaseService.searchCommonFood(keyword) {
                suggestions.append(ParsedFoodItem(
                    name: dbItem.name, brand: dbItem.brand, quantity: 1, unit: dbItem.defaultUnit,
                    calories: dbItem.caloriesPerServing, proteinGrams: dbItem.proteinPerServing,
                    carbGrams: dbItem.carbsPerServing, fatGrams: dbItem.fatPerServing, confidence: 0.7
                ))
            }
        }
        return suggestions
    }

    private func extractBasicFoodItems(from text: String) -> [ParsedFoodItem] {
        let keywords = extractFoodKeywords(from: text)
        return keywords.prefix(2).map { keyword in
            ParsedFoodItem(
                name: keyword.capitalized, quantity: 1, unit: "serving",
                calories: 100, proteinGrams: 5, carbGrams: 10, fatGrams: 3, confidence: 0.5
            )
        }
    }

    private func provideFallbackSuggestions(originalText: String) async {
        coordinator.dismiss() // Dismiss voice input sheet
        coordinator.showSheet(.foodSearch)
        let cleanedQuery = originalText
            .replacingOccurrences(of: "i had ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ate ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "log ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // TODO: Pass cleanedQuery to search interface if it supports pre-filled text
        AppLogger.info("Falling back to manual search with query: '\(cleanedQuery)'", category: .ui)
    }

    private func generateErrorSuggestion(for text: String) -> String {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        if wordCount > 15 { return "Try describing your meal more simply." }
        else if wordCount < 2 { return "Try providing more details, like 'grilled chicken with rice'." }
        else if text.contains("restaurant") { return "For restaurant meals, try describing the dish name and main ingredients."}
        else { return "Try speaking more clearly or describing your meal differently." }
    }

    private func logPerformance(startTime: CFAbsoluteTime, method: String, itemCount: Int) {
        let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
        AppLogger.info("Food parsing (\(method)): \(durationMs)ms, \(itemCount) items", category: .performance)
        if method.contains("ai") && durationMs > 5000 {
            AppLogger.warning("AI parsing exceeded 5s target: \(durationMs)ms", category: .performance)
        }
    }

    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            guard let result = try await group.next() else { throw TimeoutError() }
            group.cancelAll()
            return result
        }
    }

    private func convertFunctionResultToParsedItems(_ data: [String: SendableValue]) throws -> [ParsedFoodItem] {
        guard let itemsValue = data["items"], case .array(let itemsArray) = itemsValue else {
            // If "items" is not an array or not present, it might mean no high-confidence items were found.
            // This is not necessarily an error if alternatives are present.
            return [] // Return empty if no primary items
        }

        var parsedItems: [ParsedFoodItem] = []
        for itemValue in itemsArray {
            guard case .dictionary(let itemDict) = itemValue else { continue }
            let name = extractString(from: itemDict["name"]) ?? "Unknown Food"
            let quantityString = extractString(from: itemDict["quantity"]) ?? "1 serving"
            let (quantity, unit) = parseQuantityAndUnit(quantityString)
            parsedItems.append(ParsedFoodItem(
                name: name, brand: extractString(from: itemDict["brand"]), quantity: quantity, unit: unit,
                calories: extractDouble(from: itemDict["calories"]) ?? 0,
                proteinGrams: extractDouble(from: itemDict["protein"]),
                carbGrams: extractDouble(from: itemDict["carbs"]),
                fatGrams: extractDouble(from: itemDict["fat"]),
                fiber: extractDouble(from: itemDict["fiber"]),
                sugar: extractDouble(from: itemDict["sugar"]),
                sodium: extractDouble(from: itemDict["sodium"]),
                confidence: extractFloat(from: itemDict["confidence"]) ?? 0.8 // Default high if not specified
            ))
        }
        return parsedItems
    }

    private func parseQuantityAndUnit(_ quantityString: String) -> (Double, String) {
        let components = quantityString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        if components.count >= 2, let quantity = Double(components[0]) {
            return (quantity, components.dropFirst().joined(separator: " "))
        }
        let scanner = Scanner(string: quantityString)
        if let quantity = scanner.scanDouble() {
            let remaining = String(quantityString.dropFirst(scanner.currentIndex.utf16Offset(in: quantityString))).trimmingCharacters(in: .whitespacesAndNewlines)
            return (quantity, remaining.isEmpty ? "serving" : remaining)
        }
        return (1.0, "serving") // Default
    }

    private func extractString(from value: SendableValue?) -> String? {
        guard case .string(let str) = value else { return nil }
        return str
    }
    private func extractDouble(from value: SendableValue?) -> Double? {
        guard let value = value else { return nil }
        switch value {
        case .double(let d): return d
        case .int(let i): return Double(i)
        default: return nil
        }
    }
    private func extractFloat(from value: SendableValue?) -> Float? {
        guard let value = value else { return nil }
        switch value {
        case .double(let d): return Float(d)
        case .int(let i): return Float(i)
        default: return nil
        }
    }

    private func parseLocalCommand(_ text: String) async -> [ParsedFoodItem]? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            #"^(?:i had |ate |log )?(?:an? )?([\w\s]+)$"#, // "log apple", "ate chicken salad"
            #"^([\w\s]+)$"# // "apple", "chicken salad"
        ]

        for pattern in patterns {
            if let match = lowercased.firstMatch(of: Regex(pattern)) {
                let foodName = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
            if let dbItem = try? await foodDatabaseService.searchCommonFood(foodName) {
                return [ParsedFoodItem(
                        name: dbItem.name, brand: dbItem.brand, quantity: dbItem.defaultQuantity, unit: dbItem.defaultUnit,
                        calories: dbItem.caloriesPerServing, proteinGrams: dbItem.proteinPerServing,
                        carbGrams: dbItem.carbsPerServing, fatGrams: dbItem.fatPerServing, confidence: 0.95 // High confidence for local exact match
                    )]
                }
            }
        }
        return nil
    }

    // MARK: - Photo Capture
    func startPhotoCapture() {
        // Ensure permissions are checked before showing the sheet
        Task {
            // Placeholder for camera permission check if not handled by PhotoInputView itself
            // For now, directly show the sheet as per current structure
            coordinator.showSheet(.photoCapture)
        }
    }


    func processPhotoResult(_ image: UIImage) async {
        isLoading = true
        defer { isLoading = false }

        let startTime = CFAbsoluteTimeGetCurrent()
        do {
            let recognizedItems = try await analyzeMealPhoto(image)
            if !recognizedItems.isEmpty {
                parsedItems = recognizedItems
                coordinator.dismiss() // Dismiss photo input sheet
                coordinator.showFullScreenCover(.confirmation(parsedItems))
                logPerformance(startTime: startTime, method: "photo-analysis", itemCount: recognizedItems.count)
            } else {
                setError(FoodTrackingError.noFoodsDetected)
            }
        } catch {
            setError(error)
            logPerformance(startTime: startTime, method: "photo-analysis-failed", itemCount: 0)
        }
    }
    
    private func analyzeMealPhoto(_ image: UIImage) async throws -> [ParsedFoodItem] {
        // This integrates with the CoachEngine's analyzeMealPhoto function
        // which should handle Vision and AI analysis.
        let result = try await coachEngine.analyzeMealPhoto(image: image, context: NutritionContext(userPreferences: user.nutritionPreferences, recentMeals: recentFoods, timeOfDay: currentDate))
        
        // Assuming result.items is already [ParsedFoodItem]
        // If not, conversion logic would be needed here.
        return result.items
    }

    // MARK: - Food Search
    func searchFoods(_ query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            searchResults = try await foodDatabaseService.searchFoods(
                query: query,
                limit: 20
            )
        } catch {
            AppLogger.error("Food search failed: \(error.localizedDescription)", category: .data)
            setError(error) // Set error for UI to potentially display
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
            confidence: 1.0 // High confidence for direct selection
        )
        parsedItems = [parsedItem]
        coordinator.dismiss() // Dismiss search sheet
        coordinator.showFullScreenCover(.confirmation(parsedItems))
    }

    // MARK: - Saving Food Entries
    func confirmAndSaveFoodItems(_ items: [ParsedFoodItem]) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let foodEntry = FoodEntry(
                loggedAt: currentDate,
                mealType: selectedMealType, // Ensure this is a MealType enum
                rawTranscript: transcribedText.isEmpty ? nil : transcribedText
            )

            for parsedItem in items {
                let foodItem = FoodItem(
                    name: parsedItem.name, brand: parsedItem.brand, quantity: parsedItem.quantity,
                    unit: parsedItem.unit, calories: parsedItem.calories,
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

            user.foodEntries.append(foodEntry) // Establish relationship
            modelContext.insert(foodEntry) // Insert the entry
            try modelContext.save()

            await loadTodaysData() // Refresh UI
            parsedItems = []
            transcribedText = ""
            coordinator.dismiss() // Dismiss confirmation sheet
            HapticManager.notification(.success)
            AppLogger.info("Saved \(items.count) food items for meal \(selectedMealType.rawValue)", category: .data)

        } catch {
            AppLogger.error("Failed to save food entry: \(error.localizedDescription)", category: .data)
            setError(FoodTrackingError.saveFailed)
        }
    }

    // MARK: - Water Tracking
    func logWater(amount: Double, unit: WaterUnit) async {
        isLoading = true // Indicate activity
        defer { isLoading = false }
        do {
            let amountInML = unit.toMilliliters(amount)
            try await nutritionService?.logWaterIntake(
                for: user,
                amountML: amountInML,
                date: currentDate
            )
            // Optimistically update local state, or rely on loadTodaysData if service updates DB
            waterIntakeML += amountInML
            HapticManager.impact(.light)
            AppLogger.info("Logged \(amountInML)ml water", category: .data)
        } catch {
            setError(error)
            AppLogger.error("Failed to log water: \(error.localizedDescription)", category: .data)
        }
    }

    // MARK: - Smart Suggestions
    private func generateSmartSuggestions() async throws -> [FoodItem] {
        // Ensure nutritionService is available
        guard let nutritionService = self.nutritionService else {
            AppLogger.warning("NutritionService not available for smart suggestions.", category: .ai)
            return []
        }

        let mealHistory = try await nutritionService.getMealHistory(
            for: user,
            mealType: selectedMealType,
            daysBack: 30 // Look back 30 days for patterns
        )

        let allItems = mealHistory.flatMap { $0.items }
        var itemCounts: [String: Int] = [:]
        allItems.forEach { itemCounts[$0.name, default: 0] += 1 }
        
        let sortedItems = itemCounts.sorted { $0.value > $1.value }
        let topItems = Array(sortedItems.prefix(5)) // Suggest top 5 frequent items
        
        let frequentFoods = topItems.compactMap { (name, _) in
            allItems.first { $0.name == name } // Get the full FoodItem object
        }
        return Array(frequentFoods)
    }

    // MARK: - Meal Management
    func deleteFoodEntry(_ entry: FoodEntry) async {
        isLoading = true
        defer { isLoading = false }
        do {
            modelContext.delete(entry)
            try modelContext.save()
            await loadTodaysData() // Refresh
            HapticManager.notification(.success)
            AppLogger.info("Deleted food entry \(entry.id.uuidString)", category: .data)
        } catch {
            setError(error)
            AppLogger.error("Failed to delete food entry: \(error.localizedDescription)", category: .data)
        }
    }

    func duplicateFoodEntry(_ entry: FoodEntry) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let duplicate = entry.duplicate() // Assuming FoodEntry has a duplicate method
            duplicate.loggedAt = currentDate // Set to current date for duplication
            user.foodEntries.append(duplicate)
            modelContext.insert(duplicate)
            try modelContext.save()
            await loadTodaysData() // Refresh
            HapticManager.notification(.success)
            AppLogger.info("Duplicated food entry \(entry.id.uuidString) to new entry \(duplicate.id.uuidString)", category: .data)
        } catch {
            setError(error)
            AppLogger.error("Failed to duplicate food entry: \(error.localizedDescription)", category: .data)
        }
    }

    // MARK: - Public Methods
    
    func setSelectedMealType(_ mealType: MealType) {
        self.selectedMealType = mealType
        // Potentially reload suggestions if they are meal-type specific
        Task {
            self.suggestedFoods = try await generateSmartSuggestions()
        }
    }
    
    /// Sets the parsed items, usually from an external source or for previewing.
    func setParsedItems(_ items: [ParsedFoodItem]) {
        self.parsedItems = items
    }

    /// Injects the nutrition service, typically after app initialization or for testing.
    func setNutritionService(_ service: NutritionServiceProtocol) async {
        self.nutritionService = service
        await loadTodaysData() // Reload data with the new service
    }
    
    /// Clears the current search results.
    func clearSearchResults() {
        self.searchResults = []
    }

    /// Sets the search results, primarily for use in previews or testing.
    /// - Parameter results: An array of `FoodDatabaseItem` to set as search results.
    func setSearchResults(_ results: [FoodDatabaseItem]) {
        self.searchResults = results
    }
}

// MARK: - Supporting Types (already defined, ensure consistency)
// ParsedFoodItem, FoodNutritionSummary, FoodTrackingError, TimeoutError, WaterUnit
// These should be consistent with their definitions elsewhere if shared, or defined here if local.
// For this exercise, assuming they are defined as previously shown or are globally accessible.

// Example: If FoodNutritionSummary is not already Sendable, make it so.
// struct FoodNutritionSummary: Sendable { ... }
