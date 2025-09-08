import Foundation
import SwiftData

/// Service adapter that wraps the existing UserDataExporter for DI
@MainActor
final class UserDataExporterService: DataExporterProtocol {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func exportAllData(for user: User) async throws -> URL {
        let exporter = UserDataExporter(modelContext: modelContainer.mainContext)
        return try await exporter.exportAllData(for: user)
    }
}