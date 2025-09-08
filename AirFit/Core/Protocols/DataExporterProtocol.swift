import Foundation

/// Protocol for exporting user data without exposing SwiftData to ViewModels
@MainActor
protocol DataExporterProtocol: AnyObject {
    func exportAllData(for user: User) async throws -> URL
}