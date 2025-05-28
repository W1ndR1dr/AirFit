**Modular Sub-Document 8: Food Tracking Module (Voice-First AI-Powered Nutrition)**

**Version:** 2.1
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
- Completion of Module 1: Core Project Setup & Configuration
- Completion of Module 2: Data Layer (SwiftData Schema & Managers)
- Completion of Module 5: AI Persona Engine & CoachEngine
- Completion of Module 4: HealthKit & Context Manager (for calorie tracking)
- **CRITICAL**: Completion of Module 13: Chat Interface Module (provides VoiceInputManager)
**Date:** December 2024
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To provide an AI-powered, voice-first food tracking experience that makes nutrition logging effortless through natural language processing, barcode scanning, and intelligent meal suggestions.
*   **Responsibilities:**
    *   Voice-based food logging using Module 13's VoiceInputManager foundation
    *   AI-powered food parsing and nutrition analysis
    *   Barcode scanning with nutrition database lookup
    *   Visual meal logging with Vision framework
    *   Smart meal suggestions based on history
    *   Macro and micronutrient tracking
    *   Integration with HealthKit for calorie syncing
    *   Water intake tracking
    *   Meal planning and recipes
*   **Key Components:**
    *   `FoodTrackingCoordinator.swift` - Navigation and flow management
    *   `FoodTrackingViewModel.swift` - Business logic and state
    *   `FoodLoggingView.swift` - Main food logging interface
    *   `VoiceInputView.swift` - Voice recording UI with waveform visualization
    *   `FoodConfirmationView.swift` - AI parsing confirmation
    *   `BarcodeScannerView.swift` - Barcode scanning interface
    *   `NutritionSearchView.swift` - Food database search
    *   `MacroRingsView.swift` - Macro visualization
    *   `WaterTrackingView.swift` - Water intake logging
    *   `FoodVoiceAdapter.swift` - Adapter for Module 13's VoiceInputManager
    *   `NutritionService.swift` - Nutrition data management
    *   `FoodDatabaseService.swift` - Food database integration

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Core utilities, theme system
    *   Module 2: FoodEntry, FoodItem, CustomFood models
    *   Module 4: HealthKit integration
    *   Module 5: AI parsing capabilities
    *   **Module 13: VoiceInputManager and WhisperKit infrastructure**
    *   AVFoundation for audio recording (via Module 13)
    *   Vision framework for image analysis
    *   WhisperKit package (already configured in Module 13)
*   **Outputs:**
    *   Food and water intake data
    *   Nutrition metrics for dashboard
    *   HealthKit nutrition data
    *   Meal history and insights

**3. Voice Infrastructure Strategy**

**IMPORTANT ARCHITECTURAL DECISION:**
Module 8 leverages the superior voice infrastructure provided by Module 13 rather than implementing its own WhisperKit integration. This approach:

- ✅ Eliminates code duplication
- ✅ Ensures consistent voice experience across the app
- ✅ Leverages Module 13's optimized model management
- ✅ Reduces Module 8 implementation complexity
- ✅ Provides food-specific transcription enhancements

**Voice Integration Approach:**
1. **Foundation**: Use Module 13's `VoiceInputManager` as the core service
2. **Adaptation**: Create `FoodVoiceAdapter` for food-specific optimizations
3. **Enhancement**: Add food-specific post-processing and UI customizations
4. **Integration**: Seamless integration with food logging workflows

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 8.0: Food Tracking Infrastructure**

**Agent Task 8.0.1: Create Food Voice Adapter**
- File: `AirFit/Modules/FoodTracking/Services/FoodVoiceAdapter.swift`
- **Purpose**: Adapter pattern to wrap Module 13's VoiceInputManager with food-specific enhancements
- Complete Implementation:
  ```swift
  import Foundation
  import SwiftUI
  
  @MainActor
  final class FoodVoiceAdapter: ObservableObject {
      // MARK: - Dependencies
      private let voiceInputManager: VoiceInputManager // From Module 13
      
      // MARK: - Published State
      @Published private(set) var isRecording = false
      @Published private(set) var transcribedText = ""
      @Published private(set) var voiceWaveform: [Float] = []
      @Published private(set) var isTranscribing = false
      
      // MARK: - Callbacks
      var onFoodTranscription: ((String) -> Void)?
      var onError: ((Error) -> Void)?
      
      // MARK: - Initialization
      init(voiceInputManager: VoiceInputManager = VoiceInputManager.shared) {
          self.voiceInputManager = voiceInputManager
          setupCallbacks()
      }
      
      private func setupCallbacks() {
          // Bridge VoiceInputManager callbacks with food-specific processing
          voiceInputManager.onTranscription = { [weak self] text in
              guard let self = self else { return }
              
              // Apply food-specific post-processing
              let processedText = self.postProcessForFood(text)
              self.transcribedText = processedText
              self.onFoodTranscription?(processedText)
          }
          
          voiceInputManager.onPartialTranscription = { [weak self] text in
              guard let self = self else { return }
              self.transcribedText = text
          }
          
          voiceInputManager.onWaveformUpdate = { [weak self] levels in
              guard let self = self else { return }
              self.voiceWaveform = levels
          }
          
          voiceInputManager.onError = { [weak self] error in
              guard let self = self else { return }
              self.onError?(error)
          }
      }
      
      // MARK: - Public Methods
      func startRecording() async throws {
          isRecording = true
          try await voiceInputManager.startRecording()
      }
      
      func stopRecording() async -> String? {
          isRecording = false
          let result = await voiceInputManager.stopRecording()
          return result.map { postProcessForFood($0) }
      }
      
      func requestPermission() async throws -> Bool {
          return try await voiceInputManager.requestPermission()
      }
      
      // MARK: - Food-Specific Post-Processing
      private func postProcessForFood(_ text: String) -> String {
          var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)
          
          // Food-specific transcription improvements
          let foodCorrections: [String: String] = [
              // Quantity corrections
              "to eggs": "two eggs",
              "for slices": "four slices", 
              "won cup": "one cup",
              "tree cups": "three cups",
              "ate ounces": "eight ounces",
              
              // Food name corrections
              "chicken breast": "chicken breast",
              "sweet potato": "sweet potato",
              "greek yogurt": "Greek yogurt",
              "peanut butter": "peanut butter",
              "olive oil": "olive oil",
              
              // Measurement corrections
              "table spoon": "tablespoon",
              "tea spoon": "teaspoon",
              "fluid ounce": "fl oz",
              "pounds": "lbs"
          ]
          
          for (pattern, replacement) in foodCorrections {
              processed = processed.replacingOccurrences(
                  of: pattern,
                  with: replacement,
                  options: [.caseInsensitive]
              )
          }
          
          return processed
      }
  }
  ```

**Agent Task 8.0.2: Create Food Voice Service Protocol**
- File: `AirFit/Modules/FoodTracking/Services/FoodVoiceServiceProtocol.swift`
- **Purpose**: Clean protocol abstraction for food-specific voice operations
- Complete Implementation:
  ```swift
  import Foundation
  
  protocol FoodVoiceServiceProtocol: AnyObject {
      var isRecording: Bool { get }
      var isTranscribing: Bool { get }
      var transcribedText: String { get }
      var voiceWaveform: [Float] { get }
      
      func requestPermission() async throws -> Bool
      func startRecording() async throws
      func stopRecording() async -> String?
      
      // Food-specific callbacks
      var onFoodTranscription: ((String) -> Void)? { get set }
      var onError: ((Error) -> Void)? { get set }
  }
  
  // MARK: - FoodVoiceAdapter Protocol Conformance
  extension FoodVoiceAdapter: FoodVoiceServiceProtocol {
      // Protocol conformance is already implemented in the class
  }
  
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
  ```

**Agent Task 8.0.3: Create Food Tracking Coordinator**
- File: `AirFit/Modules/FoodTracking/FoodTrackingCoordinator.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Observation
  
  @MainActor
  @Observable
  final class FoodTrackingCoordinator {
      // MARK: - Navigation State
      var navigationPath = NavigationPath()
      var activeSheet: FoodTrackingSheet?
      var activeFullScreenCover: FoodTrackingFullScreenCover?
      
      // MARK: - Sheet Types
      enum FoodTrackingSheet: Identifiable {
          case voiceInput
          case barcodeScanner
          case foodSearch
          case manualEntry
          case waterTracking
          case mealDetails(FoodEntry)
          
          var id: String {
              switch self {
              case .voiceInput: return "voice"
              case .barcodeScanner: return "barcode"
              case .foodSearch: return "search"
              case .manualEntry: return "manual"
              case .waterTracking: return "water"
              case .mealDetails(let entry): return "meal_\(entry.id)"
              }
          }
      }
      
      // MARK: - Full Screen Cover Types
      enum FoodTrackingFullScreenCover: Identifiable {
          case camera
          case confirmation([ParsedFoodItem])
          
          var id: String {
              switch self {
              case .camera: return "camera"
              case .confirmation: return "confirmation"
              }
          }
      }
      
      // MARK: - Navigation
      func navigateTo(_ destination: FoodTrackingDestination) {
          navigationPath.append(destination)
      }
      
      func showSheet(_ sheet: FoodTrackingSheet) {
          activeSheet = sheet
      }
      
      func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
          activeFullScreenCover = cover
      }
      
      func dismiss() {
          activeSheet = nil
          activeFullScreenCover = nil
      }
      
      func pop() {
          if !navigationPath.isEmpty {
              navigationPath.removeLast()
          }
      }
      
      func popToRoot() {
          navigationPath.removeLast(navigationPath.count)
      }
  }
  
  // MARK: - Navigation Destinations
  enum FoodTrackingDestination: Hashable {
      case history
      case insights
      case favorites
      case recipes
      case mealPlan
  }
  ```

---

**Task 8.1: Food Tracking View Model**

**Agent Task 8.1.1: Create Food Tracking View Model**
- File: `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`
- Complete Implementation:
            ```swift
  import SwiftUI
  import SwiftData
  import Observation
  
  @MainActor
  @Observable
  final class FoodTrackingViewModel {
      // MARK: - Dependencies
      private let modelContext: ModelContext
      private let user: User
      private let whisperKitService: WhisperKitServiceProtocol
      private let nutritionService: NutritionServiceProtocol
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
      private(set) var todaysNutrition = NutritionSummary()
      private(set) var waterIntakeML: Double = 0
      
      // Search and suggestions
      private(set) var searchResults: [FoodDatabaseItem] = []
      private(set) var recentFoods: [FoodItem] = []
      private(set) var suggestedFoods: [FoodItem] = []
      
      // MARK: - Initialization
      init(
          modelContext: ModelContext,
          user: User,
          whisperKitService: WhisperKitServiceProtocol,
          nutritionService: NutritionServiceProtocol,
          foodDatabaseService: FoodDatabaseServiceProtocol,
          coachEngine: CoachEngine,
          coordinator: FoodTrackingCoordinator
      ) {
          self.modelContext = modelContext
          self.user = user
          self.whisperKitService = whisperKitService
          self.nutritionService = nutritionService
          self.foodDatabaseService = foodDatabaseService
          self.coachEngine = coachEngine
          self.coordinator = coordinator
          
          setupVoiceCallbacks()
      }
      
      private func setupVoiceCallbacks() {
          if let whisperService = whisperKitService as? WhisperKitService {
              whisperService.onWaveformUpdate = { [weak self] levels in
                  Task { @MainActor in
                      self?.voiceWaveform = levels
                  }
              }
              
              whisperService.onPartialTranscription = { [weak self] text in
                  Task { @MainActor in
                      self?.transcribedText = text
                  }
              }
          }
      }
      
      // MARK: - Data Loading
      func loadTodaysData() async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              // Fetch today's entries
              todaysFoodEntries = try await nutritionService.getFoodEntries(
                  for: user,
                  date: currentDate
              )
              
              // Calculate nutrition summary
              todaysNutrition = nutritionService.calculateNutritionSummary(
                  from: todaysFoodEntries
              )
              
              // Load water intake
              waterIntakeML = try await nutritionService.getWaterIntake(
                  for: user,
                  date: currentDate
              )
              
              // Load recent and suggested foods
              recentFoods = try await nutritionService.getRecentFoods(
                  for: user,
                  limit: 10
              )
              
              suggestedFoods = try await generateSmartSuggestions()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to load today's data", error: error, category: .data)
          }
      }
      
      // MARK: - Voice Input
      func startVoiceInput() async {
          // Request permission if needed
          do {
              let hasPermission = try await whisperKitService.requestPermission()
              guard hasPermission else {
                  error = TranscriptionError.permissionDenied
                  return
              }
              
              coordinator.showSheet(.voiceInput)
              
          } catch {
              self.error = error
              AppLogger.error("Failed to start voice input", error: error, category: .ui)
          }
      }
      
      func startRecording() async {
          guard !isRecording else { return }
          
          isRecording = true
          transcribedText = ""
          transcriptionConfidence = 0
          voiceWaveform = []
          
          do {
              let transcriptionStream = try await whisperKitService.startTranscription()
              
              for try await update in transcriptionStream {
                  transcribedText = update.text
                  transcriptionConfidence = update.confidence
                  
                  // Provide real-time feedback
                  if update.isPartial {
                      // Show partial transcription in UI
                      continue
                  }
                  
                  if update.isFinal {
                      await processTranscription()
                  }
              }
          } catch {
              self.error = error
              isRecording = false
              AppLogger.error("Transcription error", error: error, category: .ui)
          }
      }
      
      func stopRecording() async {
          guard isRecording else { return }
          
          isRecording = false
          
          // Get final transcription
          if let finalText = await whisperKitService.stopTranscription() {
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
              // First try local command parsing
              if let localResult = await parseLocalCommand(transcribedText) {
                  parsedItems = localResult
                  coordinator.showFullScreenCover(.confirmation(parsedItems))
                  return
              }
              
              // Use AI for complex parsing
              let aiResult = try await coachEngine.parseAndLogComplexNutrition(
                  input: transcribedText,
                  mealType: selectedMealType,
                  context: NutritionContext(
                      userPreferences: user.nutritionPreferences,
                      recentMeals: recentFoods,
                      timeOfDay: currentDate
                  )
              )
              
              parsedItems = aiResult.items
              
              // Show confirmation if items found
              if !parsedItems.isEmpty {
                  coordinator.dismiss() // Dismiss voice input
                  coordinator.showFullScreenCover(.confirmation(parsedItems))
              } else {
                  error = FoodTrackingError.noFoodsDetected
              }
              
          } catch {
              self.error = error
              AppLogger.error("Failed to process transcription", error: error, category: .ai)
          }
      }
      
      private func parseLocalCommand(_ text: String) async -> [ParsedFoodItem]? {
          let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
          
          // Simple single food patterns
          let patterns = [
              #/^(?:i had |ate |log )?(an? )?(\w+)$/#,
              #/^(\d+(?:\.\d+)?)\s*(\w+)\s+of\s+(\w+)$/#
          ]
          
          // Try simple patterns
          if let match = lowercased.firstMatch(of: patterns[0]) {
              let foodName = String(match.2)
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
      
      // MARK: - Barcode Scanning
      func startBarcodeScanning() {
          coordinator.showSheet(.barcodeScanner)
      }
      
      func processBarcodeResult(_ barcode: String) async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              if let product = try await foodDatabaseService.lookupBarcode(barcode) {
                  let parsedItem = ParsedFoodItem(
                      name: product.name,
                      brand: product.brand,
                      quantity: 1,
                      unit: product.servingUnit,
                      calories: product.calories,
                      proteinGrams: product.protein,
                      carbGrams: product.carbs,
                      fatGrams: product.fat,
                      barcode: barcode,
                      confidence: 1.0
                  )
                  
                  parsedItems = [parsedItem]
                  coordinator.dismiss()
                  coordinator.showFullScreenCover(.confirmation(parsedItems))
              } else {
                  error = FoodTrackingError.barcodeNotFound
              }
          } catch {
              self.error = error
          }
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
              // Create food entry
              let foodEntry = FoodEntry(
                  mealType: selectedMealType.rawValue,
                  loggedAt: currentDate,
                  rawTranscript: transcribedText.isEmpty ? nil : transcribedText
              )
              
              // Add food items
              for parsedItem in items {
                  let foodItem = FoodItem(
                      name: parsedItem.name,
                      brand: parsedItem.brand,
                      quantity: parsedItem.quantity,
                      unit: parsedItem.unit,
                      calories: parsedItem.calories,
                      proteinGrams: parsedItem.proteinGrams ?? 0,    // Changed from protein
                      carbGrams: parsedItem.carbGrams ?? 0,         // Changed from carbohydrates
                      fatGrams: parsedItem.fatGrams ?? 0             // Changed from fat
                  )
                  
                  // Set additional nutrition data if available
                  foodItem.fiberGrams = parsedItem.fiber
                  foodItem.sugarGrams = parsedItem.sugar
                  foodItem.sodiumMg = parsedItem.sodium
                  foodItem.barcode = parsedItem.barcode
                  
                  foodEntry.items.append(foodItem)
              }
              
              // Associate with user
              user.foodEntries.append(foodEntry)
              
              // Save to database
              modelContext.insert(foodEntry)
              try modelContext.save()
              
              // Update UI
              await loadTodaysData()
              
              // Clear state
              parsedItems = []
              transcribedText = ""
              
              // Dismiss confirmation
              coordinator.dismiss()
              
              // Show success feedback
              HapticManager.notification(.success)
              
              AppLogger.info("Saved \(items.count) food items", category: .data)
              
          } catch {
              self.error = error
              AppLogger.error("Failed to save food items", error: error, category: .data)
          }
      }
      
      // MARK: - Water Tracking
      func logWater(amount: Double, unit: WaterUnit) async {
          do {
              let amountInML = unit.toMilliliters(amount)
              
              try await nutritionService.logWaterIntake(
                  for: user,
                  amountML: amountInML,
                  date: currentDate
              )
              
              waterIntakeML += amountInML
              
              HapticManager.impact(.light)
              
          } catch {
              self.error = error
              AppLogger.error("Failed to log water", error: error, category: .data)
          }
      }
      
      // MARK: - Smart Suggestions
      private func generateSmartSuggestions() async throws -> [FoodItem] {
          // Get current context
          let hour = Calendar.current.component(.hour, from: currentDate)
          let dayOfWeek = Calendar.current.component(.weekday, from: currentDate)
          
          // Analyze patterns
          let mealHistory = try await nutritionService.getMealHistory(
              for: user,
              mealType: selectedMealType,
              daysBack: 30
          )
          
          // Find frequently eaten foods at this time
          let frequentFoods = mealHistory
              .flatMap { $0.items }
              .reduce(into: [:]) { counts, item in
                  counts[item.name, default: 0] += 1
              }
              .sorted { $0.value > $1.value }
              .prefix(5)
              .compactMap { name, _ in
                  mealHistory.flatMap { $0.items }.first { $0.name == name }
              }
          
          return Array(frequentFoods)
      }
      
      // MARK: - Meal Management
      func deleteFoodEntry(_ entry: FoodEntry) async {
          do {
              modelContext.delete(entry)
              try modelContext.save()
              await loadTodaysData()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to delete food entry", error: error, category: .data)
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
              self.error = error
              AppLogger.error("Failed to duplicate food entry", error: error, category: .data)
          }
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
      var proteinGrams: Double?  // Changed from protein
      var carbGrams: Double?     // Changed from carbs
      var fatGrams: Double?      // Changed from fat
      var fiber: Double?
      var sugar: Double?
      var sodium: Double?
      var barcode: String?
      var databaseId: String?
      var confidence: Float
  }
  
  struct NutritionSummary: Sendable {
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
      case barcodeNotFound
      case saveFailed
      
      var errorDescription: String? {
          switch self {
          case .noFoodsDetected:
              return "No foods detected in your description"
          case .barcodeNotFound:
              return "Product not found in database"
          case .saveFailed:
              return "Failed to save food entry"
          }
      }
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
  ```

---

**Task 8.2: Main Food Tracking Views**

**Agent Task 8.2.1: Create Food Logging View**
- File: `AirFit/Modules/FoodTracking/Views/FoodLoggingView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct FoodLoggingView: View {
      @StateObject private var viewModel: FoodTrackingViewModel
      @StateObject private var coordinator: FoodTrackingCoordinator
      @Environment(\.dismiss) private var dismiss
      
      init(user: User, modelContext: ModelContext) {
          let coordinator = FoodTrackingCoordinator()
          let viewModel = FoodTrackingViewModel(
              modelContext: modelContext,
              user: user,
              whisperService: WhisperService(),
              nutritionService: NutritionService(modelContext: modelContext),
              foodDatabaseService: FoodDatabaseService(),
              coachEngine: CoachEngine.shared,
              coordinator: coordinator
          )
          
          _viewModel = StateObject(wrappedValue: viewModel)
          _coordinator = StateObject(wrappedValue: coordinator)
      }
      
      var body: some View {
          NavigationStack(path: $coordinator.navigationPath) {
              ScrollView {
                  VStack(spacing: 0) {
                      // Date selector
                      datePicker
                      
                      // Macro summary
                      macroSummaryCard
                          .padding(.horizontal)
                          .padding(.top, AppSpacing.md)
                      
                      // Quick actions
                      quickActionsSection
                          .padding(.horizontal)
                          .padding(.top, AppSpacing.lg)
                      
                      // Today's meals
                      mealsSection
                          .padding(.horizontal)
                          .padding(.top, AppSpacing.lg)
                      
                      // Suggestions
                      if !viewModel.suggestedFoods.isEmpty {
                          suggestionsSection
                              .padding(.top, AppSpacing.lg)
                      }
                  }
                  .padding(.bottom, AppSpacing.xl)
              }
              .background(Color.backgroundPrimary)
              .navigationTitle("Food Tracking")
              .navigationBarTitleDisplayMode(.large)
              .toolbar {
                  ToolbarItem(placement: .topBarTrailing) {
                      Button("Done") { dismiss() }
                  }
              }
              .navigationDestination(for: FoodTrackingDestination.self) { destination in
                  destinationView(for: destination)
              }
              .sheet(item: $coordinator.activeSheet) { sheet in
                  sheetView(for: sheet)
              }
              .fullScreenCover(item: $coordinator.activeFullScreenCover) { cover in
                  fullScreenView(for: cover)
              }
              .task {
                  await viewModel.loadTodaysData()
              }
              .refreshable {
                  await viewModel.loadTodaysData()
              }
              .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                  Button("OK") { viewModel.error = nil }
              } message: {
                  if let error = viewModel.error {
                      Text(error.localizedDescription)
                  }
              }
          }
      }
      
      // MARK: - Date Picker
      private var datePicker: some View {
          HStack {
              Button(action: previousDay) {
                  Image(systemName: "chevron.left")
                      .font(.title3)
                      .foregroundStyle(.secondary)
              }
              
              Spacer()
              
              Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                  .font(.headline)
              
              Spacer()
              
              Button(action: nextDay) {
                  Image(systemName: "chevron.right")
                      .font(.title3)
                      .foregroundStyle(.secondary)
              }
              .disabled(Calendar.current.isDateInToday(viewModel.currentDate))
          }
          .padding(.horizontal)
          .padding(.vertical, AppSpacing.sm)
          .background(Color.cardBackground)
      }
      
      // MARK: - Macro Summary
      private var macroSummaryCard: some View {
          Card {
              VStack(spacing: AppSpacing.md) {
                  HStack {
                      Text("Today's Nutrition")
                          .font(.headline)
                      Spacer()
                      NavigationLink(value: FoodTrackingDestination.insights) {
                          Text("Details")
                          .font(.subheadline)
                          .foregroundStyle(.accent)
                      }
                  }
                  
                  MacroRingsView(
                      nutrition: viewModel.todaysNutrition,
                      style: .compact
                  )
                  
                  // Calorie text
                  HStack {
                      Image(systemName: "flame.fill")
                          .foregroundStyle(.orange)
                      Text("\(Int(viewModel.todaysNutrition.calories)) / \(Int(viewModel.todaysNutrition.calorieGoal)) cal")
                          .font(.callout)
                          .fontWeight(.medium)
                      Spacer()
                      
                      // Water intake
                      Image(systemName: "drop.fill")
                          .foregroundStyle(.blue)
                      Text("\(Int(viewModel.waterIntakeML)) ml")
                          .font(.callout)
                          .fontWeight(.medium)
                  }
              }
          }
      }
      
      // MARK: - Quick Actions
      private var quickActionsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Quick Add", icon: "plus.circle.fill")
              
              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: AppSpacing.md) {
                      QuickActionButton(
                          title: "Voice",
                          icon: "mic.fill",
                          color: .accent
                      ) {
                          Task { await viewModel.startVoiceInput() }
                      }
                      
                      QuickActionButton(
                          title: "Barcode",
                          icon: "barcode.viewfinder",
                          color: .orange
                      ) {
                          viewModel.startBarcodeScanning()
                      }
                      
                      QuickActionButton(
                          title: "Search",
                          icon: "magnifyingglass",
                          color: .green
                      ) {
                          coordinator.showSheet(.foodSearch)
                      }
                      
                      QuickActionButton(
                          title: "Water",
                          icon: "drop.fill",
                          color: .blue
                      ) {
                          coordinator.showSheet(.waterTracking)
                      }
                      
                      QuickActionButton(
                          title: "Manual",
                          icon: "square.and.pencil",
                          color: .purple
                      ) {
                          coordinator.showSheet(.manualEntry)
                      }
                  }
              }
          }
      }
      
      // MARK: - Meals Section
      private var mealsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Today's Meals", icon: "fork.knife")
              
              VStack(spacing: AppSpacing.md) {
                  ForEach(MealType.allCases) { mealType in
                      MealCard(
                          mealType: mealType,
                          entries: viewModel.todaysFoodEntries.filter { $0.mealType == mealType.rawValue },
                          onAdd: {
                              viewModel.selectedMealType = mealType
                              Task { await viewModel.startVoiceInput() }
                          },
                          onTapEntry: { entry in
                              coordinator.showSheet(.mealDetails(entry))
                          }
                      )
                  }
              }
          }
      }
      
      // MARK: - Suggestions Section
      private var suggestionsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Quick Add Favorites", icon: "star.fill")
                  .padding(.horizontal)
              
              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: AppSpacing.md) {
                      ForEach(viewModel.suggestedFoods) { food in
                          SuggestionCard(food: food) {
                              selectSuggestedFood(food)
                          }
                      }
                  }
                  .padding(.horizontal)
              }
          }
      }
      
      // MARK: - Actions
      private func previousDay() {
          withAnimation {
              viewModel.currentDate = Calendar.current.date(
                  byAdding: .day,
                  value: -1,
                  to: viewModel.currentDate
              ) ?? viewModel.currentDate
          }
          Task { await viewModel.loadTodaysData() }
      }
      
      private func nextDay() {
          withAnimation {
              viewModel.currentDate = Calendar.current.date(
                  byAdding: .day,
                  value: 1,
                  to: viewModel.currentDate
              ) ?? viewModel.currentDate
          }
          Task { await viewModel.loadTodaysData() }
      }
      
      private func selectSuggestedFood(_ food: FoodItem) {
          let parsed = ParsedFoodItem(
              name: food.name,
              brand: food.brand,
              quantity: food.quantity,
              unit: food.unit,
              calories: food.calories,
              proteinGrams: food.proteinGrams,    // Changed from protein
              carbGrams: food.carbGrams,         // Changed from carbohydrates
              fatGrams: food.fatGrams,            // Changed from fat
              confidence: 1.0
          )
          viewModel.parsedItems = [parsed]
          coordinator.showFullScreenCover(.confirmation([parsed]))
      }
      
      // MARK: - Navigation
      @ViewBuilder
      private func destinationView(for destination: FoodTrackingDestination) -> some View {
          switch destination {
          case .history:
              FoodHistoryView(viewModel: viewModel)
          case .insights:
              NutritionInsightsView(viewModel: viewModel)
          case .favorites:
              FavoriteFoodsView(viewModel: viewModel)
          case .recipes:
              RecipesView(viewModel: viewModel)
          case .mealPlan:
              MealPlanView(viewModel: viewModel)
          }
      }
      
      @ViewBuilder
      private func sheetView(for sheet: FoodTrackingCoordinator.FoodTrackingSheet) -> some View {
          switch sheet {
          case .voiceInput:
              VoiceInputView(viewModel: viewModel)
          case .barcodeScanner:
              BarcodeScannerView(viewModel: viewModel)
          case .foodSearch:
              NutritionSearchView(viewModel: viewModel)
          case .manualEntry:
              ManualFoodEntryView(viewModel: viewModel)
          case .waterTracking:
              WaterTrackingView(viewModel: viewModel)
          case .mealDetails(let entry):
              MealDetailsView(entry: entry, viewModel: viewModel)
          }
      }
      
      @ViewBuilder
      private func fullScreenView(for cover: FoodTrackingCoordinator.FoodTrackingFullScreenCover) -> some View {
          switch cover {
          case .camera:
              CameraFoodScanView(viewModel: viewModel)
          case .confirmation(let items):
              FoodConfirmationView(items: items, viewModel: viewModel)
          }
      }
  }
  
  // MARK: - Supporting Views
  struct QuickActionButton: View {
      let title: String
      let icon: String
      let color: Color
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              VStack(spacing: AppSpacing.xs) {
                  Image(systemName: icon)
                      .font(.title2)
                      .foregroundStyle(.white)
                  
                  Text(title)
                      .font(.caption)
                      .foregroundStyle(.primary)
              }
          }
      }
  }
  
  struct MealCard: View {
      let mealType: MealType
      let entries: [FoodEntry]
      let onAdd: () -> Void
      let onTapEntry: (FoodEntry) -> Void
      
      private var totalCalories: Int {
          entries.flatMap { $0.items }.reduce(0) { $0 + Int($1.calories) }
      }
      
      var body: some View {
          Card {
              VStack(alignment: .leading, spacing: AppSpacing.sm) {
                  HStack {
                      Label(mealType.displayName, systemImage: mealType.icon)
                          .font(.headline)
                      
                      Spacer()
                      
                      if !entries.isEmpty {
                          Text("\(totalCalories) cal")
                              .font(.subheadline)
                              .foregroundStyle(.secondary)
                      }
                      
                      Button(action: onAdd) {
                          Image(systemName: "plus.circle.fill")
                              .foregroundStyle(.accent)
                      }
                  }
                  
                  if !entries.isEmpty {
                      Divider()
                      
                      VStack(alignment: .leading, spacing: AppSpacing.xs) {
                          ForEach(entries) { entry in
                              Button(action: { onTapEntry(entry) }) {
                                  HStack {
                                      Text(entry.displayName)
                                          .font(.callout)
                                          .foregroundStyle(.primary)
                                      Spacer()
                                      Text("\(entry.totalCalories) cal")
                                          .font(.caption)
                                          .foregroundStyle(.secondary)
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
  }
  
  struct SuggestionCard: View {
      let food: FoodItem
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              VStack(alignment: .leading, spacing: AppSpacing.xs) {
                  Text(food.name)
                      .font(.callout)
                      .fontWeight(.medium)
                      .lineLimit(1)
                  
                  HStack(spacing: AppSpacing.xs) {
                      Text("\(Int(food.calories)) cal")
                      Text("•")
                      Text(food.displayQuantity)
                  }
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding()
              .frame(width: 140)
              .background(Color.cardBackground)
              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
          }
      }
  }
  ```

**Agent Task 8.2.2: Create Voice Input View**
- File: `AirFit/Modules/FoodTracking/Views/VoiceInputView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import AVFoundation
  
  struct VoiceInputView: View {
      @ObservedObject var viewModel: FoodTrackingViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var pulseAnimation = false
      @State private var audioLevel: Float = 0
      
      private let audioLevelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
      
      var body: some View {
          NavigationStack {
              VStack(spacing: 0) {
                  // Instructions
                  instructionsSection
                  
                  Spacer()
                  
                  // Microphone button
                  microphoneButton
                  
                  // Transcription display
                  transcriptionSection
                  
                  Spacer()
                  
                  // Status
                  statusSection
              }
              .padding()
              .background(Color.backgroundPrimary)
              .navigationTitle("Voice Input")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Cancel") { dismiss() }
                  }
              }
              .onReceive(audioLevelTimer) { _ in
                  updateAudioLevel()
              }
          }
      }
      
      private var instructionsSection: some View {
          VStack(spacing: AppSpacing.sm) {
              Text("Tell me what you ate")
                  .font(.title2)
                  .fontWeight(.semibold)
              
              Text("Hold the button and describe your meal")
                  .font(.callout)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
              
              // Examples
              VStack(alignment: .leading, spacing: AppSpacing.xs) {
                  ExampleText("\"I had a chicken salad with ranch dressing\"")
                  ExampleText("\"Two eggs, toast, and orange juice\"")
                  ExampleText("\"Large pepperoni pizza, about 3 slices\"")
              }
              .padding()
              .background(Color.secondaryBackground)
              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
              .padding(.top)
          }
      }
      
      private var microphoneButton: some View {
          ZStack {
              // Pulse animation circles
              if viewModel.isRecording {
                  Circle()
                      .fill(Color.accent.opacity(0.2))
                      .frame(width: 200, height: 200)
                      .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                      .animation(
                          .easeInOut(duration: 1.5)
                          .repeatForever(autoreverses: true),
                          value: pulseAnimation
                      )
                  
                  Circle()
                      .fill(Color.accent.opacity(0.1))
                      .frame(width: 240, height: 240)
                      .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                      .animation(
                          .easeInOut(duration: 1.5)
                          .delay(0.2)
                          .repeatForever(autoreverses: true),
                          value: pulseAnimation
                      )
              }
              
              // Main button
              Button(action: {}) {
                  ZStack {
                      Circle()
                          .fill(viewModel.isRecording ? Color.red : Color.accent)
                          .frame(width: 120, height: 120)
                      
                      Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                          .font(.system(size: 40))
                          .foregroundStyle(.white)
                      
                      // Audio level indicator
                      if viewModel.isRecording {
                          Circle()
                              .stroke(Color.white.opacity(0.8), lineWidth: 4)
                              .frame(width: 120 + CGFloat(audioLevel * 40), height: 120 + CGFloat(audioLevel * 40))
                              .animation(.easeOut(duration: 0.1), value: audioLevel)
                      }
                  }
              }
              .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
              .onLongPressGesture(
                  minimumDuration: 0.01,
                  maximumDistance: .infinity,
                  pressing: { isPressing in
                      handlePressing(isPressing)
                  },
                  perform: {}
              )
          }
          .frame(height: 300)
          .onAppear {
              if viewModel.isRecording {
                  pulseAnimation = true
              }
          }
      }
      
      private var transcriptionSection: some View {
          Group {
              if !viewModel.transcribedText.isEmpty {
                  VStack(spacing: AppSpacing.sm) {
                      HStack {
                          Text("Transcript")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                          
                          if viewModel.transcriptionConfidence > 0 {
                              ConfidenceIndicator(confidence: viewModel.transcriptionConfidence)
                          }
                          
                          Spacer()
                      }
                      
                      Text(viewModel.transcribedText)
                          .font(.body)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .padding()
                          .background(Color.cardBackground)
                          .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                  }
                  .transition(.opacity.combined(with: .scale))
              }
          }
          .animation(.spring(response: 0.3), value: viewModel.transcribedText)
      }
      
      private var statusSection: some View {
          HStack(spacing: AppSpacing.sm) {
              if viewModel.isRecording {
                  Image(systemName: "dot.radiowaves.left.and.right")
                      .foregroundStyle(.red)
                      .symbolEffect(.pulse)
                  Text("Listening...")
                      .foregroundStyle(.red)
              } else if viewModel.isProcessingAI {
                  ProgressView()
                      .controlSize(.small)
                  Text("Processing...")
                      .foregroundStyle(.secondary)
              } else {
                  Image(systemName: "info.circle")
                      .foregroundStyle(.secondary)
                  Text("Hold button to record")
                      .foregroundStyle(.secondary)
              }
          }
          .font(.caption)
          .frame(height: 44)
      }
      
      private func handlePressing(_ isPressing: Bool) {
          if isPressing && !viewModel.isRecording {
              // Start recording
              Task {
                  await viewModel.startRecording()
                  withAnimation {
                      pulseAnimation = true
                  }
              }
              HapticManager.impact(.medium)
          } else if !isPressing && viewModel.isRecording {
              // Stop recording
              Task {
                  await viewModel.stopRecording()
                  withAnimation {
                      pulseAnimation = false
                  }
              }
              HapticManager.impact(.light)
          }
      }
      
      private func updateAudioLevel() {
          // Simulate audio level for now
          if viewModel.isRecording {
              audioLevel = Float.random(in: 0.1...0.8)
          } else {
              audioLevel = 0
          }
      }
  }
  
  struct ExampleText: View {
      let text: String
      
      init(_ text: String) {
          self.text = text
      }
      
      var body: some View {
          HStack {
              Image(systemName: "quote.opening")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              Text(text)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .italic()
          }
      }
  }
  
  struct ConfidenceIndicator: View {
      let confidence: Float
      
      private var color: Color {
          if confidence > 0.8 { return .green }
          if confidence > 0.6 { return .yellow }
          return .orange
      }
      
      var body: some View {
          HStack(spacing: 2) {
              ForEach(0..<3) { index in
                  RoundedRectangle(cornerRadius: 2)
                      .fill(index < Int(confidence * 3) ? color : Color.gray.opacity(0.3))
                      .frame(width: 3, height: 8)
              }
          }
      }
  }
  ```

---

**Task 8.3: Food Confirmation and Search Views**

**Agent Task 8.3.1: Create Food Confirmation View**
- File: `AirFit/Modules/FoodTracking/Views/FoodConfirmationView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct FoodConfirmationView: View {
      @State private var items: [ParsedFoodItem]
      @ObservedObject var viewModel: FoodTrackingViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var editingItem: ParsedFoodItem?
      @State private var showAddItem = false
      
      init(items: [ParsedFoodItem], viewModel: FoodTrackingViewModel) {
          _items = State(initialValue: items)
          self.viewModel = viewModel
      }
      
      var body: some View {
          NavigationStack {
              VStack(spacing: 0) {
                  // Header with meal type
                  mealTypeHeader
                  
                  // Items list
                  ScrollView {
                      VStack(spacing: AppSpacing.md) {
                          ForEach($items) { $item in
                              FoodItemCard(
                                  item: item,
                                  onEdit: { editingItem = item },
                                  onDelete: { deleteItem(item) }
                              )
                          }
                          
                          // Add item button
                          Button(action: { showAddItem = true }) {
                              Label("Add Item", systemImage: "plus.circle.fill")
                                  .frame(maxWidth: .infinity)
                          }
                          .buttonStyle(.bordered)
                          .padding(.top)
                      }
                      .padding()
                  }
                  
                  // Nutrition summary
                  nutritionSummary
                  
                  // Action buttons
                  actionButtons
              }
              .background(Color.backgroundPrimary)
              .navigationTitle("Confirm Food")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Cancel") { dismiss() }
                  }
              }
              .sheet(item: $editingItem) { item in
                  FoodItemEditView(item: item) { updatedItem in
                      if let index = items.firstIndex(where: { $0.id == item.id }) {
                          items[index] = updatedItem
                      }
                  }
              }
              .sheet(isPresented: $showAddItem) {
                  ManualFoodEntryView(viewModel: viewModel) { newItem in
                      items.append(newItem)
                  }
              }
          }
      }
      
      private var mealTypeHeader: some View {
          HStack {
              Label(viewModel.selectedMealType.displayName, systemImage: viewModel.selectedMealType.icon)
                  .font(.headline)
              
              Spacer()
              
              Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
          }
          .padding()
          .background(Color.cardBackground)
      }
      
      private var nutritionSummary: some View {
          VStack(spacing: AppSpacing.sm) {
              Divider()
              
              HStack {
                  Text("Total")
                      .font(.headline)
                  
                  Spacer()
                  
                  HStack(spacing: AppSpacing.lg) {
                      NutrientLabel(value: totalCalories, unit: "cal", color: .orange)
                      NutrientLabel(value: totalProtein, unit: "g", label: "P", color: .proteinColor)
                      NutrientLabel(value: totalCarbs, unit: "g", label: "C", color: .carbsColor)
                      NutrientLabel(value: totalFat, unit: "g", label: "F", color: .fatColor)
                  }
                  .font(.callout)
              }
              .padding()
          }
          .background(Color.cardBackground)
      }
      
      private var actionButtons: some View {
          HStack(spacing: AppSpacing.md) {
              Button(action: { dismiss() }) {
                  Text("Cancel")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.secondary)
              
              Button(action: saveItems) {
                  Label("Save", systemImage: "checkmark.circle.fill")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.primaryProminent)
              .disabled(items.isEmpty)
          }
          .padding()
          .background(Color.cardBackground)
      }
      
      // MARK: - Computed Properties
      private var totalCalories: Double {
          items.reduce(0) { $0 + $1.calories }
      }
      
      private var totalProtein: Double {
          items.reduce(0) { $0 + ($1.proteinGrams ?? 0) }
      }
      
      private var totalCarbs: Double {
          items.reduce(0) { $0 + ($1.carbGrams ?? 0) }
      }
      
      private var totalFat: Double {
          items.reduce(0) { $0 + ($1.fatGrams ?? 0) }
      }
      
      // MARK: - Actions
      private func deleteItem(_ item: ParsedFoodItem) {
          withAnimation {
              items.removeAll { $0.id == item.id }
          }
          HapticManager.impact(.light)
      }
      
      private func saveItems() {
          Task {
              await viewModel.confirmAndSaveFoodItems(items)
              dismiss()
          }
      }
  }
  
  // MARK: - Supporting Views
  struct FoodItemCard: View {
      let item: ParsedFoodItem
      let onEdit: () -> Void
      let onDelete: () -> Void
      
      var body: some View {
          Card {
              VStack(alignment: .leading, spacing: AppSpacing.sm) {
                  HStack {
                      VStack(alignment: .leading, spacing: AppSpacing.xs) {
                          Text(item.name)
                              .font(.headline)
                          
                          HStack {
                              Text("\(item.quantity.formatted()) \(item.unit)")
                                  .font(.subheadline)
                                  .foregroundStyle(.secondary)
                              
                              if let brand = item.brand {
                                  Text("• \(brand)")
                                      .font(.subheadline)
                                      .foregroundStyle(.secondary)
                              }
                              
                              if item.confidence < 0.8 {
                                  Image(systemName: "exclamationmark.triangle.fill")
                                      .font(.caption)
                                      .foregroundStyle(.yellow)
                              }
                          }
                      }
                      
                      Spacer()
                      
                      Menu {
                          Button(action: onEdit) {
                              Label("Edit", systemImage: "pencil")
                          }
                          
                          Button(role: .destructive, action: onDelete) {
                              Label("Delete", systemImage: "trash")
                          }
                      } label: {
                          Image(systemName: "ellipsis")
                              .font(.body)
                              .foregroundStyle(.secondary)
                              .frame(width: 44, height: 44)
                      }
                  }
                  
                  Divider()
                  
                  HStack(spacing: AppSpacing.lg) {
                      NutrientLabel(value: item.calories, unit: "cal", color: .orange)
                      if let protein = item.proteinGrams {
                          NutrientLabel(value: protein, unit: "g", label: "Protein", color: .proteinColor)
                      }
                      if let carbs = item.carbGrams {
                          NutrientLabel(value: carbs, unit: "g", label: "Carbs", color: .carbsColor)
                      }
                      if let fat = item.fatGrams {
                          NutrientLabel(value: fat, unit: "g", label: "Fat", color: .fatColor)
                      }
                  }
                  .font(.caption)
              }
          }
      }
  }
  
  struct NutrientLabel: View {
      let value: Double
      let unit: String
      var label: String? = nil
      let color: Color
      
      var body: some View {
          HStack(spacing: 2) {
              if let label = label {
                  Text(label)
                      .foregroundStyle(color)
              }
              Text("\(value.formatted()) \(unit)")
                  .fontWeight(.medium)
          }
      }
  }
  ```

**Agent Task 8.3.2: Create Nutrition Search View**
- File: `AirFit/Modules/FoodTracking/Views/NutritionSearchView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct NutritionSearchView: View {
      @ObservedObject var viewModel: FoodTrackingViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var searchText = ""
      @FocusState private var isSearchFocused: Bool
      @State private var showRecent = true
      
      var body: some View {
          NavigationStack {
              VStack(spacing: 0) {
                  // Search bar
                  searchBar
                  
                  // Content
                  ScrollView {
                      VStack(alignment: .leading, spacing: AppSpacing.lg) {
                          if searchText.isEmpty && showRecent {
                              recentSection
                          } else {
                              searchResultsSection
                          }
                      }
                      .padding()
                  }
              }
              .background(Color.backgroundPrimary)
              .navigationTitle("Search Food")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Cancel") { dismiss() }
                  }
              }
              .onAppear {
                  isSearchFocused = true
              }
          }
      }
      
      private var searchBar: some View {
          HStack(spacing: AppSpacing.sm) {
              Image(systemName: "magnifyingglass")
                  .foregroundStyle(.secondary)
              
              TextField("Search foods...", text: $searchText)
                  .textFieldStyle(.plain)
                  .focused($isSearchFocused)
                  .autocorrectionDisabled()
                  .onSubmit {
                      performSearch()
                  }
              
              if !searchText.isEmpty {
                  Button(action: { searchText = "" }) {
                      Image(systemName: "xmark.circle.fill")
                          .foregroundStyle(.secondary)
                  }
              }
          }
          .padding()
          .background(Color.cardBackground)
          .onChange(of: searchText) { _, newValue in
              if !newValue.isEmpty {
                  performSearch()
              }
          }
      }
      
      private var recentSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Recent Foods", icon: "clock")
              
              if viewModel.recentFoods.isEmpty {
                  EmptyStateView(
                      icon: "clock",
                      title: "No Recent Foods",
                      message: "Foods you've logged will appear here"
                  )
              } else {
                  VStack(spacing: AppSpacing.sm) {
                      ForEach(viewModel.recentFoods) { food in
                          FoodSearchRow(
                              name: food.name,
                              brand: food.brand,
                              calories: food.calories,
                              serving: "\(food.quantity.formatted()) \(food.unit)"
                          ) {
                              selectRecentFood(food)
                          }
                      }
                  }
              }
          }
      }
      
      private var searchResultsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              if viewModel.isLoading {
                  HStack {
                      ProgressView()
                      Text("Searching...")
                          .foregroundStyle(.secondary)
                  }
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.vertical, 40)
              } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                  EmptyStateView(
                      icon: "magnifyingglass",
                      title: "No Results",
                      message: "Try searching with different keywords"
                  )
              } else {
                  VStack(spacing: AppSpacing.sm) {
                      ForEach(viewModel.searchResults) { result in
                          FoodSearchRow(
                              name: result.name,
                              brand: result.brand,
                              calories: result.caloriesPerServing,
                              serving: result.servingDescription
                          ) {
                              viewModel.selectSearchResult(result)
                              dismiss()
                          }
                      }
                  }
              }
          }
      }
      
      private func performSearch() {
          Task {
              await viewModel.searchFoods(searchText)
          }
      }
      
      private func selectRecentFood(_ food: FoodItem) {
          let parsed = ParsedFoodItem(
              name: food.name,
              brand: food.brand,
              quantity: food.quantity,
              unit: food.unit,
              calories: food.calories,
              proteinGrams: food.proteinGrams,
              carbGrams: food.carbGrams,
              fatGrams: food.fatGrams,
              confidence: 1.0
          )
          viewModel.parsedItems = [parsed]
          dismiss()
          viewModel.coordinator.showFullScreenCover(.confirmation([parsed]))
      }
  }
  
  struct FoodSearchRow: View {
      let name: String
      let brand: String?
      let calories: Double
      let serving: String
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              HStack {
                  VStack(alignment: .leading, spacing: AppSpacing.xs) {
                      Text(name)
                          .font(.body)
                          .foregroundStyle(.primary)
                      
                      HStack {
                          if let brand = brand {
                              Text(brand)
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                              Text("•")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                          Text(serving)
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                  }
                  
                  Spacer()
                  
                  Text("\(Int(calories)) cal")
                      .font(.callout)
                      .fontWeight(.medium)
                      .foregroundStyle(.orange)
                  
                  Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundStyle(.quaternary)
              }
              .padding(.vertical, AppSpacing.sm)
          }
          .buttonStyle(.plain)
          
          Divider()
      }
  }
  ```

---

**Task 8.4: Supporting Components**

**Agent Task 8.4.1: Create Macro Rings View**
- File: `AirFit/Modules/FoodTracking/Views/MacroRingsView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct MacroRingsView: View {
      let nutrition: NutritionSummary
      var style: Style = .full
      
      enum Style {
          case full
          case compact
      }
      
      private let ringWidth: CGFloat = 12
      
      var body: some View {
          switch style {
          case .full:
              fullView
          case .compact:
              compactView
          }
      }
      
      private var fullView: some View {
          VStack(spacing: AppSpacing.lg) {
              // Rings
              ZStack {
                  MacroRing(
                      progress: nutrition.proteinProgress,
                      color: .proteinColor,
                      radius: 80
                  )
                  
                  MacroRing(
                      progress: nutrition.carbProgress,
                      color: .carbsColor,
                      radius: 60
                  )
                  
                  MacroRing(
                      progress: nutrition.fatProgress,
                      color: .fatColor,
                      radius: 40
                  )
                  
                  // Center calories
                  VStack(spacing: 2) {
                      Text("\(Int(nutrition.calories))")
                          .font(.title2)
                          .fontWeight(.bold)
                      Text("cal")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
              }
              .frame(height: 180)
              
              // Legend
              HStack(spacing: AppSpacing.xl) {
                  MacroLegendItem(
                      title: "Protein",
                      value: nutrition.protein,
                      goal: nutrition.proteinGoal,
                      color: .proteinColor
                  )
                  
                  MacroLegendItem(
                      title: "Carbs",
                      value: nutrition.carbs,
                      goal: nutrition.carbGoal,
                      color: .carbsColor
                  )
                  
                  MacroLegendItem(
                      title: "Fat",
                      value: nutrition.fat,
                      goal: nutrition.fatGoal,
                      color: .fatColor
                  )
              }
          }
      }
      
      private var compactView: some View {
          HStack(spacing: AppSpacing.lg) {
              // Mini rings
              HStack(spacing: AppSpacing.md) {
                  MiniMacroRing(
                      progress: nutrition.proteinProgress,
                      color: .proteinColor,
                      value: nutrition.protein,
                      label: "P"
                  )
                  
                  MiniMacroRing(
                      progress: nutrition.carbProgress,
                      color: .carbsColor,
                      value: nutrition.carbs,
                      label: "C"
                  )
                  
                  MiniMacroRing(
                      progress: nutrition.fatProgress,
                      color: .fatColor,
                      value: nutrition.fat,
                      label: "F"
                  )
              }
          }
      }
  }
  
  struct MacroRing: View {
      let progress: Double
      let color: Color
      let radius: CGFloat
      private let ringWidth: CGFloat = 12
      
      var body: some View {
          ZStack {
              // Background ring
              Circle()
                  .stroke(color.opacity(0.2), lineWidth: ringWidth)
                  .frame(width: radius * 2, height: radius * 2)
              
              // Progress ring
              Circle()
                  .trim(from: 0, to: min(progress, 1.0))
                  .stroke(
                      color.gradient,
                      style: StrokeStyle(
                          lineWidth: ringWidth,
                          lineCap: .round
                      )
                  )
                  .frame(width: radius * 2, height: radius * 2)
                  .rotationEffect(.degrees(-90))
                  .animation(.spring(response: 0.6), value: progress)
              
              // Overage indicator
              if progress > 1.0 {
                  Circle()
                      .trim(from: 0, to: min(progress - 1.0, 1.0))
                      .stroke(
                          color.opacity(0.6),
                          style: StrokeStyle(
                              lineWidth: ringWidth,
                              lineCap: .round,
                              dash: [5, 3]
                          )
                      )
                      .frame(width: radius * 2, height: radius * 2)
                      .rotationEffect(.degrees(-90))
              }
          }
      }
  }
  
  struct MiniMacroRing: View {
      let progress: Double
      let color: Color
      let value: Double
      let label: String
      
      var body: some View {
          VStack(spacing: AppSpacing.xs) {
              ZStack {
                  Circle()
                      .stroke(color.opacity(0.2), lineWidth: 6)
                      .frame(width: 44, height: 44)
                  
                  Circle()
                      .trim(from: 0, to: min(progress, 1.0))
                      .stroke(
                          color.gradient,
                          style: StrokeStyle(lineWidth: 6, lineCap: .round)
                      )
                      .frame(width: 44, height: 44)
                      .rotationEffect(.degrees(-90))
                  
                  Text(label)
                      .font(.caption)
                      .fontWeight(.bold)
                      .foregroundStyle(color)
              }
              
              Text("\(Int(value))g")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
          }
      }
  }
  
  struct MacroLegendItem: View {
      let title: String
      let value: Double
      let goal: Double
      let color: Color
      
      var body: some View {
          VStack(spacing: AppSpacing.xs) {
              HStack(spacing: 4) {
                  Circle()
                      .fill(color)
                      .frame(width: 8, height: 8)
                  Text(title)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              
              Text("\(Int(value))/\(Int(goal))g")
                  .font(.caption)
                  .fontWeight(.medium)
          }
      }
  }
  ```

**Agent Task 8.4.2: Create Water Tracking View**
- File: `AirFit/Modules/FoodTracking/Views/WaterTrackingView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct WaterTrackingView: View {
      @ObservedObject var viewModel: FoodTrackingViewModel
      @Environment(\.dismiss) private var dismiss
      @State private var selectedAmount: Double = 250
      @State private var selectedUnit: WaterUnit = .ml
      @State private var customAmount = ""
      @State private var useCustom = false
      
      private let quickAmounts: [Double] = [250, 500, 750, 1000]
      
      var body: some View {
          NavigationStack {
              VStack(spacing: 0) {
                  // Current intake
                  currentIntakeSection
                  
                  ScrollView {
                      VStack(spacing: AppSpacing.xl) {
                          // Quick add buttons
                          quickAddSection
                          
                          // Custom amount
                          customAmountSection
                          
                          // Unit selector
                          unitSelector
                      }
                      .padding()
                  }
                  
                  // Add button
                  addButton
              }
              .background(Color.backgroundPrimary)
              .navigationTitle("Water Intake")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Done") { dismiss() }
                  }
              }
          }
      }
      
      private var currentIntakeSection: some View {
          VStack(spacing: AppSpacing.md) {
              // Water drop animation
              ZStack {
                  // Background circle
                  Circle()
                      .fill(Color.blue.opacity(0.1))
                      .frame(width: 120, height: 120)
                  
                  // Progress ring
                  Circle()
                      .trim(from: 0, to: min(viewModel.waterIntakeML / 2000, 1.0))
                      .stroke(
                          Color.blue.gradient,
                          style: StrokeStyle(lineWidth: 12, lineCap: .round)
                      )
                      .frame(width: 120, height: 120)
                      .rotationEffect(.degrees(-90))
                      .animation(.spring(response: 0.6), value: viewModel.waterIntakeML)
                  
                  // Water drop icon
                  Image(systemName: "drop.fill")
                      .font(.system(size: 40))
                      .foregroundStyle(.blue)
              }
              
              // Text
              VStack(spacing: AppSpacing.xs) {
                  Text("\(Int(viewModel.waterIntakeML)) ml")
                      .font(.title2)
                      .fontWeight(.bold)
                  
                  Text("Daily Goal: 2000 ml")
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.cardBackground)
      }
      
      private var quickAddSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Quick Add", icon: "plus.circle.fill")
              
              LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                  ForEach(quickAmounts, id: \.self) { amount in
                      QuickWaterButton(
                          amount: amount,
                          unit: selectedUnit,
                          isSelected: !useCustom && selectedAmount == amount
                      ) {
                          selectedAmount = amount
                          useCustom = false
                      }
                  }
              }
          }
      }
      
      private var customAmountSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Custom Amount", icon: "slider.horizontal.3")
              
              HStack {
                  TextField("Amount", text: $customAmount)
                      .textFieldStyle(.plain)
                      .keyboardType(.decimalPad)
                      .padding()
                      .background(useCustom ? Color.accent.opacity(0.1) : Color.secondaryBackground)
                      .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                      .overlay(
                          RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                              .stroke(useCustom ? Color.accent : Color.clear, lineWidth: 2)
                      )
                      .onTapGesture {
                          useCustom = true
                      }
                  
                  Text(selectedUnit.rawValue)
                      .foregroundStyle(.secondary)
                      .padding(.horizontal)
              }
          }
      }
      
      private var unitSelector: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Unit", icon: "ruler")
              
              Picker("Unit", selection: $selectedUnit) {
                  ForEach(WaterUnit.allCases, id: \.self) { unit in
                      Text(unit.rawValue).tag(unit)
                  }
              }
              .pickerStyle(.segmented)
          }
      }
      
      private var addButton: some View {
          Button(action: addWater) {
              Label("Add Water", systemImage: "plus.circle.fill")
                  .frame(maxWidth: .infinity)
          }
          .buttonStyle(.primaryProminent)
          .disabled(useCustom && customAmount.isEmpty)
          .padding()
          .background(Color.cardBackground)
      }
      
      private func addWater() {
          let amount: Double
          if useCustom {
              amount = Double(customAmount) ?? 0
          } else {
              amount = selectedAmount
          }
          
          guard amount > 0 else { return }
          
          Task {
              await viewModel.logWater(amount: amount, unit: selectedUnit)
              
              // Reset for next entry
              if useCustom {
                  customAmount = ""
              }
          }
      }
  }
  
  struct QuickWaterButton: View {
      let amount: Double
      let unit: WaterUnit
      let isSelected: Bool
      let action: () -> Void
      
      var displayText: String {
          let value = Int(amount)
          return "\(value) \(unit.rawValue)"
      }
      
      var body: some View {
          Button(action: action) {
              VStack(spacing: AppSpacing.xs) {
                  Image(systemName: "drop.fill")
                      .font(.title2)
                      .foregroundStyle(isSelected ? .white : .blue)
                  
                  Text(displayText)
                      .font(.callout)
                      .fontWeight(.medium)
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(isSelected ? Color.blue : Color.secondaryBackground)
              .foregroundStyle(isSelected ? .white : .primary)
              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
          }
      }
  }
  ```

---

**Task 8.5: Service Implementations**

**Agent Task 8.5.1: Create Nutrition Service**
- File: `AirFit/Modules/FoodTracking/Services/NutritionService.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import SwiftData
  
  protocol NutritionServiceProtocol: Sendable {
      func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry]
      func calculateNutritionSummary(from entries: [FoodEntry]) -> NutritionSummary
      func getWaterIntake(for user: User, date: Date) async throws -> Double
      func logWaterIntake(for user: User, amountML: Double, date: Date) async throws
      func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem]
      func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry]
      func getTargets(from profile: OnboardingProfile?) -> NutritionTargets
      func getTodaysSummary(for user: User) async throws -> NutritionSummary
  }
  
  final class NutritionService: NutritionServiceProtocol {
      private let modelContext: ModelContext
      
      init(modelContext: ModelContext) {
          self.modelContext = modelContext
      }
      
      func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
          let calendar = Calendar.current
          let startOfDay = calendar.startOfDay(for: date)
          let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
          
          let descriptor = FetchDescriptor<FoodEntry>(
              predicate: #Predicate { entry in
                  entry.user?.id == user.id &&
                  entry.loggedAt >= startOfDay &&
                  entry.loggedAt < endOfDay
              },
              sortBy: [SortDescriptor(\.loggedAt)]
          )
          
          return try modelContext.fetch(descriptor)
      }
      
      func calculateNutritionSummary(from entries: [FoodEntry]) -> NutritionSummary {
          var summary = NutritionSummary()
          
          for entry in entries {
              for item in entry.items {
                  summary.calories += item.calories
                  summary.protein += item.proteinGrams      // Changed from item.protein
                  summary.carbs += item.carbGrams          // Changed from item.carbohydrates
                  summary.fat += item.fatGrams            // Changed from item.fat
                  summary.fiber += item.fiber ?? 0
                  summary.sugar += item.sugar ?? 0
                  summary.sodium += item.sodium ?? 0
              }
          }
          
          return summary
      }
      
      func getWaterIntake(for user: User, date: Date) async throws -> Double {
          // In a real app, this would fetch from a WaterIntake entity
          // For now, return a mock value
          return 750
      }
      
      func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
          // In a real app, this would create/update a WaterIntake entity
          AppLogger.info("Logged \(amountML)ml water for user \(user.name)", category: .data)
      }
      
      func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
          let descriptor = FetchDescriptor<FoodEntry>(
              predicate: #Predicate { entry in
                  entry.user?.id == user.id
              },
              sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
          )
          
          let entries = try modelContext.fetch(descriptor)
          
          // Get unique recent foods
          var seenFoods = Set<String>()
          var recentFoods: [FoodItem] = []
          
          for entry in entries {
              for item in entry.items {
                  let key = "\(item.name)_\(item.brand ?? "")"
                  if !seenFoods.contains(key) && recentFoods.count < limit {
                      seenFoods.insert(key)
                      recentFoods.append(item)
                  }
              }
              if recentFoods.count >= limit { break }
          }
          
          return recentFoods
      }
      
      func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
          let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
          
          let descriptor = FetchDescriptor<FoodEntry>(
              predicate: #Predicate { entry in
                  entry.user?.id == user.id &&
                  entry.mealType == mealType.rawValue &&
                  entry.loggedAt >= startDate
              },
              sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
          )
          
          return try modelContext.fetch(descriptor)
      }
      
      func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
          // Calculate based on user profile
          guard let profile = profile else {
              return NutritionTargets.default
          }
          
          // This would use profile data to calculate personalized targets
          // For now, return defaults with some variation
          return NutritionTargets(
              calories: 2000,
              protein: 50,
              carbs: 250,
              fat: 65,
              fiber: 25,
              water: 2000
          )
      }
      
      func getTodaysSummary(for user: User) async throws -> NutritionSummary {
          let entries = try await getFoodEntries(for: user, date: Date())
          var summary = calculateNutritionSummary(from: entries)
          
          // Add targets from profile
          if let profile = user.onboardingProfile {
              let targets = getTargets(from: profile)
              summary.calorieGoal = targets.calories
              summary.proteinGoal = targets.protein
              summary.carbGoal = targets.carbs
              summary.fatGoal = targets.fat
          }
          
          return summary
      }
  }
  
  struct NutritionTargets {
      let calories: Double
      let protein: Double
      let carbs: Double
      let fat: Double
      let fiber: Double
      let water: Double
      
      static let `default` = NutritionTargets(
          calories: 2000,
          protein: 50,
          carbs: 250,
          fat: 65,
          fiber: 25,
          water: 2000
      )
  }
  ```

**Agent Task 8.5.2: Create Food Database Service**
- File: `AirFit/Modules/FoodTracking/Services/FoodDatabaseService.swift`
- Complete Implementation:
  ```swift
  import Foundation
  
  protocol FoodDatabaseServiceProtocol: Sendable {
      func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem]
      func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem?
      func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem?
  }
  
  struct FoodDatabaseItem: Identifiable, Sendable {
      let id: String
      let name: String
      let brand: String?
      let caloriesPerServing: Double
      let proteinPerServing: Double
      let carbsPerServing: Double
      let fatPerServing: Double
      let servingSize: Double
      let servingUnit: String
      let defaultQuantity: Double
      let defaultUnit: String
      
      var servingDescription: String {
          "\(servingSize.formatted()) \(servingUnit)"
      }
  }
  
  final class FoodDatabaseService: FoodDatabaseServiceProtocol {
      // Mock implementation for now
      private let mockDatabase: [FoodDatabaseItem] = [
          FoodDatabaseItem(
              id: "1",
              name: "Apple",
              brand: nil,
              caloriesPerServing: 95,
              proteinPerServing: 0.5,
              carbsPerServing: 25,
              fatPerServing: 0.3,
              servingSize: 1,
              servingUnit: "medium",
              defaultQuantity: 1,
              defaultUnit: "medium"
          ),
          FoodDatabaseItem(
              id: "2",
              name: "Chicken Breast",
              brand: nil,
              caloriesPerServing: 165,
              proteinPerServing: 31,
              carbsPerServing: 0,
              fatPerServing: 3.6,
              servingSize: 100,
              servingUnit: "g",
              defaultQuantity: 100,
              defaultUnit: "g"
          ),
          FoodDatabaseItem(
              id: "3",
              name: "Greek Yogurt",
              brand: "Chobani",
              caloriesPerServing: 100,
              proteinPerServing: 18,
              carbsPerServing: 6,
              fatPerServing: 0,
              servingSize: 170,
              servingUnit: "g",
              defaultQuantity: 1,
              defaultUnit: "cup"
          )
      ]
      
      func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem] {
          // Simulate network delay
          try await Task.sleep(nanoseconds: 500_000_000)
          
          let lowercaseQuery = query.lowercased()
          let results = mockDatabase.filter { item in
              item.name.lowercased().contains(lowercaseQuery) ||
              (item.brand?.lowercased().contains(lowercaseQuery) ?? false)
          }
          
          return Array(results.prefix(limit))
      }
      
      func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem? {
          // Simulate network delay
          try await Task.sleep(nanoseconds: 500_000_000)
          
          // Mock barcode lookup
          if barcode == "123456789" {
              return FoodDatabaseItem(
                  id: "barcode_1",
                  name: "Protein Bar",
                  brand: "Quest",
                  caloriesPerServing: 200,
                  proteinPerServing: 20,
                  carbsPerServing: 22,
                  fatPerServing: 8,
                  servingSize: 1,
                  servingUnit: "bar",
                  defaultQuantity: 1,
                  defaultUnit: "bar"
              )
          }
          
          return nil
      }
      
      func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem? {
          return mockDatabase.first { $0.name.lowercased() == name.lowercased() }
      }
  }
  ```

---

**Task 8.6: Testing**

**Agent Task 8.6.1: Create Food Tracking View Model Tests**
- File: `AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift`
- Test Implementation:
  ```swift
  @MainActor
  final class FoodTrackingViewModelTests: XCTestCase {
      var sut: FoodTrackingViewModel!
      var mockWhisperService: MockWhisperService!
      var mockNutritionService: MockNutritionService!
      var mockFoodDatabaseService: MockFoodDatabaseService!
      var mockCoachEngine: MockCoachEngine!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup test context
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, FoodEntry.self, FoodItem.self
          )
          
          // Create test user
          testUser = User(name: "Test User")
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks
          mockWhisperService = MockWhisperService()
          mockNutritionService = MockNutritionService()
          mockFoodDatabaseService = MockFoodDatabaseService()
          mockCoachEngine = MockCoachEngine()
          
          // Create SUT
          sut = FoodTrackingViewModel(
              modelContext: modelContext,
              user: testUser,
              whisperService: mockWhisperService,
              nutritionService: mockNutritionService,
              foodDatabaseService: mockFoodDatabaseService,
              coachEngine: mockCoachEngine,
              coordinator: FoodTrackingCoordinator()
          )
      }
      
      func test_startVoiceInput_withPermission_shouldShowVoiceSheet() async throws {
          // Arrange
          mockWhisperService.hasPermission = true
          
          // Act
          await sut.startVoiceInput()
          
          // Assert
          XCTAssertEqual(sut.coordinator.activeSheet, .voiceInput)
      }
      
      func test_processTranscription_withSimpleFood_shouldParseLocally() async {
          // Arrange
          sut.transcribedText = "log an apple"
          mockFoodDatabaseService.mockSearchResult = FoodDatabaseItem(
              id: "1",
              name: "Apple",
              brand: nil,
              caloriesPerServing: 95,
              proteinPerServing: 0.5,
              carbsPerServing: 25,
              fatPerServing: 0.3,
              servingSize: 1,
              servingUnit: "medium",
              defaultQuantity: 1,
              defaultUnit: "medium"
          )
          
          // Act
          await sut.processTranscription()
          
          // Assert
          XCTAssertEqual(sut.parsedItems.count, 1)
          XCTAssertEqual(sut.parsedItems.first?.name, "Apple")
          XCTAssertEqual(sut.parsedItems.first?.calories, 95)
      }
      
      func test_confirmAndSaveFoodItems_shouldCreateFoodEntry() async throws {
          // Arrange
          let parsedItems = [
              ParsedFoodItem(
                  name: "Test Food",
                  brand: nil,
                  quantity: 1,
                  unit: "serving",
                  calories: 100,
                  proteinGrams: 10,
                  carbGrams: 20,
                  fatGrams: 5,
                  confidence: 0.9
              )
          ]
          
          // Act
          await sut.confirmAndSaveFoodItems(parsedItems)
          
          // Assert
          let entries = try modelContext.fetch(FetchDescriptor<FoodEntry>())
          XCTAssertEqual(entries.count, 1)
          XCTAssertEqual(entries.first?.items.count, 1)
          XCTAssertEqual(entries.first?.items.first?.name, "Test Food")
      }
      
      func test_searchFoods_shouldUpdateSearchResults() async {
          // Arrange
          let mockResults = [
              FoodDatabaseItem(
                  id: "1",
                  name: "Chicken",
                  brand: nil,
                  caloriesPerServing: 165,
                  proteinPerServing: 31,
                  carbsPerServing: 0,
                  fatPerServing: 3.6,
                  servingSize: 100,
                  servingUnit: "g",
                  defaultQuantity: 100,
                  defaultUnit: "g"
              )
          ]
          mockFoodDatabaseService.searchResults = mockResults
          
          // Act
          await sut.searchFoods("chicken")
          
          // Assert
          XCTAssertEqual(sut.searchResults.count, 1)
          XCTAssertEqual(sut.searchResults.first?.name, "Chicken")
      }
      
      func test_logWater_shouldUpdateWaterIntake() async {
          // Arrange
          sut.waterIntakeML = 500
          
          // Act
          await sut.logWater(amount: 250, unit: .ml)
          
          // Assert
          XCTAssertEqual(sut.waterIntakeML, 750)
          XCTAssertTrue(mockNutritionService.didLogWater)
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Voice-based food logging with real-time transcription
- ✅ AI-powered food parsing from natural language
- ✅ Barcode scanning integration
- ✅ Food database search functionality
- ✅ Macro and micronutrient tracking
- ✅ Water intake logging
- ✅ Visual nutrition summaries with animated rings
- ✅ Meal history and smart suggestions
- ✅ Quick add from favorites/recent foods
- ✅ Manual food entry option
- ✅ Integration with HealthKit for nutrition data
- ✅ Offline capability with local food database
- ✅ Performance: Voice input < 100ms latency
- ✅ Test coverage ≥ 80%

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 4, 5
- **Must Be Completed Before:** Final app assembly
- **Can Run In Parallel With:** Module 7 (Workout Logging)

**7. Performance Requirements**

- Voice recording start: < 100ms
- Transcription accuracy: > 95% for food names and quantities
- WhisperKit model performance:
  - Tiny/Base models recommended for quick food logging (< 1s for typical entries)
  - Real-time waveform visualization at 60fps
  - Transcription finalization: < 2s after stopping recording
- AI parsing: < 2 seconds for complex meals
- Food search: < 500ms response time
- UI animations: 60fps throughout
- Memory usage: < 50MB for voice recording + model memory (see Module 13)

**8. WhisperKit Integration Benefits for Food Tracking**

The integration of WhisperKit for voice-based food logging provides several key advantages over the standard iOS Speech framework:

**Superior Food Recognition Accuracy:**
- **Food-Specific Terms**: WhisperKit handles food names, brands, and cooking methods much better than iOS Speech Recognition
- **Quantity Recognition**: Accurate transcription of measurements like "2 and a half cups", "350 grams", "1.5 ounces"
- **Multi-Language Food Names**: Recognizes international cuisine names (e.g., "quinoa", "acai", "kimchi", "sriracha")
- **Brand Names**: Better recognition of food brand names that iOS Speech might struggle with

**Privacy & Offline Capability:**
- All voice processing happens on-device, ensuring meal data privacy
- No internet required once the model is downloaded
- Particularly important for health-conscious users who value data privacy

**Optimized for Quick Logging:**
- Shorter recording duration (30s max) optimized for food entries
- Fast transcription with smaller models (tiny/base) for quick logging
- Real-time waveform feedback showing recording is active

**Food-Specific Post-Processing:**
- Custom corrections for common food terms and units
- Proper formatting of quantities and measurements
- Recognition of meal types and cooking methods

**Shared Model Management:**
- Leverages the same WhisperKit models downloaded for Module 13 (Chat)
- No additional storage required if chat module is already using WhisperKit
- Consistent voice experience across the app

**Implementation Considerations:**
- Use smaller models (tiny/base) by default for food logging to prioritize speed
- Food entries are typically shorter than chat messages, so optimize for quick transcription
- Consider adding food-specific vocabulary to improve recognition of specialty items
- Implement voice activity detection to auto-stop recording after silence

---
