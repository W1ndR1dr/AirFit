import Foundation

// MARK: - Nutrition Parsing Schemas
extension StructuredOutputSchema {

    // Schema for parsing natural language food descriptions
    static let nutritionParsing: StructuredOutputSchema = {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "items": [
                    "type": "array",
                    "description": "Array of parsed food items",
                    "items": [
                        "type": "object",
                        "properties": [
                            "food_name": [
                                "type": "string",
                                "description": "Name of the food item"
                            ],
                            "quantity": [
                                "type": "number",
                                "description": "Quantity of the food item"
                            ],
                            "unit": [
                                "type": "string",
                                "description": "Unit of measurement"
                            ],
                            "calories": [
                                "type": "number",
                                "description": "Calories in kcal"
                            ],
                            "protein": [
                                "type": "number",
                                "description": "Protein in grams"
                            ],
                            "carbs": [
                                "type": "number",
                                "description": "Carbohydrates in grams"
                            ],
                            "fat": [
                                "type": "number",
                                "description": "Fat in grams"
                            ],
                            "confidence": [
                                "type": "number",
                                "description": "Confidence score 0-1"
                            ]
                        ],
                        "required": ["food_name", "calories", "protein", "carbs", "fat", "confidence"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "required": ["items"],
            "additionalProperties": false
        ]

        return StructuredOutputSchema.fromJSON(
            name: "nutrition_parsing",
            description: "Parse natural language food descriptions into structured nutrition data",
            schema: schema,
            strict: true
        ) ?? StructuredOutputSchema(name: "nutrition_parsing", description: "", jsonSchema: Data(), strict: true)
    }()

    // Schema for dashboard content generation
    static let dashboardContent: StructuredOutputSchema = {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "primary_insight": [
                    "type": "string",
                    "description": "Main insight or observation about user's current state"
                ],
                "guidance": [
                    "type": "string",
                    "description": "Actionable guidance or recommendation"
                ],
                "celebration": [
                    "type": "string",
                    "description": "Positive reinforcement or achievement recognition"
                ],
                "nutrition_focus": [
                    "type": "string",
                    "description": "Specific nutrition advice based on current intake"
                ],
                "workout_context": [
                    "type": "string",
                    "description": "Workout-related context or recovery advice"
                ]
            ],
            "required": ["primary_insight", "guidance"],
            "additionalProperties": false
        ]

        return StructuredOutputSchema.fromJSON(
            name: "dashboard_content",
            description: "Generate AI-driven dashboard content with insights and recommendations",
            schema: schema,
            strict: true
        ) ?? StructuredOutputSchema(name: "dashboard_content", description: "", jsonSchema: Data(), strict: true)
    }()

    // Schema for meal photo analysis
    static let mealPhotoAnalysis: StructuredOutputSchema = {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "meal_description": [
                    "type": "string",
                    "description": "Natural language description of the meal"
                ],
                "items": [
                    "type": "array",
                    "description": "Individual food items identified in the photo",
                    "items": [
                        "type": "object",
                        "properties": [
                            "food_name": [
                                "type": "string",
                                "description": "Name of the food"
                            ],
                            "portion_size": [
                                "type": "string",
                                "description": "Estimated portion size"
                            ],
                            "calories": [
                                "type": "number",
                                "description": "Estimated calories"
                            ],
                            "protein": [
                                "type": "number",
                                "description": "Estimated protein in grams"
                            ],
                            "carbs": [
                                "type": "number",
                                "description": "Estimated carbs in grams"
                            ],
                            "fat": [
                                "type": "number",
                                "description": "Estimated fat in grams"
                            ],
                            "confidence": [
                                "type": "number",
                                "description": "Confidence in estimation 0-1"
                            ]
                        ],
                        "required": ["food_name", "portion_size", "calories", "protein", "carbs", "fat", "confidence"],
                        "additionalProperties": false
                    ]
                ],
                "total_calories": [
                    "type": "number",
                    "description": "Total estimated calories for the meal"
                ],
                "meal_type": [
                    "type": "string",
                    "description": "Type of meal",
                    "enum": ["breakfast", "lunch", "dinner", "snack"]
                ]
            ],
            "required": ["meal_description", "items", "total_calories"],
            "additionalProperties": false
        ]

        return StructuredOutputSchema.fromJSON(
            name: "meal_photo_analysis",
            description: "Analyze a meal photo and extract nutrition information",
            schema: schema,
            strict: true
        ) ?? StructuredOutputSchema(name: "meal_photo_analysis", description: "", jsonSchema: Data(), strict: true)
    }()
}
