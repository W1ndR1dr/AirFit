import Foundation

extension CoachEngine {
    func handleFunctionCall(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID
    ) async throws {
        let start = CFAbsoluteTimeGetCurrent()
        AppLogger.info("Executing function: \(functionCall.name)", category: .ai)

        let result = await orchestrator.functionCall(functionCall, user: user, conversationId: conversationId)
        _ = try await conversationManager.createAssistantMessage(
            result,
            for: user,
            conversationId: conversationId,
            functionCall: FunctionCall(name: functionCall.name, arguments: functionCall.arguments.mapValues { AnyCodable($0.value) }),
            isLocalCommand: false,
            isError: false
        )

        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        AppLogger.info("Function \(functionCall.name) completed in \(ms)ms", category: .ai)
    }
}
