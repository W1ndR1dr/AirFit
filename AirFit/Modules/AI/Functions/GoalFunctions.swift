import Foundation

/// Goal setting and refinement AI functions for the CoachEngine.
enum GoalFunctions {

    /// Assists with creating and refining SMART fitness goals.
    static let assistGoalSettingOrRefinement = AIFunctionDefinition(
        name: "assistGoalSettingOrRefinement",
        description: """
        Helps users define, refine, or restructure their fitness goals using SMART criteria
        (Specific, Measurable, Achievable, Relevant, Time-bound). Considers user's current
        fitness level, lifestyle constraints, and long-term aspirations.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "currentGoal": AIParameterDefinition(
                    type: "string",
                    description: "User's existing goal statement if they have one"
                ),
                "aspirations": AIParameterDefinition(
                    type: "string",
                    description: """
                    What the user ultimately wants to achieve. Can be vague or specific,
                    short-term or long-term. Examples: 'get stronger', 'lose weight', 'run a marathon'
                    """
                ),
                "timeframe": AIParameterDefinition(
                    type: "string",
                    description: "Desired timeframe for achieving the goal"
                ),
                "currentFitnessLevel": AIParameterDefinition(
                    type: "string",
                    description: "User's self-assessed current fitness level",
                    enumValues: ["beginner", "novice", "intermediate", "advanced", "expert", "returning_after_break"]
                ),
                "constraints": AIParameterDefinition(
                    type: "array",
                    description: "Limitations or challenges that might affect goal achievement",
                    items: AIBox(AIParameterDefinition(
                        type: "string",
                        description: "Constraint or limitation",
                        enumValues: [
                            "time_limited", "equipment_limited", "injury_history", "budget_constraints",
                            "travel_frequently", "family_obligations", "work_schedule", "health_conditions",
                            "motivation_issues", "knowledge_gaps"
                        ]
                    ))
                ),
                "motivationFactors": AIParameterDefinition(
                    type: "array",
                    description: "What motivates or drives the user",
                    items: AIBox(AIParameterDefinition(
                        type: "string",
                        description: "Motivation factor"
                    ))
                ),
                "goalType": AIParameterDefinition(
                    type: "string",
                    description: "Category of goal being set",
                    enumValues: [
                        "performance", "body_composition", "health_markers", "lifestyle",
                        "skill_development", "competition", "rehabilitation"
                    ]
                )
            ],
            required: ["aspirations"]
        )
    )
}
