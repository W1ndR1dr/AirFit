import Foundation
import SwiftData

@MainActor
final class DataManager: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "data-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    init() {}
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["configured": "\(_isConfigured)"]
        )
    }

    // MARK: - Initial Setup
    func performInitialSetup(with container: ModelContainer) async {
        do {
            let context = container.mainContext
            let descriptor = FetchDescriptor<User>()
            let existing = try context.fetch(descriptor)

            if existing.isEmpty {
                print("No existing user found, waiting for onboarding")
            } else {
                print("Found \(existing.count) existing users")
                // System templates removed - using AI-native generation
            }
        } catch {
            print("Failed to perform initial setup: \(error)")
        }
    }

    // MARK: - AI-Native Generation
    // Template creation removed - AI generates personalized workouts and meals
    // based on user preferences, goals, and available equipment
}

// MARK: - ModelContext Helpers
extension ModelContext {
    func fetchFirst<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        return try fetch(descriptor).first
    }

    func count<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> Int {
        var descriptor = FetchDescriptor<T>()
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        return try fetchCount(descriptor)
    }
}

// MARK: - Preview Support
#if DEBUG
extension DataManager {
    static var preview: DataManager {
        let manager = DataManager()
        // Create in-memory container for previews
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self,
            CoachMessage.self,
            ChatSession.self,
            ConversationSession.self,
            ConversationResponse.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            manager._previewContainer = container
        }
        return manager
    }
    
    static var previewContainer: ModelContainer {
        // Create in-memory container
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: User.self, OnboardingProfile.self, configurations: configuration)
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    private var _previewContainer: ModelContainer? {
        get { nil }
        set { }
    }
    
    var modelContext: ModelContext {
        _previewContainer?.mainContext ?? ModelContainer.createMemoryContainer().mainContext
    }
}

extension ModelContainer {
    static func createMemoryContainer() -> ModelContainer {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self,
            CoachMessage.self,
            ChatSession.self,
            ConversationSession.self,
            ConversationResponse.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
