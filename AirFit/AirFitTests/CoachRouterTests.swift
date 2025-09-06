import XCTest
@testable import AirFit

final class CoachRouterTests: XCTestCase {

    @MainActor
    func testForcedRouteOverridesHeuristics() async throws {
        let routing = RoutingConfiguration()
        routing.updateConfiguration(forcedRoute: .functionCalling)
        let router = CoachRouter(routingConfiguration: routing)

        let strategy = router.route(
            userInput: "2 cups rice",
            history: [],
            userContext: UserContextSnapshot(),
            userId: UUID()
        )

        XCTAssertEqual(strategy.route, .functionCalling)
        XCTAssertTrue(strategy.fallbackEnabled)
        XCTAssertEqual(strategy.reason.contains("Forced route"), true)
    }

    @MainActor
    func testSimpleParsingChoosesDirectAI() async throws {
        let routing = RoutingConfiguration()
        routing.updateConfiguration(forcedRoute: nil, hybridRoutingEnabled: true)
        let router = CoachRouter(routingConfiguration: routing)

        let strategy = router.route(
            userInput: "ate 2 eggs and 1 cup oatmeal",
            history: [],
            userContext: UserContextSnapshot(),
            userId: UUID()
        )

        XCTAssertEqual(strategy.route, .directAI, "Expected directAI for simple nutrition parsing input")
        XCTAssertTrue(strategy.fallbackEnabled)
    }

    @MainActor
    func testComplexWorkflowChoosesFunctionCalling() async throws {
        let routing = RoutingConfiguration()
        routing.updateConfiguration(forcedRoute: nil, hybridRoutingEnabled: true)
        let router = CoachRouter(routingConfiguration: routing)

        let input = "Plan my workouts for next week and then adjust macros after that"
        let strategy = router.route(
            userInput: input,
            history: [],
            userContext: UserContextSnapshot(),
            userId: UUID()
        )

        XCTAssertEqual(strategy.route, .functionCalling, "Expected functionCalling for complex planning workflow input")
    }
}

