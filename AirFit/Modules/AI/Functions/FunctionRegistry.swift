import Foundation

<<<<<<< HEAD
/// Comprehensive registry of all AI functions available to the CoachEngine.
/// Defines function schemas for workout planning, nutrition logging, performance analysis,
/// plan adaptation, goal setting, and educational content generation.
enum FunctionRegistry {

    /// All available functions that the AI coach can call to assist users.
    static let availableFunctions: [AIFunctionDefinition] = [
        WorkoutFunctions.generatePersonalizedWorkoutPlan,
        WorkoutFunctions.adaptPlanBasedOnFeedback,
        NutritionFunctions.parseAndLogComplexNutrition,
        AnalysisFunctions.analyzePerformanceTrends,
        AnalysisFunctions.generateEducationalInsight,
        GoalFunctions.assistGoalSettingOrRefinement
    ]

}

// MARK: - Function Validation

extension FunctionRegistry {

    /// Validates that all function definitions are properly structured.
    static func validateFunctions() -> [String] {
        var errors: [String] = []

        for function in availableFunctions {
            // Check required fields
            if function.name.isEmpty {
                errors.append("Function has empty name")
            }

            if function.description.isEmpty {
                errors.append("Function '\(function.name)' has empty description")
            }

            // Validate parameters
            for (paramName, param) in function.parameters.properties {
                if param.description.isEmpty {
                    errors.append("Parameter '\(paramName)' in function '\(function.name)' has empty description")
                }

                // Check enum values for string types
                if param.type == "string" && param.enumValues?.isEmpty == true {
                    // Note: Not all string parameters need enum values, so this is just a warning
                }

                // Check numeric constraints
                if ["integer", "number"].contains(param.type) {
                    if let min = param.minimum, let max = param.maximum, min >= max {
                        errors.append("Parameter '\(paramName)' has invalid range: min(\(min)) >= max(\(max))")
                    }
                }
            }

            // Check required parameters exist
            for requiredParam in function.parameters.required
            where function.parameters.properties[requiredParam] == nil {
                errors.append("Required parameter '\(requiredParam)' not found in function '\(function.name)'")
            }
        }

        return errors
    }

    /// Returns function definition by name.
    static func function(named name: String) -> AIFunctionDefinition? {
        return availableFunctions.first { $0.name == name }
    }

    /// Returns all function names.
    static var functionNames: [String] {
        return availableFunctions.map { $0.name }
    }
=======
/// Registry of all AI-callable functions.
enum FunctionRegistry {
    /// Collection of available function definitions.
    static let availableFunctions: [FunctionDefinition] = [
        // Workout Planning
        FunctionDefinition(
            name: "generatePersonalizedWorkoutPlan",
            description: "Creates a new, tailored workout plan considering user goals, context, and feedback",
            parameters: FunctionParameters(
                properties: [
                    "goalFocus": ParameterDefinition(
                        type: "string",
                        description: "Primary goal of the workout plan",
                        enumValues: ["strength", "endurance", "hypertrophy", "active_recovery", "general_fitness"],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "durationMinutes": ParameterDefinition(
                        type: "integer",
                        description: "Target workout duration in minutes",
                        enumValues: nil,
                        minimum: 15,
                        maximum: 120,
                        items: nil
                    ),
                    "intensityPreference": ParameterDefinition(
                        type: "string",
                        description: "Desired workout intensity",
                        enumValues: ["light", "moderate", "high", "variable"],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "targetMuscleGroups": ParameterDefinition(
                        type: "array",
                        description: "Specific muscle groups to target",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: Box(
                            ParameterDefinition(
                                type: "string",
                                description: "Muscle group",
                                enumValues: ["chest", "back", "shoulders", "arms", "legs", "core", "full_body"],
                                minimum: nil,
                                maximum: nil,
                                items: nil
                            )
                        )
                    ),
                    "constraints": ParameterDefinition(
                        type: "string",
                        description: "Any limitations or special requirements",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    )
                ],
                required: ["goalFocus"]
            )
        ),

        // Nutrition Logging
        FunctionDefinition(
            name: "parseAndLogComplexNutrition",
            description: "Parses detailed free-form natural language meal descriptions into structured data for logging",
            parameters: FunctionParameters(
                properties: [
                    "naturalLanguageInput": ParameterDefinition(
                        type: "string",
                        description: "User's full description of the meal",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "mealType": ParameterDefinition(
                        type: "string",
                        description: "Type of meal",
                        enumValues: ["breakfast", "lunch", "dinner", "snack", "pre_workout", "post_workout"],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "timestamp": ParameterDefinition(
                        type: "string",
                        description: "ISO 8601 datetime when the meal was consumed",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    )
                ],
                required: ["naturalLanguageInput"]
            )
        ),

        // Performance Analysis
        FunctionDefinition(
            name: "analyzePerformanceTrends",
            description: "Analyzes user's performance data to identify trends and insights",
            parameters: FunctionParameters(
                properties: [
                    "analysisQuery": ParameterDefinition(
                        type: "string",
                        description: "Natural language description of what to analyze",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "metricsRequired": ParameterDefinition(
                        type: "array",
                        description: "Specific metrics needed for analysis",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: Box(
                            ParameterDefinition(
                                type: "string",
                                description: "Metric name",
                                enumValues: nil,
                                minimum: nil,
                                maximum: nil,
                                items: nil
                            )
                        )
                    ),
                    "timePeriodDays": ParameterDefinition(
                        type: "integer",
                        description: "Number of days to analyze",
                        enumValues: nil,
                        minimum: 7,
                        maximum: 365,
                        items: nil
                    )
                ],
                required: ["analysisQuery"]
            )
        ),

        // Plan Adaptation
        FunctionDefinition(
            name: "adaptPlanBasedOnFeedback",
            description: "Modifies existing plans based on user's subjective state or feedback",
            parameters: FunctionParameters(
                properties: [
                    "userFeedback": ParameterDefinition(
                        type: "string",
                        description: "User's feedback about their current state or plan",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "adaptationType": ParameterDefinition(
                        type: "string",
                        description: "Type of adaptation needed",
                        enumValues: ["reduce_intensity", "increase_intensity", "change_focus", "add_variety", "recovery_focus"],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "specificConcern": ParameterDefinition(
                        type: "string",
                        description: "Specific issue to address (e.g., 'shoulder pain', 'too tired')",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    )
                ],
                required: ["userFeedback"]
            )
        ),

        // Goal Setting
        FunctionDefinition(
            name: "assistGoalSettingOrRefinement",
            description: "Helps user define or refine SMART fitness goals",
            parameters: FunctionParameters(
                properties: [
                    "currentGoal": ParameterDefinition(
                        type: "string",
                        description: "User's existing goal if any",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "aspirations": ParameterDefinition(
                        type: "string",
                        description: "What the user wants to achieve",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "timeframe": ParameterDefinition(
                        type: "string",
                        description: "Desired timeframe for the goal",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "constraints": ParameterDefinition(
                        type: "array",
                        description: "Any limitations to consider",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: Box(
                            ParameterDefinition(
                                type: "string",
                                description: "Constraint",
                                enumValues: nil,
                                minimum: nil,
                                maximum: nil,
                                items: nil
                            )
                        )
                    )
                ],
                required: ["aspirations"]
            )
        ),

        // Educational Content
        FunctionDefinition(
            name: "generateEducationalInsight",
            description: "Provides personalized educational content on fitness/health topics",
            parameters: FunctionParameters(
                properties: [
                    "topic": ParameterDefinition(
                        type: "string",
                        description: "Educational topic",
                        enumValues: [
                            "progressive_overload",
                            "nutrition_timing",
                            "recovery_science",
                            "sleep_optimization",
                            "hrv_training",
                            "mobility_flexibility",
                            "supplement_science"
                        ],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "userContext": ParameterDefinition(
                        type: "string",
                        description: "Why this topic is relevant to the user now",
                        enumValues: nil,
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    ),
                    "depth": ParameterDefinition(
                        type: "string",
                        description: "Level of detail desired",
                        enumValues: ["quick_tip", "detailed_explanation", "scientific_deep_dive"],
                        minimum: nil,
                        maximum: nil,
                        items: nil
                    )
                ],
                required: ["topic", "userContext"]
            )
        )
    ]
>>>>>>> 8e41ef7 (Feat: Add AI models and function registry)
}
