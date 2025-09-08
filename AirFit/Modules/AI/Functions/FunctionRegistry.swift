import Foundation

/// Comprehensive registry of all AI functions available to the CoachEngine.
/// Defines function schemas for workout planning, performance analysis,
/// plan adaptation, and goal setting.
///
/// NOTE: parseAndLogComplexNutrition and generateEducationalInsight have been migrated
/// to direct AI implementation in CoachEngine for improved performance and reduced token usage.
enum FunctionRegistry {

    /// All available functions that the AI coach can call to assist users.
    /// Functions removed in Phase 3 refactor:
    /// - parseAndLogComplexNutrition (now CoachEngine.parseAndLogNutritionDirect)
    /// - generateEducationalInsight (now CoachEngine.generateEducationalContentDirect)
    static let availableFunctions: [AIFunctionDefinition] = [
        // WORKOUT TRACKING REMOVED - Analysis via HealthKit only
        // WorkoutFunctions.generatePersonalizedWorkoutPlan,
        // WorkoutFunctions.adaptPlanBasedOnFeedback,
        AnalysisFunctions.analyzePerformanceTrends,
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
}
