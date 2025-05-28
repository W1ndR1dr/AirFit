import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var modelContext
    @State var viewModel: WorkoutViewModel
    @State private var selectedTemplate: UserWorkoutTemplate?
    @State private var showingCustomTemplate = false

    private let predefinedTemplates = UserWorkoutTemplate.predefinedTemplates

    var userTemplates: [UserWorkoutTemplate] {
        do {
            return try modelContext.fetch(
                FetchDescriptor<UserWorkoutTemplate>(
                    predicate: #Predicate { $0.isUserCreated == true },
                    sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
                )
            )
        } catch {
            return []
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Quick Start Templates
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        SectionHeader(title: "Quick Start", icon: "bolt.fill")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                            ForEach(predefinedTemplates) { template in
                                TemplateCard(template: template) {
                                    startWorkout(with: template)
                                }
                            }
                        }
                    }

                    // User Templates
                    if !userTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            SectionHeader(title: "My Templates", icon: "person.fill")

                            ForEach(userTemplates) { template in
                                UserTemplateRow(template: template) {
                                    startWorkout(with: template)
                                }
                            }
                        }
                    }

                    // Create Custom
                    Button {
                        showingCustomTemplate = true
                    } label: {
                        Label("Create Custom Workout", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCustomTemplate) {
                WorkoutBuilderView(viewModel: viewModel)
            }
        }
    }

    private func startWorkout(with template: UserWorkoutTemplate) {
        let workout = template.createWorkout()
        modelContext.insert(workout)

        template.lastUsedDate = Date()

        do {
            try modelContext.save()
            viewModel.activeWorkout = workout
            dismiss()

            // Navigate to active workout tracking
            NotificationCenter.default.post(
                name: .startActiveWorkout,
                object: workout
            )
        } catch {
            AppLogger.error("Failed to start workout", error: error, category: .data)
        }
    }
}

// MARK: - Template Card
private struct TemplateCard: View {
    let template: UserWorkoutTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.small) {
                Image(systemName: template.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(template.accentColor.gradient)
                    .frame(height: 44)

                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text("\(template.exercises.count) exercises")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - User Template Row
private struct UserTemplateRow: View {
    let template: UserWorkoutTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(template.name)
                            .font(.headline)

                        HStack(spacing: AppSpacing.medium) {
                            Label("\(template.exercises.count) exercises", systemImage: "list.bullet")
                            if let duration = template.estimatedDuration {
                                Label(duration.formattedDuration(), systemImage: "timer")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - User Workout Template Model
@Model
final class UserWorkoutTemplate {
    var id = UUID()
    var name: String
    var workoutType: String
    var exercises: [TemplateExercise]
    var estimatedDuration: TimeInterval?
    var notes: String?
    var isUserCreated: Bool
    var lastUsedDate: Date?
    var createdDate: Date

    // UI properties
    var iconName: String {
        WorkoutType(rawValue: workoutType)?.systemImage ?? "figure.strengthtraining.traditional"
    }

    var accentColor: Color {
        WorkoutType(rawValue: workoutType)?.color ?? .blue
    }

    init(
        name: String,
        workoutType: String,
        exercises: [TemplateExercise],
        estimatedDuration: TimeInterval? = nil,
        notes: String? = nil,
        isUserCreated: Bool = true
    ) {
        self.name = name
        self.workoutType = workoutType
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.notes = notes
        self.isUserCreated = isUserCreated
        self.createdDate = Date()
    }

    func createWorkout() -> Workout {
        let workout = Workout(
            name: name,
            workoutType: WorkoutType(rawValue: workoutType) ?? .general,
            plannedDate: Date()
        )

        workout.notes = notes

        // Convert template exercises to workout exercises
        for templateExercise in exercises {
            let exercise = Exercise(
                name: templateExercise.name,
                muscleGroups: templateExercise.muscleGroups ?? []
            )
            exercise.notes = templateExercise.notes

            // Add planned sets
            for setTemplate in templateExercise.sets {
                let set = ExerciseSet(
                    setNumber: setTemplate.order,
                    targetReps: setTemplate.targetReps,
                    targetWeightKg: setTemplate.targetWeight
                )
                exercise.sets.append(set)
            }

            workout.exercises.append(exercise)
        }

        return workout
    }

    // Predefined templates
    static var predefinedTemplates: [UserWorkoutTemplate] {
        [
            UserWorkoutTemplate(
                name: "Push Day",
                workoutType: WorkoutType.strength.rawValue,
                exercises: [
                    TemplateExercise(name: "Bench Press", sets: [
                        TemplateSetData(order: 1, targetReps: 12),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8)
                    ]),
                    TemplateExercise(name: "Overhead Press", sets: [
                        TemplateSetData(order: 1, targetReps: 10),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8)
                    ]),
                    TemplateExercise(name: "Dips", sets: [
                        TemplateSetData(order: 1, targetReps: 12),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8)
                    ])
                ],
                estimatedDuration: 45 * 60,
                isUserCreated: false
            ),

            UserWorkoutTemplate(
                name: "Pull Day",
                workoutType: WorkoutType.strength.rawValue,
                exercises: [
                    TemplateExercise(name: "Pull-ups", sets: [
                        TemplateSetData(order: 1, targetReps: 8),
                        TemplateSetData(order: 2, targetReps: 8),
                        TemplateSetData(order: 3, targetReps: 6)
                    ]),
                    TemplateExercise(name: "Barbell Rows", sets: [
                        TemplateSetData(order: 1, targetReps: 12),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8)
                    ]),
                    TemplateExercise(name: "Bicep Curls", sets: [
                        TemplateSetData(order: 1, targetReps: 15),
                        TemplateSetData(order: 2, targetReps: 12),
                        TemplateSetData(order: 3, targetReps: 10)
                    ])
                ],
                estimatedDuration: 45 * 60,
                isUserCreated: false
            ),

            UserWorkoutTemplate(
                name: "Leg Day",
                workoutType: WorkoutType.strength.rawValue,
                exercises: [
                    TemplateExercise(name: "Squats", sets: [
                        TemplateSetData(order: 1, targetReps: 12),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8),
                        TemplateSetData(order: 4, targetReps: 6)
                    ]),
                    TemplateExercise(name: "Romanian Deadlifts", sets: [
                        TemplateSetData(order: 1, targetReps: 12),
                        TemplateSetData(order: 2, targetReps: 10),
                        TemplateSetData(order: 3, targetReps: 8)
                    ]),
                    TemplateExercise(name: "Leg Curls", sets: [
                        TemplateSetData(order: 1, targetReps: 15),
                        TemplateSetData(order: 2, targetReps: 12),
                        TemplateSetData(order: 3, targetReps: 10)
                    ])
                ],
                estimatedDuration: 60 * 60,
                isUserCreated: false
            ),

            UserWorkoutTemplate(
                name: "HIIT Circuit",
                workoutType: WorkoutType.cardio.rawValue,
                exercises: [
                    TemplateExercise(name: "Burpees", sets: [TemplateSetData(order: 1, targetDuration: 45)]),
                    TemplateExercise(name: "Mountain Climbers", sets: [TemplateSetData(order: 1, targetDuration: 45)]),
                    TemplateExercise(name: "Jump Squats", sets: [TemplateSetData(order: 1, targetDuration: 45)]),
                    TemplateExercise(name: "High Knees", sets: [TemplateSetData(order: 1, targetDuration: 45)])
                ],
                estimatedDuration: 20 * 60,
                isUserCreated: false
            )
        ]
    }
}

// MARK: - Template Exercise Model
@Model
final class TemplateExercise {
    var name: String
    var muscleGroups: [String]?
    var notes: String?
    var sets: [TemplateSetData]

    init(name: String, muscleGroups: [String]? = nil, notes: String? = nil, sets: [TemplateSetData] = []) {
        self.name = name
        self.muscleGroups = muscleGroups
        self.notes = notes
        self.sets = sets
    }
}

// MARK: - Template Set Data
struct TemplateSetData: Codable {
    let order: Int
    let targetReps: Int?
    let targetWeight: Double?
    let targetDuration: TimeInterval?

    init(order: Int, targetReps: Int? = nil, targetWeight: Double? = nil, targetDuration: TimeInterval? = nil) {
        self.order = order
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetDuration = targetDuration
    }
}

// MARK: - Notification
extension Notification.Name {
    static let startActiveWorkout = Notification.Name("startActiveWorkout")
}
