import Foundation

/// Workout planning AI functions for the CoachEngine.
enum WorkoutFunctions {

    /// Creates personalized workout plans based on user goals, context, and preferences.
    static let generatePersonalizedWorkoutPlan = AIFunctionDefinition(
        name: "generatePersonalizedWorkoutPlan",
        description: """
        Creates a new, tailored workout plan considering the user's specific goals, current fitness level,
        available time, equipment, and contextual factors like energy level and recent activity.
        Adapts to user feedback and preferences for optimal personalization.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "goalFocus": AIParameterDefinition(
                    type: "string",
                    description: "Primary training goal for this workout plan",
                    enumValues: [
                        "strength", "hypertrophy", "endurance", "power", "mobility",
                        "active_recovery", "general_fitness", "sport_specific"
                    ]
                ),
                "durationMinutes": AIParameterDefinition(
                    type: "integer",
                    description: "Target workout duration in minutes",
                    minimum: 15,
                    maximum: 180
                ),
                "intensityPreference": AIParameterDefinition(
                    type: "string",
                    description: "Desired workout intensity level",
                    enumValues: ["light", "moderate", "high", "variable", "auto"]
                ),
                "targetMuscleGroups": AIParameterDefinition(
                    type: "array",
                    description: "Specific muscle groups to emphasize in this workout",
                    items: AIBox(AIParameterDefinition(
                        type: "string",
                        description: "Muscle group to target",
                        enumValues: [
                            "chest", "back", "shoulders", "biceps", "triceps", "forearms",
                            "core", "glutes", "quadriceps", "hamstrings", "calves", "full_body"
                        ]
                    ))
                ),
                "availableEquipment": AIParameterDefinition(
                    type: "array",
                    description: "Equipment available for this workout",
                    items: AIBox(AIParameterDefinition(
                        type: "string",
                        description: "Available equipment",
                        enumValues: [
                            "bodyweight", "dumbbells", "barbell", "resistance_bands", "kettlebells",
                            "pull_up_bar", "bench", "squat_rack", "cable_machine", "cardio_equipment", "full_gym"
                        ]
                    ))
                ),
                "constraints": AIParameterDefinition(
                    type: "string",
                    description: "Any physical limitations, injuries, or special requirements to consider"
                ),
                "workoutStyle": AIParameterDefinition(
                    type: "string",
                    description: "Preferred workout structure and style",
                    enumValues: [
                        "circuit", "traditional_sets", "superset", "hiit", "emom", "amrap", "pyramid", "cluster"
                    ]
                )
            ],
            required: ["goalFocus"]
        )
    )

    /// Adapts existing plans based on user feedback and changing circumstances.
    static let adaptPlanBasedOnFeedback = AIFunctionDefinition(
        name: "adaptPlanBasedOnFeedback",
        description: """
        Intelligently modifies existing workout plans, nutrition targets, or goals based on
        user feedback, performance data, and changing life circumstances. Maintains plan
        integrity while addressing specific concerns or requests.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "userFeedback": AIParameterDefinition(
                    type: "string",
                    description: """
                    User's feedback about their current plan, how they're feeling, or what they want to change.
                    Can include subjective experiences, specific complaints, or requests for modifications.
                    """
                ),
                "adaptationType": AIParameterDefinition(
                    type: "string",
                    description: "Type of adaptation needed based on the feedback",
                    enumValues: [
                        "reduce_intensity", "increase_intensity", "change_focus", "add_variety",
                        "recovery_focus", "time_adjustment", "frequency_change", "equipment_swap",
                        "injury_accommodation", "schedule_optimization"
                    ]
                ),
                "specificConcern": AIParameterDefinition(
                    type: "string",
                    description: """
                    Specific issue to address (e.g., 'shoulder pain', 'too tired', 'bored with routine',
                    'not seeing results', 'too time consuming')
                    """
                ),
                "urgencyLevel": AIParameterDefinition(
                    type: "string",
                    description: "How quickly this adaptation should be implemented",
                    enumValues: ["immediate", "gradual", "next_cycle"]
                ),
                "maintainGoals": AIParameterDefinition(
                    type: "boolean",
                    description: "Whether to maintain the original goals or allow goal modification"
                )
            ],
            required: ["userFeedback"]
        )
    )
}
