import Foundation
import SwiftData
import CryptoKit

// MARK: - Exercise Info for AI Services
struct ExerciseInfo: Sendable {
    let id: String
    let name: String
    let primaryMuscles: [String]
    let equipment: [String]
    let category: String
}

// MARK: - Exercise Definition Model
@Model
final class ExerciseDefinition: Identifiable, Codable {
    @Attribute(.unique)
    var id: String
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var equipment: [Equipment]
    var instructions: [String]
    var tips: [String]
    var commonMistakes: [String]
    var difficulty: Difficulty
    var isCompound: Bool
    var imageNames: [String]
    var force: String?
    var mechanic: String?

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        muscleGroups: [MuscleGroup],
        equipment: [Equipment],
        instructions: [String],
        tips: [String] = [],
        commonMistakes: [String] = [],
        difficulty: Difficulty,
        isCompound: Bool,
        imageNames: [String],
        force: String? = nil,
        mechanic: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.tips = tips
        self.commonMistakes = commonMistakes
        self.difficulty = difficulty
        self.isCompound = isCompound
        self.imageNames = imageNames
        self.force = force
        self.mechanic = mechanic
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, category, muscleGroups, equipment, instructions
        case tips, commonMistakes, difficulty, isCompound, imageNames
        case force, mechanic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(ExerciseCategory.self, forKey: .category)
        muscleGroups = try container.decode([MuscleGroup].self, forKey: .muscleGroups)
        equipment = try container.decode([Equipment].self, forKey: .equipment)
        instructions = try container.decode([String].self, forKey: .instructions)
        tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        commonMistakes = try container.decodeIfPresent([String].self, forKey: .commonMistakes) ?? []
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        isCompound = try container.decode(Bool.self, forKey: .isCompound)
        imageNames = try container.decode([String].self, forKey: .imageNames)
        force = try container.decodeIfPresent(String.self, forKey: .force)
        mechanic = try container.decodeIfPresent(String.self, forKey: .mechanic)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(muscleGroups, forKey: .muscleGroups)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(tips, forKey: .tips)
        try container.encode(commonMistakes, forKey: .commonMistakes)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(isCompound, forKey: .isCompound)
        try container.encode(imageNames, forKey: .imageNames)
        try container.encodeIfPresent(force, forKey: .force)
        try container.encodeIfPresent(mechanic, forKey: .mechanic)
    }
}

// MARK: - Raw Exercise Data (for parsing)
private struct RawExerciseData: Codable {
    let name: String
    let force: String?
    let level: String
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let category: String
    let images: [String]
    let id: String
}

// MARK: - Exercise Database
@MainActor
final class ExerciseDatabase: ObservableObject, ServiceProtocol {
    @Published private(set) var isLoading = false
    @Published private(set) var loadingProgress: Double = 0
    @Published private(set) var error: ExerciseDatabaseError?

    private let container: ModelContainer
    private var exercises: [ExerciseDefinition] = []
    private let cacheQueue = DispatchQueue(label: "exercise.cache", qos: .utility)

    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "exercise-database"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    init(container: ModelContainer? = nil) {
        do {
            self.container = try container ?? ModelContainer(for: ExerciseDefinition.self)
        } catch {
            AppLogger.error("Failed to initialize ExerciseDatabase, using in-memory container", error: error, category: .data)
            // Create an in-memory container as fallback
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                self.container = try ModelContainer(for: ExerciseDefinition.self, configurations: configuration)
            } catch {
                // This should never fail for in-memory container, but handle it gracefully
                AppLogger.fault("Failed to create in-memory container for ExerciseDatabase: \(error)", category: .data)
                // Final fallback: attempt schema-based in-memory container; if this fails, keep an empty database state
                let schema = Schema([ExerciseDefinition.self])
                if let fallback = try? ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]) {
                    self.container = fallback
                } else {
                    // As a last resort, log and create a best-effort in-memory container on a background schema
                    AppLogger.fault("All ExerciseDatabase container fallbacks failed; operating with empty in-memory store", category: .data)
                    // This will create a container but further fetches may return empty; avoids a hard crash
                    self.container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                }
            }
            self.exercises = []
        }
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        await initializeDatabase()
        _isConfigured = true
        AppLogger.info("ExerciseDatabase configured", category: .data)
    }

    func reset() async {
        exercises.removeAll()
        _isConfigured = false
        AppLogger.info("ExerciseDatabase reset", category: .data)
    }

    nonisolated func healthCheck() async -> ServiceHealth {
        await MainActor.run {
            let hasExercises = !exercises.isEmpty
            let status: ServiceHealth.Status = hasExercises ? .healthy : .degraded

            return ServiceHealth(
                status: status,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: hasExercises ? nil : "No exercises loaded",
                metadata: [
                    "exerciseCount": "\(exercises.count)",
                    "isLoading": "\(isLoading)"
                ]
            )
        }
    }

    // MARK: - Public API
    func getAllExercises() async throws -> [ExerciseDefinition] {
        if exercises.isEmpty {
            exercises = try container.mainContext.fetch(FetchDescriptor<ExerciseDefinition>())
        }
        return exercises
    }

    func searchExercises(query: String) async -> [ExerciseDefinition] {
        guard !query.isEmpty else { return exercises }

        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.name.localizedStandardContains(query) ||
                exercise.instructions.contains { $0.localizedStandardContains(query) }
        }

        return (try? container.mainContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    func getExercisesByMuscleGroup(_ muscleGroup: MuscleGroup) async -> [ExerciseDefinition] {
        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.muscleGroups.contains(muscleGroup)
        }
        return (try? container.mainContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    func getExercisesByCategory(_ category: ExerciseCategory) async -> [ExerciseDefinition] {
        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.category == category
        }
        return (try? container.mainContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    func getExercisesByEquipment(_ equipment: Equipment) async -> [ExerciseDefinition] {
        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.equipment.contains(equipment)
        }
        return (try? container.mainContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    func getExercisesByDifficulty(_ difficulty: Difficulty) async -> [ExerciseDefinition] {
        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.difficulty == difficulty
        }
        return (try? container.mainContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    func getExercise(by id: String) async -> ExerciseDefinition? {
        let predicate = #Predicate<ExerciseDefinition> { exercise in
            exercise.id == id
        }
        return try? container.mainContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    // MARK: - AI Service Support

    func filterExercises(equipment: [String]? = nil, primaryMuscles: [String]? = nil) async -> [ExerciseInfo] {
        var filteredExercises = exercises

        // Filter by equipment if specified
        if let equipment = equipment, !equipment.isEmpty {
            let equipmentSet = Set(equipment.map { $0.lowercased() })
            filteredExercises = filteredExercises.filter { exercise in
                exercise.equipment.contains { equip in
                    equipmentSet.contains(equip.rawValue.lowercased())
                }
            }
        }

        // Filter by primary muscles if specified
        if let muscles = primaryMuscles, !muscles.isEmpty {
            let muscleSet = Set(muscles.map { $0.lowercased() })
            filteredExercises = filteredExercises.filter { exercise in
                exercise.muscleGroups.contains { muscle in
                    muscleSet.contains(muscle.displayName.lowercased())
                }
            }
        }

        // Convert to ExerciseInfo for AI service
        return filteredExercises.map { exercise in
            ExerciseInfo(
                id: exercise.id,
                name: exercise.name,
                primaryMuscles: exercise.muscleGroups.map { $0.displayName },
                equipment: exercise.equipment.map { $0.displayName },
                category: exercise.category.displayName
            )
        }
    }

    // MARK: - Private Methods
    private func initializeDatabase() async {
        do {
            let count = try container.mainContext.fetchCount(FetchDescriptor<ExerciseDefinition>())
            // swiftlint:disable:next empty_count
            if count == 0 {
                await seedDatabase()
            } else {
                exercises = try container.mainContext.fetch(FetchDescriptor<ExerciseDefinition>())
                AppLogger.info("ExerciseDatabase loaded with \(exercises.count) exercises", category: .data)
            }
        } catch {
            await handleError(.initializationFailed(error))
        }
    }

    private func seedDatabase() async {
        isLoading = true
        loadingProgress = 0

        do {
            guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json", subdirectory: "Resources/SeedData") else {
                throw ExerciseDatabaseError.seedDataNotFound
            }

            AppLogger.info("Loading exercise data from bundle", category: .data)
            let data = try Data(contentsOf: url)
            let rawExercises = try JSONDecoder().decode([RawExerciseData].self, from: data)

            AppLogger.info("Processing \(rawExercises.count) exercises", category: .data)

            let totalCount = Double(rawExercises.count)
            var processedCount = 0.0

            for rawExercise in rawExercises {
                let exercise = try transformRawExercise(rawExercise)
                container.mainContext.insert(exercise)

                processedCount += 1
                loadingProgress = processedCount / totalCount

                // Batch save every 50 exercises for performance
                if Int(processedCount).isMultiple(of: 50) {
                    try container.mainContext.save()
                }
            }

            // Final save
            try container.mainContext.save()

            // Load into memory cache
            exercises = try container.mainContext.fetch(FetchDescriptor<ExerciseDefinition>())

            AppLogger.info("Successfully seeded ExerciseDatabase with \(exercises.count) exercises", category: .data)

        } catch {
            await handleError(.seedingFailed(error))
        }

        isLoading = false
        loadingProgress = 1.0
    }

    private func transformRawExercise(_ raw: RawExerciseData) throws -> ExerciseDefinition {
        // Generate stable ID
        let idString = "\(raw.name)-\(raw.equipment ?? "none")"
        let idData = Data(idString.utf8)
        let hash = SHA256.hash(data: idData)
        let id = hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).lowercased()

        // Map category
        let category = ExerciseCategory.fromRawValue(raw.category)

        // Map muscle groups
        let primaryMuscles = raw.primaryMuscles.compactMap(MuscleGroup.fromRawValue)
        let secondaryMuscles = raw.secondaryMuscles.compactMap(MuscleGroup.fromRawValue)
        let allMuscles = Array(Set(primaryMuscles + secondaryMuscles))

        // Map equipment
        let equipment = raw.equipment.map { Equipment.fromRawValue($0) } ?? [.bodyweight]

        // Map difficulty
        let difficulty = Difficulty.fromRawValue(raw.level)

        // Determine if compound
        let isCompound = raw.mechanic?.lowercased() == "compound" || allMuscles.count > 1

        // Process image names (remove path, keep filename)
        let imageNames = raw.images.map { imagePath in
            URL(fileURLWithPath: imagePath).lastPathComponent
        }

        return ExerciseDefinition(
            id: String(id),
            name: raw.name,
            category: category,
            muscleGroups: allMuscles,
            equipment: equipment,
            instructions: raw.instructions,
            tips: [], // Can be populated later
            commonMistakes: [], // Can be populated later
            difficulty: difficulty,
            isCompound: isCompound,
            imageNames: imageNames,
            force: raw.force,
            mechanic: raw.mechanic
        )
    }

    private func handleError(_ error: ExerciseDatabaseError) async {
        self.error = error
        isLoading = false
        AppLogger.error("ExerciseDatabase error", error: error, category: .data)
    }
}

// MARK: - Exercise Database Error
enum ExerciseDatabaseError: LocalizedError {
    case seedDataNotFound
    case initializationFailed(Error)
    case seedingFailed(Error)
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .seedDataNotFound:
            return "Exercise seed data not found in bundle"
        case .initializationFailed(let error):
            return "Failed to initialize database: \(error.localizedDescription)"
        case .seedingFailed(let error):
            return "Failed to seed database: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Database query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Enum Extensions for Mapping
extension ExerciseCategory {
    static func fromRawValue(_ raw: String) -> ExerciseCategory {
        switch raw.lowercased() {
        case "strength": return .strength
        case "cardio": return .cardio
        case "stretching": return .flexibility
        case "plyometrics": return .plyometrics
        case "powerlifting": return .strength
        case "strongman": return .strength
        case "olympic weightlifting": return .strength
        default: return .strength
        }
    }
}

extension MuscleGroup {
    static func fromRawValue(_ raw: String) -> MuscleGroup? {
        switch raw.lowercased() {
        case "abdominals", "abs": return .abs
        case "biceps": return .biceps
        case "triceps": return .triceps
        case "chest", "pectorals": return .chest
        case "shoulders", "deltoids": return .shoulders
        case "quadriceps", "quads": return .quads
        case "hamstrings": return .hamstrings
        case "glutes": return .glutes
        case "calves": return .calves
        case "lats", "latissimus dorsi": return .lats
        case "middle back", "rhomboids": return .middleBack
        case "lower back": return .lowerBack
        case "traps", "trapezius": return .traps
        case "forearms": return .forearms
        case "adductors": return .adductors
        case "abductors": return .abductors
        default: return nil
        }
    }
}

extension Equipment {
    static func fromRawValue(_ raw: String) -> [Equipment] {
        switch raw.lowercased() {
        case "body only", "bodyweight": return [.bodyweight]
        case "dumbbell": return [.dumbbells]
        case "barbell": return [.barbell]
        case "kettlebells": return [.kettlebells]
        case "cable": return [.cables]
        case "machine": return [.machine]
        case "bands": return [.resistanceBands]
        case "foam roll": return [.foamRoller]
        case "medicine ball": return [.medicineBall]
        case "exercise ball": return [.stabilityBall]
        case "other": return [.other]
        default: return [.other]
        }
    }
}

extension Difficulty {
    static func fromRawValue(_ raw: String) -> Difficulty {
        switch raw.lowercased() {
        case "beginner": return .beginner
        case "intermediate": return .intermediate
        case "expert", "advanced": return .advanced
        default: return .intermediate
        }
    }
}
