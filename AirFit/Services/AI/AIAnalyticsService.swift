import Foundation
import SwiftData

/// Basic implementation of AI Analytics Service
/// Wraps the base AnalyticsServiceProtocol and adds AI-specific functionality
actor AIAnalyticsService: AIAnalyticsServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-analytics-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For actors, return true as services are ready when created
        true
    }
    
    private let analyticsService: AnalyticsServiceProtocol
    private let aiService: AIServiceProtocol
    private let personaService: PersonaService
    
    init(
        analyticsService: AnalyticsServiceProtocol, 
        aiService: AIServiceProtocol,
        personaService: PersonaService
    ) {
        self.analyticsService = analyticsService
        self.aiService = aiService
        self.personaService = personaService
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["hasAnalyticsService": "true"]
        )
    }
    
    // MARK: - AI-specific methods
    
    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult {
        // Gather user's recent data for analysis
        let insights = try await analyticsService.getInsights(for: user)
        
        // Build AI prompt for performance analysis
        let prompt = buildPerformanceAnalysisPrompt(
            query: query,
            metrics: metrics,
            days: days,
            depth: depth,
            includeRecommendations: includeRecommendations,
            insights: insights
        )
        
        // Get user's persona for consistent coaching voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Analyzing fitness performance data. Provide actionable insights and identify meaningful trends in the user's style."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        // Parse the AI response into structured analysis
        // Calculate data points from workout frequency and streak
        let dataPoints = insights.streakDays > 0 ? insights.streakDays : Int(insights.workoutFrequency * 7)
        return try parsePerformanceAnalysis(fullResponse, dataPoints: dataPoints)
    }
    
    func generatePredictiveInsights(
        for user: User,
        timeframe: Int
    ) async throws -> PredictiveInsights {
        // Gather historical data for predictions
        let insights = try await analyticsService.getInsights(for: user)
        
        // Build AI prompt for predictive analysis
        let prompt = buildPredictiveAnalysisPrompt(
            timeframe: timeframe,
            insights: insights
        )
        
        // Get user's persona for consistent coaching voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Providing predictive analytics based on fitness trends. Focus on future projections and identify risks and opportunities."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        // Parse the AI response into predictive insights
        return try parsePredictiveInsights(fullResponse)
    }
    
    // MARK: - AnalyticsServiceProtocol methods
    
    func trackEvent(_ event: AnalyticsEvent) async {
        await analyticsService.trackEvent(event)
    }
    
    func trackScreen(_ screen: String, properties: [String: String]?) async {
        await analyticsService.trackScreen(screen, properties: properties)
    }
    
    func setUserProperties(_ properties: [String: String]) async {
        await analyticsService.setUserProperties(properties)
    }
    
    func trackWorkoutCompleted(_ workout: Workout) async {
        await analyticsService.trackWorkoutCompleted(workout)
    }
    
    func trackMealLogged(_ meal: FoodEntry) async {
        await analyticsService.trackMealLogged(meal)
    }
    
    func getInsights(for user: User) async throws -> UserInsights {
        return try await analyticsService.getInsights(for: user)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildPerformanceAnalysisPrompt(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        insights: UserInsights
    ) -> String {
        var prompt = """
        Analyze the following fitness performance data for the last \(days) days:
        
        Query: \(query)
        Requested metrics: \(metrics.joined(separator: ", "))
        Analysis depth: \(depth)
        
        User statistics:
        - Workout frequency: \(String(format: "%.1f", insights.workoutFrequency)) per week
        - Average workout duration: \(Int(insights.averageWorkoutDuration / 60)) minutes
        - Current streak: \(insights.streakDays) days
        - Calories trend: \(insights.caloriesTrend.direction.rawValue) (\(String(format: "%.1f%%", insights.caloriesTrend.changePercentage)))
        - Macro balance: P:\(Int(insights.macroBalance.proteinPercentage))% C:\(Int(insights.macroBalance.carbsPercentage))% F:\(Int(insights.macroBalance.fatPercentage))%
        """
        
        if includeRecommendations {
            prompt += "\n\nProvide specific, actionable recommendations based on the data."
        }
        
        prompt += """
        
        
        Format your response as JSON:
        {
            "summary": "Brief summary of findings",
            "keyMetrics": {
                "metric_name": {
                    "value": 0,
                    "trend": "up/down/stable",
                    "interpretation": "What this means"
                }
            },
            "insights": ["Key insight 1", "Key insight 2"],
            "recommendations": ["Action 1", "Action 2"]
        }
        """
        
        return prompt
    }
    
    private func buildPredictiveAnalysisPrompt(
        timeframe: Int,
        insights: UserInsights
    ) -> String {
        return """
        Based on the following user data, provide predictive insights for the next \(timeframe) days:
        
        Current statistics:
        - Workout frequency: \(String(format: "%.1f", insights.workoutFrequency)) per week
        - Average workout duration: \(Int(insights.averageWorkoutDuration / 60)) minutes
        - Current streak: \(insights.streakDays) days
        - Calories trend: \(insights.caloriesTrend.direction.rawValue) (\(String(format: "%.1f%%", insights.caloriesTrend.changePercentage)))
        - Macro balance: P:\(Int(insights.macroBalance.proteinPercentage))% C:\(Int(insights.macroBalance.carbsPercentage))% F:\(Int(insights.macroBalance.fatPercentage))%
        - Recent achievements: \(insights.achievements.count)
        
        Analyze trends and provide predictions for:
        1. Expected performance improvements
        2. Potential risks or plateaus
        3. Recommended adjustments
        
        Format as JSON:
        {
            "predictions": [
                {
                    "metric": "name",
                    "currentValue": 0,
                    "predictedValue": 0,
                    "confidence": "high/medium/low",
                    "timeframe": "\(timeframe) days"
                }
            ],
            "risks": ["Risk 1", "Risk 2"],
            "opportunities": ["Opportunity 1", "Opportunity 2"],
            "recommendations": ["Action 1", "Action 2"]
        }
        """
    }
    
    private func parsePerformanceAnalysis(_ response: String, dataPoints: Int) throws -> PerformanceAnalysisResult {
        // Try to extract JSON from response
        let jsonPattern = #"\{[\s\S]*\}"#
        guard let range = response.range(of: jsonPattern, options: .regularExpression),
              let data = String(response[range]).data(using: .utf8) else {
            // Fallback to simple analysis
            let defaultInsight = AIPerformanceInsight(
                category: "General",
                finding: response.prefix(200).trimmingCharacters(in: .whitespacesAndNewlines),
                impact: .medium,
                evidence: []
            )
            
            return PerformanceAnalysisResult(
                summary: "Analysis completed",
                insights: [defaultInsight],
                trends: [],
                recommendations: [],
                dataPoints: dataPoints,
                confidence: 0.5
            )
        }
        
        struct AnalysisResponse: Codable {
            let summary: String
            let keyMetrics: [String: MetricData]?
            let insights: [String]
            let recommendations: [String]?
            
            struct MetricData: Codable {
                let value: Double
                let trend: String
                let interpretation: String
            }
        }
        
        do {
            let decoded = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            
            // Convert insights to AIPerformanceInsight objects
            let aiInsights = decoded.insights.map { insight in
                AIPerformanceInsight(
                    category: "Fitness",
                    finding: insight,
                    impact: .medium,
                    evidence: []
                )
            }
            
            // Convert metrics to trends
            let trends = decoded.keyMetrics?.compactMap { key, data -> PerformanceTrend? in
                let direction: PerformanceTrend.TrendDirection
                switch data.trend.lowercased() {
                case "up", "improving":
                    direction = .improving
                case "down", "declining":
                    direction = .declining
                case "stable":
                    direction = .stable
                default:
                    direction = .volatile
                }
                
                return PerformanceTrend(
                    metric: key,
                    direction: direction,
                    magnitude: data.value,
                    timeframe: "Recent"
                )
            } ?? []
            
            return PerformanceAnalysisResult(
                summary: decoded.summary,
                insights: aiInsights,
                trends: trends,
                recommendations: decoded.recommendations ?? [],
                dataPoints: dataPoints,
                confidence: 0.8
            )
        } catch {
            // If JSON parsing fails, return basic result
            let fallbackInsight = AIPerformanceInsight(
                category: "Analysis",
                finding: response.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines),
                impact: .low,
                evidence: []
            )
            
            return PerformanceAnalysisResult(
                summary: "Analysis completed with limited data",
                insights: [fallbackInsight],
                trends: [],
                recommendations: [],
                dataPoints: dataPoints,
                confidence: 0.3
            )
        }
    }
    
    private func parsePredictiveInsights(_ response: String) throws -> PredictiveInsights {
        // Try to extract JSON from response
        let jsonPattern = #"\{[\s\S]*\}"#
        guard let range = response.range(of: jsonPattern, options: .regularExpression),
              let data = String(response[range]).data(using: .utf8) else {
            // Fallback result
            return PredictiveInsights(
                projections: [:],
                risks: ["Unable to generate predictions"],
                opportunities: [],
                confidence: 0.5
            )
        }
        
        struct PredictiveResponse: Codable {
            let predictions: [PredictionData]?
            let risks: [String]
            let opportunities: [String]
            let recommendations: [String]
            
            struct PredictionData: Codable {
                let metric: String
                let currentValue: Double
                let predictedValue: Double
                let confidence: String
                let timeframe: String
            }
        }
        
        do {
            let decoded = try JSONDecoder().decode(PredictiveResponse.self, from: data)
            
            // Convert predictions to projections dictionary
            var projections: [String: Double] = [:]
            var confidenceSum: Double = 0
            var confidenceCount = 0
            
            decoded.predictions?.forEach { prediction in
                // Use metric name as key and predicted value as value
                projections[prediction.metric] = prediction.predictedValue
                confidenceSum += mapConfidenceLevel(prediction.confidence)
                confidenceCount += 1
            }
            
            // Calculate overall confidence
            let avgConfidence = confidenceCount > 0 ? confidenceSum / Double(confidenceCount) : 0.5
            
            return PredictiveInsights(
                projections: projections,
                risks: decoded.risks,
                opportunities: decoded.opportunities,
                confidence: avgConfidence
            )
        } catch {
            // If JSON parsing fails, return basic result
            return PredictiveInsights(
                projections: [:],
                risks: ["Analysis error: unable to parse response"],
                opportunities: [],
                confidence: 0.3
            )
        }
    }
    
    private func mapConfidenceLevel(_ confidence: String) -> Double {
        switch confidence.lowercased() {
        case "high":
            return 0.9
        case "medium":
            return 0.7
        case "low":
            return 0.5
        default:
            return 0.6
        }
    }
}