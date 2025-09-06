import XCTest
@testable import AirFit

final class PersonaSynthesizerTests: XCTestCase {
    func testSynthesizesPersonaFromCannedJSON() async throws {
        let ai = AIServiceStub()
        ai.isConfigured = true
        ai.activeProvider = .openAI

        // Minimal JSON satisfying parser expectations
        let json = """
        {
          "name": "Riley",
          "archetype": "Calm strategist",
          "coreValues": ["Consistency", "Clarity", "Progress"],
          "backgroundStory": "Former collegiate runner turned coach.",
          "systemPrompt": "Always supportive, direct when needed.",
          "voiceCharacteristics": {
            "energy": "moderate",
            "pace": "natural",
            "warmth": "friendly",
            "vocabulary": "moderate",
            "sentenceStructure": "moderate"
          },
          "interactionStyle": {
            "greetingStyle": "Hey there!",
            "closingStyle": "You've got this.",
            "encouragementPhrases": ["Let's keep momentum!"],
            "acknowledgmentStyle": "Celebrate small wins",
            "correctionApproach": "Clear, constructive",
            "humorLevel": "light",
            "formalityLevel": "balanced",
            "responseLength": "moderate"
          },
          "adaptationRules": [
            { "trigger": "timeOfDay", "condition": "morning", "adjustment": "higher energy" }
          ],
          "nutritionRecommendations": {
            "approach": "Fuel for performance",
            "proteinGramsPerPound": 1.0,
            "fatPercentage": 0.3,
            "carbStrategy": "Fill remaining",
            "rationale": "Supports training volume",
            "flexibilityNotes": "Focus on weekly averages"
          }
        }
        """
        await ai.setValue(json, forKey: "cannedJSON")

        let synth = PersonaSynthesizer(aiService: ai)

        let conv = ConversationData(
            messages: [ConversationMessage(role: .user, content: "I want to get stronger.", timestamp: Date())],
            variables: ["primary_goal": "strength"]
        )
        let insights = ConversationPersonalityInsights(
            dominantTraits: ["Analytical", "Organized"],
            communicationStyle: .analytical,
            motivationType: .achievement,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["supportive"],
            stressResponse: .needsSupport,
            preferredTimes: ["morning"],
            extractedAt: Date()
        )

        let persona = try await synth.synthesizePersona(from: conv, insights: insights, preferredModel: .gpt5)
        XCTAssertEqual(persona.name, "Riley")
        XCTAssertEqual(persona.archetype, "Calm strategist")
        XCTAssertEqual(persona.voiceCharacteristics.energy, .moderate)
        XCTAssertNotNil(persona.nutritionRecommendations)
        XCTAssertEqual(persona.nutritionRecommendations?.proteinGramsPerPound, 1.0)
    }
}
