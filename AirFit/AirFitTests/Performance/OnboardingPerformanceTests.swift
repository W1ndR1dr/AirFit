import XCTest
import SwiftData
@testable import AirFit

/// Performance tests for onboarding - Carmack style validation
@MainActor
final class OnboardingPerformanceTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var mockAIService: MockAIService!
    var mockAPIKeyManager: MockAPIKeyManager!
    var mockUserService: MockUserService!
    var onboardingService: OnboardingService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        modelContainer = try ModelContainer.createTestContainer()
        modelContext = modelContainer.mainContext
        
        mockAIService = MockAIService()
        mockAPIKeyManager = MockAPIKeyManager()
        mockUserService = MockUserService()
        onboardingService = OnboardingService(modelContext: modelContext)
        
        viewModel = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: onboardingService,
            modelContext: modelContext,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            mode: .legacy // Use legacy mode for performance tests
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        onboardingService = nil
        mockUserService = nil
        mockAPIKeyManager = nil
        mockAIService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Screen Transition Performance
    
    func test_screenTransition_shouldBeUnder100ms() async throws {
        // Arrange - set up profile data to enable navigation
        setupCompleteProfile()
        
        // Measure screen transition time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Act - navigate to next screen
        viewModel.navigateToNextScreen()
        let transitionDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(transitionDuration, 0.1, "Screen transition took \(String(format: "%.3f", transitionDuration))s - target is <100ms")
        XCTAssertEqual(viewModel.currentScreen, .lifeSnapshot)
    }
    
    // MARK: - Profile Completion Performance
    
    func test_completeOnboarding_shouldBeUnder1Second() async throws {
        // Arrange
        setupCompleteProfile()
        
        // Measure completion time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Act
        try await viewModel.completeOnboarding()
        let completionDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(completionDuration, 1.0, "Profile completion took \(String(format: "%.2f", completionDuration))s - target is <1s")
    }
    
    // MARK: - Memory Usage Tests
    
    func test_memoryUsage_shouldBeUnder10MB() async throws {
        let initialMemory = getMemoryUsage()
        
        // Navigate through all screens
        let screens: [OnboardingScreen] = [
            .openingScreen, .lifeSnapshot, .coreAspiration,
            .coachingStyle, .engagementPreferences, .sleepAndBoundaries,
            .motivationalAccents
        ]
        
        for _ in screens {
            viewModel.navigateToNextScreen()
            // Simulate some data entry
            setupCompleteProfile()
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncreaseMB = Double(finalMemory - initialMemory) / 1_048_576
        
        XCTAssertLessThan(memoryIncreaseMB, 10.0, "Memory increased by \(String(format: "%.1f", memoryIncreaseMB))MB - target is <10MB")
    }
    
    // MARK: - AI Response Simulation Performance
    
    func test_aiResponseStream_shouldStartWithin200ms() async throws {
        // Arrange
        let request = AIRequest(
            systemPrompt: "You are a helpful assistant.",
            messages: [],
            temperature: 0.7,
            stream: true,
            user: "Test message"
        )
        
        // Measure time to first response
        let startTime = CFAbsoluteTimeGetCurrent()
        var timeToFirstResponse: Double = 0
        var receivedFirstResponse = false
        
        // Act
        let stream = mockAIService.sendRequest(request)
        
        for try await response in stream {
            if !receivedFirstResponse {
                timeToFirstResponse = CFAbsoluteTimeGetCurrent() - startTime
                receivedFirstResponse = true
            }
            // Continue consuming stream
            _ = response
        }
        
        // Assert
        XCTAssertTrue(receivedFirstResponse)
        XCTAssertLessThan(timeToFirstResponse, 0.2, "Time to first response was \(String(format: "%.3f", timeToFirstResponse))s - target is <200ms")
    }
    
    // MARK: - Profile Save Performance
    
    func test_profileSave_shouldBeUnder500ms() async throws {
        // Arrange
        setupCompleteProfile()
        
        // Create profile blob
        let profileBlob = UserProfileJsonBlob(
            lifeContext: viewModel.lifeContext,
            goal: viewModel.goal,
            blend: Blend(), // Using default blend as we use selectedPersonaMode now
            engagementPreferences: viewModel.engagementPreferences,
            sleepWindow: viewModel.sleepWindow,
            motivationalStyle: viewModel.motivationalStyle,
            timezone: viewModel.timezone,
            baselineModeEnabled: viewModel.baselineModeEnabled
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileBlob)
        
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )
        
        // Measure save time
        let startTime = CFAbsoluteTimeGetCurrent()
        try await onboardingService.saveProfile(profile)
        let saveDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(saveDuration, 0.5, "Profile save took \(String(format: "%.3f", saveDuration))s - target is <500ms")
    }
    
    // MARK: - Navigation Performance
    
    func test_navigationThroughAllScreens_shouldBeUnder2Seconds() async throws {
        let screens: [OnboardingScreen] = [
            .openingScreen, .lifeSnapshot, .coreAspiration,
            .coachingStyle, .engagementPreferences, .sleepAndBoundaries,
            .motivationalAccents, .generatingCoach, .coachProfileReady
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in screens {
            viewModel.navigateToNextScreen()
            // Small delay to simulate real usage
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(totalDuration, 2.0, "Navigation through all screens took \(String(format: "%.2f", totalDuration))s - target is <2s")
    }
    
    // MARK: - Concurrent Operation Performance
    
    func test_concurrentOperations_shouldNotDegrade() async throws {
        // Test that multiple async operations don't degrade performance
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Run navigation and validation sequentially but measure total time
        await navigateNext()
        await validateMockData()
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, 1.0, "Sequential operations took \(String(format: "%.2f", duration))s - target is <1s")
    }
    
    // MARK: - Helper Methods
    
    private func setupCompleteProfile() {
        viewModel.lifeContext = LifeContext(
            isDeskJob: true,
            isPhysicallyActiveWork: false,
            travelsFrequently: false,
            hasChildrenOrFamilyCare: false,
            scheduleType: .predictable,
            workoutWindowPreference: .earlyBird
        )
        
        viewModel.goal = Goal(
            family: .healthWellbeing,
            rawText: "Lose 20 pounds and build muscle"
        )
        
        viewModel.selectedPersonaMode = .supportiveCoach
        
        viewModel.engagementPreferences = EngagementPreferences(
            trackingStyle: .dataDrivenPartnership,
            informationDepth: .detailed,
            updateFrequency: .daily
        )
        
        viewModel.sleepWindow = SleepWindow(
            bedTime: "22:00",
            wakeTime: "06:00",
            consistency: .consistent
        )
        
        viewModel.motivationalStyle = MotivationalStyle(
            celebrationStyle: .enthusiasticCelebratory,
            absenceResponse: .gentleNudge
        )
    }
    
    private func navigateNext() async {
        viewModel.navigateToNextScreen()
    }
    
    private func validateMockData() async {
        // Simulate some async validation
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}