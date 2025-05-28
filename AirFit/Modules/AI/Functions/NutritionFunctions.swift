import Foundation

/// Nutrition logging AI functions for the CoachEngine.
enum NutritionFunctions {

    /// Parses complex natural language meal descriptions into structured nutrition data.
    static let parseAndLogComplexNutrition = AIFunctionDefinition(
        name: "parseAndLogComplexNutrition",
        description: """
        Intelligently parses detailed, free-form natural language descriptions of meals, snacks,
        or beverages into structured nutritional data. Handles complex descriptions including
        cooking methods, portion sizes, brand names, and mixed dishes.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "naturalLanguageInput": AIParameterDefinition(
                    type: "string",
                    description: """
                    User's complete description of what they ate or drank. Can include multiple items,
                    cooking methods, portion estimates, brand names, and contextual details.
                    """
                ),
                "mealType": AIParameterDefinition(
                    type: "string",
                    description: "Classification of when this food was consumed",
                    enumValues: [
                        "breakfast", "lunch", "dinner", "snack", "pre_workout",
                        "post_workout", "late_night", "beverage_only"
                    ]
                ),
                "timestamp": AIParameterDefinition(
                    type: "string",
                    description: "ISO 8601 datetime when the meal was consumed (if different from now)"
                ),
                "confidenceThreshold": AIParameterDefinition(
                    type: "number",
                    description: "Minimum confidence level required for nutritional estimates (0.0-1.0)",
                    minimum: 0.0,
                    maximum: 1.0
                ),
                "includeAlternatives": AIParameterDefinition(
                    type: "boolean",
                    description: "Whether to provide alternative interpretations for ambiguous descriptions"
                )
            ],
            required: ["naturalLanguageInput"]
        )
    )
}
