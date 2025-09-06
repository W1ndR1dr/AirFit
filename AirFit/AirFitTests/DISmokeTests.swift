import XCTest
import SwiftData
@testable import AirFit

final class DISmokeTests: XCTestCase {
    func testCoreServicesResolve() async throws {
        let container = try TestSupport.makeAppDIContainer()

        // Resolve a few essential services; this should not construct heavy dependencies yet
        let ai: AIServiceProtocol = try await container.resolve(AIServiceProtocol.self)
        _ = ai  // silence unused warning

        let userService: UserServiceProtocol = try await container.resolve(UserServiceProtocol.self)
        _ = userService

        let healthKit: HealthKitManaging = try await container.resolve(HealthKitManaging.self)
        _ = healthKit

        let nutritionCalc: NutritionCalculatorProtocol = try await container.resolve(NutritionCalculatorProtocol.self)
        _ = nutritionCalc
    }
}

