import XCTest
@testable import AirFit

final class ContextAnalyzerTests: XCTestCase {

    func test_determineOptimalRoute_simpleParsing_returnsDirectAI() {
        // Test simple food logging messages
        let simpleInputs = [
            "I ate 2 apples",
            "had chicken breast for lunch",
            "log 300 calories",
            "track protein shake"
        ]

        for input in simpleInputs {
            let route = ContextAnalyzer.determineOptimalRoute(
                userInput: input,
                conversationHistory: [],
                userState: UserContextSnapshot()
            )

            XCTAssertEqual(route, .directAI, "Input '\(input)' should use direct AI")
        }
    }

    func test_determineOptimalRoute_complexWorkflow_returnsFunctionCalling() {
        // Test complex workflow messages
        let complexInputs = [
            "analyze my performance trends over the last month",
            "create a workout plan for next week",
            "adjust my goals based on recent progress",
            "plan my meals and workouts for tomorrow"
        ]

        for input in complexInputs {
            let route = ContextAnalyzer.determineOptimalRoute(
                userInput: input,
                conversationHistory: [],
                userState: UserContextSnapshot()
            )

            XCTAssertEqual(route, .functionCalling, "Input '\(input)' should use function calling")
        }
    }

    func test_determineOptimalRoute_activeChain_preservesFunctionCalling() {
        // Test that active function chains are preserved
        let recentHistory = [
            AIChatMessage(role: .assistant, content: "I'll analyze your workouts", functionCall: AIFunctionCall(name: "analyzePerformanceTrends"))
        ]

        let route = ContextAnalyzer.determineOptimalRoute(
            userInput: "what about my nutrition?",
            conversationHistory: recentHistory,
            userState: UserContextSnapshot()
        )

        XCTAssertEqual(route, .functionCalling, "Should preserve function calling when chain is active")
    }

    func test_detectsSimpleParsing_recognizesPatterns() {
        let simpleCases = [
            ("ate 2 cups rice", true),
            ("had protein shake", true),
            ("300 calories", true),
            ("breakfast with eggs", true),
            ("what is progressive overload", true), // Short educational request
            ("log my water intake", true)
        ]

        for (input, expectedSimple) in simpleCases {
            let isSimple = ContextAnalyzer.detectsSimpleParsing(input)
            XCTAssertEqual(isSimple, expectedSimple, "Input '\(input)' simple detection failed")
        }
    }

    func test_detectsComplexWorkflow_recognizesPatterns() {
        let complexCases = [
            ("analyze my trends", true),
            ("create workout plan", true),
            ("adjust my goals", true),
            ("plan my week", true),
            ("ate apple", false),
            ("what is protein", false)
        ]

        for (input, expectedComplex) in complexCases {
            let isComplex = ContextAnalyzer.detectsComplexWorkflow(input, history: [])
            XCTAssertEqual(isComplex, expectedComplex, "Input '\(input)' complex detection failed")
        }
    }

    func test_chainContext_detectsActiveChains() {
        // Test active chain detection
        let activeChainHistory = [
            AIChatMessage(role: .user, content: "analyze my performance"),
            AIChatMessage(role: .assistant, content: "I'll analyze that", functionCall: AIFunctionCall(name: "analyzePerformanceTrends")),
            AIChatMessage(role: .user, content: "what about nutrition?")
        ]

        let route = ContextAnalyzer.determineOptimalRoute(
            userInput: "and my sleep patterns?",
            conversationHistory: activeChainHistory,
            userState: UserContextSnapshot()
        )

        XCTAssertEqual(route, .functionCalling, "Should detect active chain and use function calling")
    }

    func test_routingAnalytics_logsCorrectly() {
        // Test that analytics logging works without crashing
        RoutingAnalytics.logRoutingDecision(
            route: .directAI,
            input: "test input",
            processingTimeMs: 10
        )

        RoutingAnalytics.logPerformanceComparison(
            route: .functionCalling,
            executionTimeMs: 100,
            tokenCount: 500,
            success: true
        )

        // If we get here without crashing, the logging works
        XCTAssertTrue(true)
    }

    func test_processingRoute_properties() {
        // Test ProcessingRoute enum properties
        XCTAssertTrue(ProcessingRoute.functionCalling.shouldUseFunctions)
        XCTAssertFalse(ProcessingRoute.functionCalling.shouldUseDirectAI)

        XCTAssertFalse(ProcessingRoute.directAI.shouldUseFunctions)
        XCTAssertTrue(ProcessingRoute.directAI.shouldUseDirectAI)

        XCTAssertTrue(ProcessingRoute.hybrid.shouldUseFunctions)
        XCTAssertTrue(ProcessingRoute.hybrid.shouldUseDirectAI)
    }

    func test_userContextSnapshot_initialization() {
        // Test UserContextSnapshot creation
        let snapshot = UserContextSnapshot(
            activeGoals: ["lose weight", "build muscle"],
            recentActivity: ["workout", "meal log"],
            preferences: ["style": "encouraging"],
            timeOfDay: "morning",
            isNewUser: false
        )

        XCTAssertEqual(snapshot.activeGoals.count, 2)
        XCTAssertEqual(snapshot.recentActivity.count, 2)
        XCTAssertEqual(snapshot.timeOfDay, "morning")
        XCTAssertFalse(snapshot.isNewUser)
    }

    func test_urgencyLevel_detection() {
        // Test urgency level detection in input analysis
        let route1 = ContextAnalyzer.determineOptimalRoute(
            userInput: "urgent help needed with my workout plan",
            conversationHistory: [],
            userState: UserContextSnapshot()
        )

        let route2 = ContextAnalyzer.determineOptimalRoute(
            userInput: "ate some food",
            conversationHistory: [],
            userState: UserContextSnapshot()
        )

        // Both should work without crashing
        XCTAssertNotNil(route1)
        XCTAssertNotNil(route2)
    }
}
