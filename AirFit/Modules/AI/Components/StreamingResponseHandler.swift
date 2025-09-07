import Foundation

@MainActor
final class StreamingResponseHandler {
    // MARK: - Types

    struct StreamingResult {
        let fullResponse: String
        let functionCall: AIFunctionCall?
        let tokenUsage: Int
        let timeToFirstToken: TimeInterval?
        let totalTime: TimeInterval
    }

    struct StreamingState {
        var fullResponse = ""
        var tokens: [String] = []
        var functionCall: AIFunctionCall?
        var tokenUsage = 0
        var firstTokenTime: TimeInterval?
        let startTime: CFAbsoluteTime

        init() {
            self.startTime = CFAbsoluteTimeGetCurrent()
        }
    }

    // MARK: - Properties

    weak var delegate: StreamingResponseDelegate?
    private let routingConfiguration: RoutingConfiguration?

    // MARK: - Initialization

    init(routingConfiguration: RoutingConfiguration? = nil) {
        self.routingConfiguration = routingConfiguration
    }

    // MARK: - Streaming Handler

    /// Processes an AI response stream and returns the complete result
    func handleStream(
        _ stream: AsyncThrowingStream<AIResponse, Error>,
        routingStrategy: RoutingStrategy? = nil
    ) async throws -> StreamingResult {
        var state = StreamingState()

        do {
            for try await response in stream {
                try await processResponse(response, state: &state)
            }

            let totalTime = CFAbsoluteTimeGetCurrent() - state.startTime

            let result = StreamingResult(
                fullResponse: state.fullResponse,
                functionCall: state.functionCall,
                tokenUsage: state.tokenUsage,
                timeToFirstToken: state.firstTokenTime,
                totalTime: totalTime
            )

            // Log performance metrics
            logPerformanceMetrics(result, routingStrategy: routingStrategy)

            return result

        } catch {
            AppLogger.error("Stream processing failed", error: error, category: .ai)

            // Notify delegate of error
            await delegate?.streamingDidFail(with: error)

            throw error
        }
    }

    /// Collects all text from a stream without processing
    func collectText(from stream: AsyncThrowingStream<AIResponse, Error>) async throws -> String {
        var result = ""
        for try await response in stream {
            switch response {
            case .text(let text), .textDelta(let text):
                result += text
            case .error(let error):
                throw error
            default:
                break
            }
        }
        return result
    }

    /// Collects text and token usage for callers that want both
    func collectTextWithUsage(from stream: AsyncThrowingStream<AIResponse, Error>) async throws -> (String, Int?) {
        var result = ""
        var usage: Int?
        for try await response in stream {
            switch response {
            case .text(let text), .textDelta(let text):
                result += text
            case .done(let u):
                usage = u?.totalTokens
            case .error(let error):
                throw error
            default:
                break
            }
        }
        return (result, usage)
    }

    // MARK: - Private Helpers

    private func processResponse(
        _ response: AIResponse,
        state: inout StreamingState
    ) async throws {
        switch response {
        case .text(let text):
            handleTextResponse(text, state: &state)

        case .textDelta(let delta):
            handleTextDelta(delta, state: &state)

        case .functionCall(let call):
            handleFunctionCall(call, state: &state)

        case .structuredData(let data):
            // Handle structured data as text
            if let jsonString = String(data: data, encoding: .utf8) {
                handleTextResponse(jsonString, state: &state)
            }

        case .done(let usage):
            handleCompletion(usage, state: &state)

        case .error(let error):
            throw error
        }
    }

    private func handleTextResponse(_ text: String, state: inout StreamingState) {
        if state.firstTokenTime == nil {
            let timeToFirstToken = CFAbsoluteTimeGetCurrent() - state.startTime
            state.firstTokenTime = timeToFirstToken
            logFirstToken(timeToFirstToken)
        }

        state.fullResponse += text
        state.tokens.append(text)

        let accumulated = state.fullResponse
        Task {
            await delegate?.streamingDidReceiveText(text, accumulated: accumulated)
        }
    }

    private func handleTextDelta(_ delta: String, state: inout StreamingState) {
        if state.firstTokenTime == nil {
            let timeToFirstToken = CFAbsoluteTimeGetCurrent() - state.startTime
            state.firstTokenTime = timeToFirstToken
            logFirstToken(timeToFirstToken)
        }

        state.fullResponse += delta
        state.tokens.append(delta)

        let accumulated = state.fullResponse
        Task {
            await delegate?.streamingDidReceiveText(delta, accumulated: accumulated)
        }
    }

    private func handleFunctionCall(_ call: AIFunctionCall, state: inout StreamingState) {
        state.functionCall = call

        AppLogger.info("Function call detected: \(call.name)", category: .ai)

        Task {
            await delegate?.streamingDidDetectFunction(call)
        }
    }

    private func handleCompletion(_ usage: AITokenUsage?, state: inout StreamingState) {
        if let usage = usage {
            state.tokenUsage = usage.totalTokens
        }

        AppLogger.debug("Stream completed: \(state.tokenUsage) tokens", category: .ai)

        let fullResponse = state.fullResponse
        let tokenUsage = state.tokenUsage
        Task {
            await delegate?.streamingDidComplete(
                fullResponse: fullResponse,
                tokenUsage: tokenUsage
            )
        }
    }

    private func logFirstToken(_ timeToFirstToken: TimeInterval) {
        AppLogger.info(
            "First token received in \(Int(timeToFirstToken * 1_000))ms",
            category: .ai
        )
    }

    private func logPerformanceMetrics(
        _ result: StreamingResult,
        routingStrategy: RoutingStrategy?
    ) {
        let metrics: [String: Any] = [
            "totalTime": Int(result.totalTime * 1_000),
            "timeToFirstToken": result.timeToFirstToken.map { Int($0 * 1_000) } ?? -1,
            "tokenUsage": result.tokenUsage,
            "hasFunction": result.functionCall != nil,
            "responseLength": result.fullResponse.count
        ]

        AppLogger.info(
            "Stream metrics: \(metrics.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))",
            category: .ai
        )

        // Record routing metrics if strategy provided
        if let strategy = routingStrategy {
            let routingMetrics = RoutingMetrics(
                route: strategy.route,
                executionTimeMs: Int(result.totalTime * 1_000),
                success: true,
                tokenUsage: result.tokenUsage > 0 ? result.tokenUsage : nil,
                confidence: nil,
                fallbackUsed: false
            )

            routingConfiguration?.recordRoutingMetrics(routingMetrics)
        }
    }
}

// MARK: - StreamingResponseDelegate

@MainActor
protocol StreamingResponseDelegate: AnyObject {
    func streamingDidReceiveText(_ text: String, accumulated: String) async
    func streamingDidDetectFunction(_ function: AIFunctionCall) async
    func streamingDidComplete(fullResponse: String, tokenUsage: Int) async
    func streamingDidFail(with error: Error) async
}
