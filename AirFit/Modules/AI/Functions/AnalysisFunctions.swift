import Foundation

/// Performance analysis and educational AI functions for the CoachEngine.
enum AnalysisFunctions {

    /// Analyzes user performance data to identify trends, patterns, and insights.
    static let analyzePerformanceTrends = AIFunctionDefinition(
        name: "analyzePerformanceTrends",
        description: """
        Performs comprehensive analysis of user's performance data across multiple metrics
        to identify trends, correlations, and actionable insights. Considers workout performance,
        nutrition adherence, sleep quality, subjective measures, and external factors.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "analysisQuery": AIParameterDefinition(
                    type: "string",
                    description: """
                    Natural language description of what the user wants to understand about their performance.
                    Examples: 'Why am I feeling weaker lately?', 'How does my sleep affect my workouts?'
                    """
                ),
                "metricsToAnalyze": AIParameterDefinition(
                    type: "array",
                    description: "Specific performance metrics to include in the analysis",
                    items: AIBox(AIParameterDefinition(
                        type: "string",
                        description: "Performance metric",
                        enumValues: [
                            "workout_volume", "workout_intensity", "strength_progression", "endurance_metrics",
                            "recovery_metrics", "sleep_quality", "energy_levels", "mood_scores",
                            "nutrition_adherence", "body_composition", "heart_rate_variability",
                            "resting_heart_rate", "workout_frequency", "injury_incidents"
                        ]
                    ))
                ),
                "timePeriodDays": AIParameterDefinition(
                    type: "integer",
                    description: "Number of days of historical data to analyze",
                    minimum: 7,
                    maximum: 365
                ),
                "analysisDepth": AIParameterDefinition(
                    type: "string",
                    description: "Level of analytical detail desired",
                    enumValues: ["quick_overview", "standard_analysis", "deep_dive", "predictive"]
                ),
                "includeRecommendations": AIParameterDefinition(
                    type: "boolean",
                    description: "Whether to include actionable recommendations based on findings"
                )
            ],
            required: ["analysisQuery"]
        )
    )

    /// Generates personalized educational content on fitness and health topics.
    static let generateEducationalInsight = AIFunctionDefinition(
        name: "generateEducationalInsight",
        description: """
        Provides personalized, science-based educational content on fitness, nutrition,
        and health topics. Tailors complexity and focus to user's current knowledge level
        and specific situation for maximum relevance and actionability.
        """,
        parameters: AIFunctionParameters(
            properties: [
                "topic": AIParameterDefinition(
                    type: "string",
                    description: "Educational topic to explore",
                    enumValues: [
                        "progressive_overload", "periodization", "nutrition_timing", "macronutrient_balance",
                        "hydration_science", "sleep_optimization", "recovery_science", "injury_prevention",
                        "mobility_flexibility", "cardiovascular_health", "strength_training_basics",
                        "endurance_training", "body_composition", "metabolism_basics", "supplement_science",
                        "stress_management", "habit_formation", "motivation_psychology", "exercise_physiology",
                        "biomechanics"
                    ]
                ),
                "userContext": AIParameterDefinition(
                    type: "string",
                    description: """
                    Why this topic is relevant to the user right now. What specific situation,
                    question, or challenge prompted this educational need?
                    """
                ),
                "knowledgeLevel": AIParameterDefinition(
                    type: "string",
                    description: "User's current understanding of this topic",
                    enumValues: ["complete_beginner", "basic_awareness", "intermediate", "advanced", "expert"]
                ),
                "contentDepth": AIParameterDefinition(
                    type: "string",
                    description: "Level of detail and complexity desired",
                    enumValues: ["quick_tip", "overview", "detailed_explanation", "scientific_deep_dive", "practical_application"]
                ),
                "outputFormat": AIParameterDefinition(
                    type: "string",
                    description: "Preferred format for the educational content",
                    enumValues: ["conversational", "structured_guide", "bullet_points", "qa_format", "step_by_step"]
                ),
                "includeActionItems": AIParameterDefinition(
                    type: "boolean",
                    description: "Whether to include specific, actionable next steps"
                ),
                "relateToUserData": AIParameterDefinition(
                    type: "boolean",
                    description: "Whether to connect the education to user's specific data and situation"
                )
            ],
            required: ["topic", "userContext"]
        )
    )
}
