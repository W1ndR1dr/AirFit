@testable import AirFit
import Foundation
import SwiftData

@MainActor
final class MockOnboardingService: OnboardingServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    var saveProfileCalled = false
    var saveProfileError: Error?
    private let modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    func saveProfile(_ profile: OnboardingProfile) async throws {
        recordInvocation(#function, arguments: profile)
        saveProfileCalled = true
        
        if let error = saveProfileError {
            throw error
        }
        
        // Actually save to context if provided (for realistic testing)
        if let context = modelContext {
            // Find or create a user
            let userDescriptor = FetchDescriptor<User>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let users = try modelContext.fetch(userDescriptor)
            
            let currentUser: User
            if let existingUser = users.first {
                currentUser = existingUser
            } else {
                // Create a test user
                currentUser = User(
                    email: "test@example.com",
                    name: "Test User"
                )
                modelContext.insert(currentUser)
            }
            
            // Link the profile to the user
            profile.user = currentUser
            currentUser.onboardingProfile = profile
            
            // Save to SwiftData
            modelContext.insert(profile)
            try modelContext.save()
        }
    }
    
    func reset() {
        invocations.removeAll()
        stubbedResults.removeAll()
        saveProfileCalled = false
        saveProfileError = nil
    }
}
