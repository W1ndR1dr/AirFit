import Foundation

/// Performance analysis and educational AI functions for the CoachEngine.
/// NOTE: generateEducationalInsight has been migrated to direct AI implementation in CoachEngine
/// for improved performance and reduced token usage.
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

    // generateEducationalInsight removed - now handled directly by CoachEngine.generateEducationalContentDirect()
    // This enables 80% token reduction and more natural, personalized content generation

}
