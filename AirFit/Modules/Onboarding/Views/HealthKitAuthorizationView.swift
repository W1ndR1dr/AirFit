import SwiftUI
import SwiftData
import Observation

/// Placeholder view for HealthKit authorization during onboarding.
struct HealthKitAuthorizationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var heartBeat: CGFloat = 1.0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                // Glass card with health data preview
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        // Animated heart icon
                        ZStack {
                            Circle()
                                .fill(gradientManager.currentGradient(for: colorScheme))
                                .frame(width: 100, height: 100)
                                .opacity(0.2)
                                .scaleEffect(heartBeat * 1.2)
                                .blur(radius: 10)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                                .scaleEffect(heartBeat)
                        }
                        .frame(height: 120)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        
                        // Title with cascade
                        if animateIn {
                            CascadeText("Connect HealthKit")
                                .font(.system(size: 28, weight: .light, design: .rounded))
                        }
                        
                        Text("Allow AirFit to sync with your health data for personalized insights")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
                        
                        // Data types with icons
                        VStack(spacing: AppSpacing.sm) {
                            HealthDataRow(icon: "figure.walk", text: "Activity & Steps", delay: 0.3)
                            HealthDataRow(icon: "figure.run", text: "Workouts", delay: 0.4)
                            HealthDataRow(icon: "bed.double.fill", text: "Sleep Analysis", delay: 0.5)
                            HealthDataRow(icon: "heart.text.square", text: "Health Metrics", delay: 0.6)
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                // Authorization button
                StandardButton(
                    "Authorize HealthKit",
                    icon: "heart.circle.fill",
                    style: .primary,
                    isFullWidth: true
                ) {
                    Task { await viewModel.requestHealthKitAuthorization() }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.7), value: animateIn)
                .accessibilityIdentifier("onboarding.healthkit.authorize")
                
                // Skip option
                Button("Skip for now") {
                    HapticService.selection()
                    viewModel.navigateToNextScreen()
                }
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(0.8), value: animateIn)

                Spacer()

                // Error state
                if viewModel.healthKitAuthorizationStatus == .denied {
                    GlassCard {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text("Permission denied. You can enable access in Settings.")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
            startHeartBeatAnimation()
        }
    }
    
    private func startHeartBeatAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            heartBeat = 1.1
        }
    }
}

// MARK: - HealthDataRow
private struct HealthDataRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(.green.opacity(0.8))
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .opacity(animateIn ? 1 : 0)
        .offset(x: animateIn ? 0 : -20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(delay)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    HealthKitAuthorizationView(
        viewModel: OnboardingViewModel(
            aiService: DemoAIService(),
            onboardingService: PreviewOnboardingService(),
            modelContext: DataManager.preview.modelContext,
            apiKeyManager: PreviewAPIKeyManager(),
            userService: PreviewUserService(),
            healthKitAuthManager: HealthKitAuthManager(healthKitManager: PreviewHealthKitManager())
        )
    )
    .environmentObject(GradientManager())
}

// MARK: - Preview Helpers
private final class PreviewOnboardingService: OnboardingServiceProtocol {
    func setupService() async throws {}
    func teardownService() async throws {}
    func getHealthStatus() async -> ServiceHealthStatus { .healthy }
    
    func completeOnboarding(profile: OnboardingProfile) async throws -> User {
        User(email: "test@example.com", name: "Test User")
    }
    
    func updatePersona(_ persona: PersonaProfile, for userId: UUID) async throws {}
    func getPersona(for userId: UUID) async throws -> PersonaProfile? { nil }
}

private final class PreviewUserService: UserServiceProtocol {
    func getCurrentUser() -> User? { nil }
    func getCurrentUserId() async -> UUID? { nil }
    func createUser(from profile: OnboardingProfile) async throws -> User {
        User(email: profile.email, name: profile.name)
    }
    func updateProfile(_ updates: ProfileUpdate) async throws {}
    func completeOnboarding() async throws {}
    func setCoachPersona(_ persona: CoachPersona) async throws {}
    func deleteUser(_ user: User) async throws {}
}

private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func getAPIKey(for provider: AIProvider) async throws -> String { "test-key" }
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {}
    func deleteAPIKey(for provider: AIProvider) async throws {}
    func hasAPIKey(for provider: AIProvider) async -> Bool { true }
    func getAllConfiguredProviders() async -> [AIProvider] { [.openAI] }
}

private final class PreviewHealthKitManager: HealthKitManaging {
    var isAvailable: Bool { true }
    var authorizationStatus: HealthKitManager.AuthorizationStatus { .authorized }
    
    func requestAuthorization() async throws {}
    func refreshAuthorizationStatus() {}
    func queryDailySteps(startDate: Date, endDate: Date) async throws -> [DailyStepsData] { [] }
    func queryWorkouts(startDate: Date, endDate: Date) async throws -> [WorkoutData] { [] }
    func queryNutrition(startDate: Date, endDate: Date) async throws -> NutritionData {
        NutritionData(calories: 0, protein: 0, carbs: 0, fat: 0, date: Date())
    }
    func querySleepAnalysis(startDate: Date, endDate: Date) async throws -> [SleepData] { [] }
    func queryRestingHeartRate(startDate: Date, endDate: Date) async throws -> [HeartRateData] { [] }
    func queryHeartRateVariability(startDate: Date, endDate: Date) async throws -> [HRVData] { [] }
    func saveWorkout(_ workout: WorkoutData) async throws {}
    func saveNutrition(_ nutrition: NutritionData) async throws {}
    func saveSleep(_ sleep: SleepData) async throws {}
}
