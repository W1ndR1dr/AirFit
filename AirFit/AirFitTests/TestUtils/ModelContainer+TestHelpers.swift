import SwiftData

extension ModelContainer {
    /// Creates an in-memory container for the specified models.
    static func makeInMemoryContainer(for schemas: [any PersistentModel.Type]) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schemas, configurations: config)
    }
}
