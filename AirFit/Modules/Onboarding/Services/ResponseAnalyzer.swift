import Foundation

// MARK: - Response Analyzer Implementation
actor ResponseAnalyzerImpl: ResponseAnalyzer {
    // For now, we'll do local analysis without AI service
    // Phase 2 will integrate the actual AI persona synthesis
    
    init() {
        // No dependencies for Phase 1
    }
    
    func analyzeResponse(
        response: ResponseValue,
        node: ConversationNode,
        previousResponses: [ResponseSnapshot]
    ) async throws -> PersonalityInsights {
        // Start with existing insights or create new
        var insights = try await extractExistingInsights(from: previousResponses) ?? PersonalityInsights()
        
        // Extract text content from response
        let responseText = extractText(from: response)
        
        // Update traits based on node type and response
        switch node.nodeType {
        case .goals:
            insights = updateGoalTraits(insights: insights, response: responseText, node: node)
        case .lifestyle:
            insights = updateLifestyleTraits(insights: insights, response: responseText, node: node)
        case .personality:
            insights = updatePersonalityTraits(insights: insights, response: responseText, node: node)
        case .preferences:
            insights = updatePreferenceTraits(insights: insights, response: responseText, node: node)
        default:
            break
        }
        
        // Update from choice options if applicable
        if case .choice(let choiceId) = response {
            insights = updateFromChoiceTraits(insights: insights, choiceId: choiceId, node: node)
        } else if case .multiChoice(let choiceIds) = response {
            for choiceId in choiceIds {
                insights = updateFromChoiceTraits(insights: insights, choiceId: choiceId, node: node)
            }
        }
        
        // Calculate confidence scores
        insights.confidenceScores = calculateConfidenceScores(insights: insights, responseCount: previousResponses.count + 1)
        insights.lastUpdated = Date()
        
        return insights
    }
    
    // MARK: - Private Methods
    private func extractExistingInsights(from responses: [ResponseSnapshot]) async throws -> PersonalityInsights? {
        // Find the most recent response with insights
        if let latestResponse = responses.last,
           let insights = try? JSONDecoder().decode(PersonalityInsights.self, from: latestResponse.responseData) {
            return insights
        }
        return nil
    }
    
    private func extractText(from response: ResponseValue) -> String {
        switch response {
        case .text(let value):
            return value
        case .voice(let transcription, _):
            return transcription
        case .choice(let id):
            return id
        case .multiChoice(let ids):
            return ids.joined(separator: ", ")
        case .slider(let value):
            return String(value)
        }
    }
    
    private func updateGoalTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
        var updated = insights
        
        // Analyze goal-related keywords
        let lowercased = response.lowercased()
        
        // Achievement orientation
        if lowercased.contains("win") || lowercased.contains("compete") || lowercased.contains("best") {
            updated.traits[.intensityPreference] = (updated.traits[.intensityPreference] ?? 0.5) + 0.1
            updated.motivationalDrivers.insert(.achievement)
        }
        
        // Health focus
        if lowercased.contains("health") || lowercased.contains("wellness") || lowercased.contains("longevity") {
            updated.traits[.dataOrientation] = (updated.traits[.dataOrientation] ?? 0.5) + 0.1
            updated.motivationalDrivers.insert(.health)
        }
        
        // Social aspects
        if lowercased.contains("friend") || lowercased.contains("group") || lowercased.contains("community") {
            updated.traits[.socialOrientation] = (updated.traits[.socialOrientation] ?? 0.5) + 0.15
            updated.motivationalDrivers.insert(.social)
        }
        
        return updated
    }
    
    private func updateLifestyleTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
        var updated = insights
        
        let lowercased = response.lowercased()
        
        // Structure preferences
        if lowercased.contains("routine") || lowercased.contains("schedule") || lowercased.contains("plan") {
            updated.traits[.structureNeed] = (updated.traits[.structureNeed] ?? 0.5) + 0.15
        } else if lowercased.contains("flexible") || lowercased.contains("spontaneous") {
            updated.traits[.structureNeed] = (updated.traits[.structureNeed] ?? 0.5) - 0.15
        }
        
        // Stress indicators
        if lowercased.contains("busy") || lowercased.contains("stress") || lowercased.contains("overwhelm") {
            updated.stressResponses[.timeConstraints] = .simplification
            updated.traits[.emotionalSupport] = (updated.traits[.emotionalSupport] ?? 0.5) + 0.1
        }
        
        return updated
    }
    
    private func updatePersonalityTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
        var updated = insights
        
        let lowercased = response.lowercased()
        
        // Authority preferences
        if lowercased.contains("push") || lowercased.contains("challenge") || lowercased.contains("tough") {
            updated.traits[.authorityPreference] = (updated.traits[.authorityPreference] ?? 0.5) + 0.2
            updated.communicationStyle.encouragementStyle = .tough
        } else if lowercased.contains("support") || lowercased.contains("encourage") || lowercased.contains("gentle") {
            updated.traits[.authorityPreference] = (updated.traits[.authorityPreference] ?? 0.5) - 0.2
            updated.communicationStyle.encouragementStyle = .cheerleader
        }
        
        // Communication tone
        if lowercased.contains("casual") || lowercased.contains("friend") || lowercased.contains("fun") {
            updated.communicationStyle.preferredTone = .casual
        } else if lowercased.contains("professional") || lowercased.contains("serious") {
            updated.communicationStyle.preferredTone = .formal
        }
        
        return updated
    }
    
    private func updatePreferenceTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
        var updated = insights
        
        let lowercased = response.lowercased()
        
        // Data preferences
        if lowercased.contains("data") || lowercased.contains("numbers") || lowercased.contains("track") {
            updated.traits[.dataOrientation] = (updated.traits[.dataOrientation] ?? 0.5) + 0.15
            updated.communicationStyle.detailLevel = .comprehensive
        } else if lowercased.contains("simple") || lowercased.contains("basic") {
            updated.communicationStyle.detailLevel = .minimal
        }
        
        // Feedback timing
        if lowercased.contains("constant") || lowercased.contains("always") {
            updated.communicationStyle.feedbackTiming = .immediate
        } else if lowercased.contains("milestone") || lowercased.contains("achievement") {
            updated.communicationStyle.feedbackTiming = .milestone
        }
        
        return updated
    }
    
    private func updateFromChoiceTraits(insights: PersonalityInsights, choiceId: String, node: ConversationNode) -> PersonalityInsights {
        var updated = insights
        
        // Find the choice option
        if case .singleChoice(let options) = node.inputType,
           let option = options.first(where: { $0.id == choiceId }) {
            // Apply trait modifications from the choice
            for (trait, value) in option.traits {
                if let dimension = PersonalityDimension(rawValue: trait) {
                    let currentValue = updated.traits[dimension] ?? 0.5
                    updated.traits[dimension] = max(0, min(1, currentValue + value))
                }
            }
        } else if case .multiChoice(let options, _, _) = node.inputType,
                  let option = options.first(where: { $0.id == choiceId }) {
            // Apply trait modifications (weighted for multi-choice)
            for (trait, value) in option.traits {
                if let dimension = PersonalityDimension(rawValue: trait) {
                    let currentValue = updated.traits[dimension] ?? 0.5
                    updated.traits[dimension] = max(0, min(1, currentValue + (value * 0.7)))
                }
            }
        }
        
        return updated
    }
    
    private func calculateConfidenceScores(insights: PersonalityInsights, responseCount: Int) -> [PersonalityDimension: Double] {
        var scores: [PersonalityDimension: Double] = [:]
        
        // Base confidence increases with more responses
        let baseConfidence = min(0.9, Double(responseCount) * 0.15)
        
        for dimension in PersonalityDimension.allCases {
            if insights.traits[dimension] != nil {
                // Higher confidence for traits that deviate from neutral (0.5)
                let deviation = abs((insights.traits[dimension] ?? 0.5) - 0.5)
                scores[dimension] = min(0.95, baseConfidence + (deviation * 0.3))
            } else {
                scores[dimension] = 0.0
            }
        }
        
        return scores
    }
}