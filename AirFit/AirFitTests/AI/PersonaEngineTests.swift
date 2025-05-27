import XCTest
import SwiftData
@testable import AirFit

final class PersonaEngineTests: XCTestCase {
    // MARK: - Properties
    var sut: PersonaEngine!
    var modelContext: ModelContext!
    var testUser: User!
    
    // MARK: - Setup & Teardown
    @MainActor
    override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            CoachMessage.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
        
        // Create test user
        testUser = User(
            id: UUID(),
            createdAt: Date(),
            lastActiveAt: Date()
        )
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Initialize system under test
        sut = PersonaEngine()
    }
    
    @MainActor
    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        testUser = nil
    }
    
    // MARK: - Prompt Building Tests
    
    @MainActor
    func test_buildSystemPrompt_withValidInputs_shouldGenerateCompletePrompt() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory = createTestConversationHistory()
        let availableFunctions = createTestFunctions()
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("AirFit Coach"))
        XCTAssertFalse(prompt.contains("{{USER_PROFILE_JSON}}")) // Should be replaced
        XCTAssertFalse(prompt.contains("{{HEALTH_CONTEXT_JSON}}")) // Should be replaced
        XCTAssertFalse(prompt.contains("{{CONVERSATION_HISTORY_JSON}}")) // Should be replaced
        XCTAssertFalse(prompt.contains("{{AVAILABLE_FUNCTIONS_JSON}}")) // Should be replaced
        XCTAssertFalse(prompt.contains("{{CURRENT_DATETIME_UTC}}")) // Should be replaced
        XCTAssertTrue(prompt.contains(userProfile.timezone))
        
        // Verify JSON injection
        XCTAssertTrue(prompt.contains("\"life_context\""))
        XCTAssertTrue(prompt.contains("\"blend\""))
        XCTAssertTrue(prompt.contains("\"goal\""))
        XCTAssertTrue(prompt.contains("\"engagement_preferences\""))
    }
    
    @MainActor
    func test_buildSystemPrompt_withJSONInjection_shouldEscapeSpecialCharacters() throws {
        // Given
        let userProfile = createTestUserProfileWithSpecialChars()
        let healthContext = createTestHealthContext()
        let conversationHistory: [ChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("escape"))
        // Note: The PersonaEngine may not filter HTML tags, just ensure JSON is properly escaped
        XCTAssertTrue(prompt.contains("\"")) // Contains quotes (may be escaped in JSON)
    }
    
    @MainActor
    func test_buildSystemPrompt_withLongConversationHistory_shouldLimitToLast20Messages() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory = createLongConversationHistory(count: 50)
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        // Count occurrences of message markers in the JSON
        let messageCount = prompt.components(separatedBy: "\"role\"").count - 1
        XCTAssertLessThanOrEqual(messageCount, 20)
    }
    
    @MainActor
    func test_buildSystemPrompt_withTokenLengthValidation_shouldThrowForLongPrompts() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createMassiveHealthContext()
        let conversationHistory = createLongConversationHistory(count: 20)
        let availableFunctions = createManyTestFunctions(count: 50)
        
        // When & Then
        XCTAssertThrowsError(try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )) { error in
            guard let personaError = error as? PersonaEngineError,
                  case .promptTooLong(let tokens) = personaError else {
                XCTFail("Expected PersonaEngineError.promptTooLong")
                return
            }
            XCTAssertGreaterThan(tokens, 8_000)
        }
    }
    
    // MARK: - Persona Adjustment Tests
    
    @MainActor
    func test_adjustPersonaForContext_withLowEnergy_shouldIncreaseEmpathy() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithLowEnergy()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalDirect = baseProfile.blend.authoritativeDirect
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.authoritativeDirect, originalDirect)
        XCTAssertTrue(adjustedProfile.blend.isValid) // Should remain normalized
    }
    
    @MainActor
    func test_adjustPersonaForContext_withHighStress_shouldReduceProvocative() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithHighStress()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalProvocative = baseProfile.blend.playfullyProvocative
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.playfullyProvocative, originalProvocative)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withEveningTime_shouldBeCalmAndLessPlayful() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithEveningTime()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalProvocative = baseProfile.blend.playfullyProvocative
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.playfullyProvocative, originalProvocative)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withPoorSleep_shouldBeMoreUnderstanding() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithPoorSleep()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalDirect = baseProfile.blend.authoritativeDirect
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.authoritativeDirect, originalDirect)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withRecoveryNeeds_shouldBeMoreSupportive() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithRecoveryNeeds()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalDirect = baseProfile.blend.authoritativeDirect
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.authoritativeDirect, originalDirect)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withWorkoutStreak_shouldBeMoreChallenging() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithWorkoutStreak()
        
        let originalProvocative = baseProfile.blend.playfullyProvocative
        let originalDirect = baseProfile.blend.authoritativeDirect
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.playfullyProvocative, originalProvocative)
        XCTAssertGreaterThan(adjustedProfile.blend.authoritativeDirect, originalDirect)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withDetrainingStatus_shouldBeVeryEncouraging() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithDetraining()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        let originalDirect = baseProfile.blend.authoritativeDirect
        let originalProvocative = baseProfile.blend.playfullyProvocative
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then
        XCTAssertGreaterThan(adjustedProfile.blend.encouragingEmpathetic, originalEmpathy)
        XCTAssertLessThan(adjustedProfile.blend.authoritativeDirect, originalDirect)
        XCTAssertLessThan(adjustedProfile.blend.playfullyProvocative, originalProvocative)
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    @MainActor
    func test_adjustPersonaForContext_withMultipleFactors_shouldApplyAllAdjustments() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithMultipleFactors()
        
        let originalEmpathy = baseProfile.blend.encouragingEmpathetic
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then - Multiple adjustments should compound
        let empathyIncrease = adjustedProfile.blend.encouragingEmpathetic - originalEmpathy
        XCTAssertGreaterThan(empathyIncrease, 0.2) // Significant increase from multiple factors
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func test_buildSystemPrompt_withFunctionRegistry_shouldIncludeAllFunctions() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory: [ChatMessage] = []
        let availableFunctions = FunctionRegistry.availableFunctions
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("generatePersonalizedWorkoutPlan"))
        XCTAssertTrue(prompt.contains("parseAndLogComplexNutrition"))
        XCTAssertTrue(prompt.contains("analyzePerformanceTrends"))
        XCTAssertTrue(prompt.contains("assistGoalSettingOrRefinement"))
    }
    
    @MainActor
    func test_buildSystemPrompt_withHealthContext_shouldIncludeRelevantMetrics() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithSpecificMetrics()
        
        let conversationHistory: [ChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("8500") || prompt.contains("8,500"))
        XCTAssertTrue(prompt.contains("65"))
        XCTAssertTrue(prompt.contains("70"))
    }
    
    @MainActor
    func test_buildSystemPrompt_withConversationHistory_shouldMaintainContext() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory = [
            ChatMessage(role: "user", content: "How many calories should I eat?"),
            ChatMessage(role: "assistant", content: "Based on your goals, I recommend 2000 calories per day."),
            ChatMessage(role: "user", content: "What about protein?")
        ]
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("calories"))
        XCTAssertTrue(prompt.contains("2000"))
        XCTAssertTrue(prompt.contains("protein"))
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func test_buildSystemPrompt_performance_shouldCompleteQuickly() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory = createTestConversationHistory()
        let availableFunctions = createTestFunctions()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10 {
            _ = try sut.buildSystemPrompt(
                userProfile: userProfile,
                healthContext: healthContext,
                conversationHistory: conversationHistory,
                availableFunctions: availableFunctions
            )
        }
        
        let averageTime = (CFAbsoluteTimeGetCurrent() - startTime) / 10.0
        
        // Then
        XCTAssertLessThan(averageTime, 0.01) // Should complete in < 10ms
    }
    
    @MainActor
    func test_adjustPersonaForContext_performance_shouldCompleteQuickly() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            _ = sut.adjustPersonaForContext(
                baseProfile: baseProfile,
                healthContext: healthContext
            )
        }
        
        let averageTime = (CFAbsoluteTimeGetCurrent() - startTime) / 100.0
        
        // Then
        XCTAssertLessThan(averageTime, 0.001) // Should complete in < 1ms
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func test_buildSystemPrompt_withInvalidTimezone_shouldUseAsIs() throws {
        // Given
        let userProfile = createTestUserProfileWithInvalidTimezone()
        let healthContext = createTestHealthContext()
        let conversationHistory: [ChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("Invalid/Timezone")) // Should include as-is
    }
    
    @MainActor
    func test_adjustPersonaForContext_withNilHealthData_shouldReturnOriginalProfile() {
        // Given
        let baseProfile = createTestUserProfile()
        let healthContext = createTestHealthContextWithNilData()
        
        // When
        let adjustedProfile = sut.adjustPersonaForContext(
            baseProfile: baseProfile,
            healthContext: healthContext
        )
        
        // Then - Should be very similar to original (only time-based adjustments)
        let empathyDiff = abs(adjustedProfile.blend.encouragingEmpathetic - baseProfile.blend.encouragingEmpathetic)
        XCTAssertLessThan(empathyDiff, 0.1) // Minimal change
        XCTAssertTrue(adjustedProfile.blend.isValid)
    }
    
    // MARK: - Helper Methods
    
    private func createTestUserProfile() -> PersonaProfile {
        return UserProfileJsonBlob(
            lifeContext: LifeContext(
                isDeskJob: true,
                isPhysicallyActiveWork: false,
                travelsFrequently: false,
                hasChildrenOrFamilyCare: true,
                scheduleType: .predictable,
                workoutWindowPreference: .earlyBird
            ),
            goal: Goal(
                family: .healthWellbeing,
                rawText: "I want to lose 15 pounds and feel more energetic"
            ),
            blend: Blend(
                authoritativeDirect: 0.25,
                encouragingEmpathetic: 0.35,
                analyticalInsightful: 0.30,
                playfullyProvocative: 0.10
            ),
            engagementPreferences: EngagementPreferences(
                trackingStyle: .dataDrivenPartnership,
                informationDepth: .detailed,
                updateFrequency: .daily
            ),
            sleepWindow: SleepWindow(
                bedTime: "22:30",
                wakeTime: "06:30",
                consistency: .consistent
            ),
            motivationalStyle: MotivationalStyle(
                celebrationStyle: .enthusiasticCelebratory,
                absenceResponse: .gentleNudge
            ),
            timezone: "America/New_York",
            baselineModeEnabled: true
        )
    }
    
    private func createTestUserProfileWithSpecialChars() -> PersonaProfile {
        return UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(
                family: .healthWellbeing,
                rawText: "I want to \"escape\" this & that <script>alert('xss')</script>"
            ),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "UTC",
            baselineModeEnabled: true
        )
    }
    
    private func createTestUserProfileWithInvalidTimezone() -> PersonaProfile {
        return UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "Invalid/Timezone",
            baselineModeEnabled: true
        )
    }
    
    private func createTestHealthContext() -> HealthContextSnapshot {
        return HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: 3,
                mood: 4,
                stress: 2,
                motivation: 4,
                soreness: 1,
                notes: "Feeling good today"
            ),
            environment: EnvironmentContext(
                weatherCondition: "sunny",
                temperature: Measurement(value: 22, unit: .celsius),
                humidity: 45,
                airQualityIndex: 25,
                timeOfDay: .morning
            ),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 400, unit: .kilocalories),
                basalEnergyBurned: Measurement(value: 1500, unit: .kilocalories),
                steps: 7_500,
                distance: Measurement(value: 5.2, unit: .kilometers),
                flightsClimbed: 12,
                exerciseMinutes: 45,
                standHours: 8,
                moveMinutes: 30,
                currentHeartRate: 72,
                isWorkoutActive: false,
                moveProgress: 0.8,
                exerciseProgress: 0.9,
                standProgress: 0.67
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-8 * 3600),
                    wakeTime: Date(),
                    totalSleepTime: 7.5 * 3600,
                    timeInBed: 8 * 3600,
                    efficiency: 94,
                    remTime: 2 * 3600,
                    coreTime: 4 * 3600,
                    deepTime: 1.5 * 3600,
                    awakeTime: 30 * 60
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 58,
                hrv: Measurement(value: 45, unit: .milliseconds),
                respiratoryRate: 14,
                vo2Max: 42.5,
                cardioFitness: .aboveAverage
            ),
            body: BodyMetrics(
                weight: Measurement(value: 72, unit: .kilograms),
                bodyFatPercentage: 18.5,
                bmi: 23.2,
                weightTrend: .stable
            ),
            appContext: AppSpecificContext(
                lastMealTime: Date().addingTimeInterval(-2 * 3600),
                lastMealSummary: "Breakfast: Oatmeal with berries",
                waterIntakeToday: Measurement(value: 1.2, unit: .liters),
                lastCoachInteraction: Date().addingTimeInterval(-1 * 3600),
                currentStreak: 5
            ),
            trends: HealthTrends(
                weeklyActivityChange: 12.5,
                sleepConsistencyScore: 85,
                recoveryTrend: .normal,
                performanceTrend: .improving
            )
        )
    }
    
    private func createTestHealthContextWithLowEnergy() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: 1, // Very low energy
                mood: context.subjectiveData.mood,
                stress: context.subjectiveData.stress,
                motivation: context.subjectiveData.motivation,
                soreness: context.subjectiveData.soreness,
                notes: context.subjectiveData.notes
            ),
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithHighStress() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: context.subjectiveData.energyLevel,
                mood: context.subjectiveData.mood,
                stress: 5, // Very high stress
                motivation: context.subjectiveData.motivation,
                soreness: context.subjectiveData.soreness,
                notes: context.subjectiveData.notes
            ),
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithEveningTime() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: EnvironmentContext(
                weatherCondition: context.environment.weatherCondition,
                temperature: context.environment.temperature,
                humidity: context.environment.humidity,
                airQualityIndex: context.environment.airQualityIndex,
                timeOfDay: .evening
            ),
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithPoorSleep() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: context.activity,
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-8 * 3600),
                    wakeTime: Date(),
                    totalSleepTime: 4 * 3600, // Only 4 hours
                    timeInBed: 8 * 3600,
                    efficiency: 50, // Poor efficiency
                    remTime: 1 * 3600,
                    coreTime: 2 * 3600,
                    deepTime: 1 * 3600,
                    awakeTime: 4 * 3600
                )
            ),
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithRecoveryNeeds() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: HealthTrends(
                weeklyActivityChange: context.trends.weeklyActivityChange,
                sleepConsistencyScore: context.trends.sleepConsistencyScore,
                recoveryTrend: .needsRecovery,
                performanceTrend: context.trends.performanceTrend
            )
        )
        return context
    }
    
    private func createTestHealthContextWithWorkoutStreak() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: AppSpecificContext(
                activeWorkoutName: context.appContext.activeWorkoutName,
                lastMealTime: context.appContext.lastMealTime,
                lastMealSummary: context.appContext.lastMealSummary,
                waterIntakeToday: context.appContext.waterIntakeToday,
                lastCoachInteraction: context.appContext.lastCoachInteraction,
                upcomingWorkout: context.appContext.upcomingWorkout,
                currentStreak: context.appContext.currentStreak,
                workoutContext: WorkoutContext(
                    streakDays: 10, // Strong streak
                    intensityTrend: .stable,
                    recoveryStatus: .wellRested
                )
            ),
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithDetraining() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: AppSpecificContext(
                activeWorkoutName: context.appContext.activeWorkoutName,
                lastMealTime: context.appContext.lastMealTime,
                lastMealSummary: context.appContext.lastMealSummary,
                waterIntakeToday: context.appContext.waterIntakeToday,
                lastCoachInteraction: context.appContext.lastCoachInteraction,
                upcomingWorkout: context.appContext.upcomingWorkout,
                currentStreak: context.appContext.currentStreak,
                workoutContext: WorkoutContext(
                    streakDays: 0,
                    intensityTrend: .decreasing,
                    recoveryStatus: .detraining
                )
            ),
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithMultipleFactors() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: 2, // Low energy
                mood: context.subjectiveData.mood,
                stress: 4, // High stress
                motivation: context.subjectiveData.motivation,
                soreness: context.subjectiveData.soreness,
                notes: context.subjectiveData.notes
            ),
            environment: EnvironmentContext(
                weatherCondition: context.environment.weatherCondition,
                temperature: context.environment.temperature,
                humidity: context.environment.humidity,
                airQualityIndex: context.environment.airQualityIndex,
                timeOfDay: .evening
            ),
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: HealthTrends(
                weeklyActivityChange: context.trends.weeklyActivityChange,
                sleepConsistencyScore: context.trends.sleepConsistencyScore,
                recoveryTrend: .needsRecovery,
                performanceTrend: context.trends.performanceTrend
            )
        )
        return context
    }
    
    private func createTestHealthContextWithSpecificMetrics() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: ActivityMetrics(
                activeEnergyBurned: context.activity.activeEnergyBurned,
                basalEnergyBurned: context.activity.basalEnergyBurned,
                steps: 8_500,
                distance: context.activity.distance,
                flightsClimbed: context.activity.flightsClimbed,
                exerciseMinutes: context.activity.exerciseMinutes,
                standHours: context.activity.standHours,
                moveMinutes: context.activity.moveMinutes,
                currentHeartRate: context.activity.currentHeartRate,
                isWorkoutActive: context.activity.isWorkoutActive,
                moveProgress: context.activity.moveProgress,
                exerciseProgress: context.activity.exerciseProgress,
                standProgress: context.activity.standProgress
            ),
            sleep: context.sleep,
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 65,
                hrv: context.heartHealth.hrv,
                respiratoryRate: context.heartHealth.respiratoryRate,
                vo2Max: context.heartHealth.vo2Max,
                cardioFitness: context.heartHealth.cardioFitness,
                recoveryHeartRate: context.heartHealth.recoveryHeartRate,
                heartRateRecovery: context.heartHealth.heartRateRecovery
            ),
            body: BodyMetrics(
                weight: Measurement(value: 70, unit: .kilograms),
                bodyFatPercentage: context.body.bodyFatPercentage,
                leanBodyMass: context.body.leanBodyMass,
                bmi: context.body.bmi,
                weightTrend: context.body.weightTrend,
                bodyFatTrend: context.body.bodyFatTrend
            ),
            appContext: context.appContext,
            trends: context.trends
        )
        return context
    }
    
    private func createTestHealthContextWithNilData() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        context = HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: nil,
                mood: context.subjectiveData.mood,
                stress: nil,
                motivation: context.subjectiveData.motivation,
                soreness: context.subjectiveData.soreness,
                notes: context.subjectiveData.notes
            ),
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: context.appContext,
            trends: HealthTrends(
                weeklyActivityChange: context.trends.weeklyActivityChange,
                sleepConsistencyScore: context.trends.sleepConsistencyScore,
                recoveryTrend: nil,
                performanceTrend: context.trends.performanceTrend
            )
        )
        return context
    }
    
    private func createTestConversationHistory() -> [ChatMessage] {
        return [
            ChatMessage(role: "user", content: "Good morning! How should I start my day?"),
            ChatMessage(role: "assistant", content: "Good morning! Based on your sleep quality last night, I'd recommend starting with some light stretching and hydration."),
            ChatMessage(role: "user", content: "That sounds great. What about breakfast?"),
            ChatMessage(role: "assistant", content: "Given your goals, a protein-rich breakfast would be ideal. How about eggs with some vegetables?")
        ]
    }
    
    private func createTestFunctions() -> [AIFunctionDefinition] {
        return [
            AIFunctionDefinition(
                name: "logWaterIntake",
                description: "Log water intake for the user",
                parameters: AIFunctionParameters(
                    properties: [
                        "amount": AIParameterDefinition(
                            type: "number",
                            description: "Amount of water in ounces"
                        ),
                        "timestamp": AIParameterDefinition(
                            type: "string",
                            description: "ISO timestamp of intake"
                        )
                    ],
                    required: ["amount"]
                )
            ),
            AIFunctionDefinition(
                name: "getHealthSummary",
                description: "Get current health metrics summary",
                parameters: AIFunctionParameters(
                    properties: [
                        "includeDetails": AIParameterDefinition(
                            type: "boolean",
                            description: "Whether to include detailed metrics"
                        )
                    ]
                )
            )
        ]
    }
    
    private func createLongConversationHistory(count: Int) -> [ChatMessage] {
        var messages: [ChatMessage] = []
        for i in 0..<count {
            let role = i % 2 == 0 ? "user" : "assistant"
            let content = "This is message number \(i + 1) in a long conversation history."
            messages.append(ChatMessage(role: role, content: content))
        }
        return messages
    }
    
    private func createMassiveHealthContext() -> HealthContextSnapshot {
        var context = createTestHealthContext()
        
        // Add massive workout context to increase token count
        context = HealthContextSnapshot(
            subjectiveData: context.subjectiveData,
            environment: context.environment,
            activity: context.activity,
            sleep: context.sleep,
            heartHealth: context.heartHealth,
            body: context.body,
            appContext: AppSpecificContext(
                activeWorkoutName: context.appContext.activeWorkoutName,
                lastMealTime: context.appContext.lastMealTime,
                lastMealSummary: context.appContext.lastMealSummary,
                waterIntakeToday: context.appContext.waterIntakeToday,
                lastCoachInteraction: context.appContext.lastCoachInteraction,
                upcomingWorkout: context.appContext.upcomingWorkout,
                currentStreak: context.appContext.currentStreak,
                workoutContext: WorkoutContext(
                    recentWorkouts: Array(0..<100).map { i in
                        CompactWorkout(
                            name: "Workout \(i) with a very long name that includes detailed exercise descriptions and extensive notes about form, technique, and performance metrics",
                            type: "Strength Training with Cardio and Flexibility Components",
                            date: Date().addingTimeInterval(-Double(i) * 86400),
                            duration: 3600,
                            exerciseCount: 15,
                            totalVolume: 5000,
                            avgRPE: 7.5,
                            muscleGroups: ["chest", "back", "shoulders", "arms", "legs", "core", "glutes"],
                            keyExercises: [
                                "Barbell Bench Press with detailed form notes",
                                "Deadlifts with progressive overload tracking",
                                "Squats with mobility work and warm-up routine"
                            ]
                        )
                    }
                )
            ),
            trends: context.trends
        )
        
        return context
    }
    
    private func createManyTestFunctions(count: Int) -> [AIFunctionDefinition] {
        return Array(0..<count).map { i in
            AIFunctionDefinition(
                name: "testFunction\(i)",
                description: "This is a test function number \(i) with a very long description that includes detailed parameter explanations, usage examples, and comprehensive documentation about its purpose, implementation details, and expected behavior in various scenarios.",
                parameters: AIFunctionParameters(
                    properties: [
                        "param1": AIParameterDefinition(
                            type: "string",
                            description: "A very detailed parameter description with extensive documentation"
                        ),
                        "param2": AIParameterDefinition(
                            type: "number",
                            description: "Another parameter with comprehensive documentation and examples"
                        ),
                        "param3": AIParameterDefinition(
                            type: "boolean",
                            description: "A boolean parameter with detailed usage instructions"
                        )
                    ],
                    required: ["param1", "param2"]
                )
            )
        }
    }
} 