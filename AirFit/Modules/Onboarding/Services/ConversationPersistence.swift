import Foundation
import SwiftData

@MainActor
final class ConversationPersistence {
    private let modelContext: ModelContext
    private let maxSessionAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Session Management
    func saveSession(_ session: ConversationSession) throws {
        try modelContext.save()
    }
    
    func fetchActiveSession(for userId: UUID) throws -> ConversationSession? {
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate { session in
                session.userId == userId && session.completedAt == nil
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        let sessions = try modelContext.fetch(descriptor)
        
        // Return most recent incomplete session if it's not too old
        if let mostRecent = sessions.first,
           Date().timeIntervalSince(mostRecent.startedAt) < maxSessionAge {
            return mostRecent
        }
        
        return nil
    }
    
    func fetchCompletedSessions(for userId: UUID, limit: Int = 10) throws -> [ConversationSession] {
        var descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate { session in
                session.userId == userId && session.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    func deleteSession(_ session: ConversationSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }
    
    // MARK: - Cleanup
    func cleanupOldSessions() async throws {
        let cutoffDate = Date().addingTimeInterval(-maxSessionAge)
        
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate { session in
                session.startedAt < cutoffDate && session.completedAt == nil
            }
        )
        
        let oldSessions = try modelContext.fetch(descriptor)
        
        for session in oldSessions {
            modelContext.delete(session)
        }
        
        if !oldSessions.isEmpty {
            try modelContext.save()
            print("Cleaned up \(oldSessions.count) old conversation sessions")
        }
    }
    
    // MARK: - Progress Tracking
    func updateProgress(for session: ConversationSession, nodeId: String, responseCount: Int, totalNodes: Int) throws {
        session.currentNodeId = nodeId
        session.completionPercentage = Double(responseCount) / Double(totalNodes)
        try modelContext.save()
    }
    
    // MARK: - Response Management
    func addResponse(to session: ConversationSession, response: ConversationResponse) throws {
        session.responses.append(response)
        try modelContext.save()
    }
    
    func getResponses(for session: ConversationSession) -> [ConversationResponse] {
        return session.responses.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Insights Management
    func saveInsights(_ insights: PersonalityInsights, for session: ConversationSession) throws {
        session.extractedInsights = try JSONEncoder().encode(insights)
        try modelContext.save()
    }
    
    func loadInsights(from session: ConversationSession) throws -> PersonalityInsights? {
        guard let data = session.extractedInsights else { return nil }
        return try JSONDecoder().decode(PersonalityInsights.self, from: data)
    }
    
    // MARK: - Export/Import
    func exportSession(_ session: ConversationSession) throws -> Data {
        let export = ConversationExport(
            session: session,
            responses: getResponses(for: session),
            insights: try? loadInsights(from: session)
        )
        
        return try JSONEncoder().encode(export)
    }
    
    func importSession(from data: Data, userId: UUID) throws -> ConversationSession {
        let export = try JSONDecoder().decode(ConversationExport.self, from: data)
        
        // Create new session with imported data
        let session = ConversationSession(userId: userId)
        session.startedAt = export.session.startedAt
        session.completedAt = export.session.completedAt
        session.currentNodeId = export.session.currentNodeId
        session.completionPercentage = export.session.completionPercentage
        
        if let insights = export.insights {
            session.extractedInsights = try JSONEncoder().encode(insights)
        }
        
        modelContext.insert(session)
        
        // Add responses
        for response in export.responses {
            let newResponse = ConversationResponse(
                nodeId: response.nodeId,
                responseType: response.responseType,
                responseData: response.responseData
            )
            newResponse.timestamp = response.timestamp
            newResponse.processingTime = response.processingTime
            session.responses.append(newResponse)
        }
        
        try modelContext.save()
        return session
    }
}

// MARK: - Export Model
private struct ConversationExport: Codable {
    let session: SessionData
    let responses: [ResponseData]
    let insights: PersonalityInsights?
    
    struct SessionData: Codable {
        let startedAt: Date
        let completedAt: Date?
        let currentNodeId: String
        let completionPercentage: Double
    }
    
    struct ResponseData: Codable {
        let nodeId: String
        let responseType: String
        let responseData: Data
        let timestamp: Date
        let processingTime: TimeInterval
    }
    
    init(session: ConversationSession, responses: [ConversationResponse], insights: PersonalityInsights?) {
        self.session = SessionData(
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            currentNodeId: session.currentNodeId,
            completionPercentage: session.completionPercentage
        )
        
        self.responses = responses.map { response in
            ResponseData(
                nodeId: response.nodeId,
                responseType: response.responseType,
                responseData: response.responseData,
                timestamp: response.timestamp,
                processingTime: response.processingTime
            )
        }
        
        self.insights = insights
    }
}