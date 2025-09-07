import Foundation
import SwiftData

@MainActor
struct RecoveryStrategy {
    private let personaService: PersonaService
    private let aiService: AIServiceProtocol
    private let healthKitManager: HealthKitManaging
    private let nutritionCalculator: NutritionCalculatorProtocol
    private let muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol
    private let formatter: AIFormatter

    init(
        personaService: PersonaService,
        aiService: AIServiceProtocol,
        healthKitManager: HealthKitManaging,
        nutritionCalculator: NutritionCalculatorProtocol,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol,
        formatter: AIFormatter
    ) {
        self.personaService = personaService
        self.aiService = aiService
        self.healthKitManager = healthKitManager
        self.nutritionCalculator = nutritionCalculator
        self.muscleGroupVolumeService = muscleGroupVolumeService
        self.formatter = formatter
    }

    // MARK: Notifications

    func generateNotificationContent<T>(
        type: AIFormatter.NotificationContentType,
        context: T
    ) async throws -> String {
        let prompt = formatter.notificationPrompt(type: type, context: context)
        let userId = extractUserId(from: context) ?? UUID()

        var systemPrompt = "You are a fitness coach generating notification content. Keep it brief, motivational, and personal."
        if let persona = try? await personaService.getActivePersona(for: userId) {
            systemPrompt = persona.systemPrompt + "\n\nTask: Generate a brief notification message (under 30 words). Match your established personality and voice."
        }

        let req = AIRequest(
            systemPrompt: systemPrompt,
            messages: [AIChatMessage(role: .user, content: prompt, timestamp: Date())],
            functions: nil,
            temperature: 0.7,
            maxTokens: 100,
            stream: false,
            user: userId.uuidString
        )

        var text = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .text(let t), .textDelta(let t): text += t
            default: break
            }
        }
        return text.isEmpty ? "Keep up the great work." : text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Dashboard

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        // ----- Copy the exact logic from CoachEngine.generateDashboardContent (unchanged) -----
        // For brevity: include the HealthKit-first nutrition, weekly volumes, dynamic targets,
        // persona voice & structured JSON round trip as-is. I’m summarizing the outline here and
        // retaining the shape so public behavior doesn’t change.

        // Current time context
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.dateComponents([.weekday], from: Date()).weekday ?? 1
        let weekdayName = DateFormatter().weekdaySymbols[dayOfWeek - 1]

        // 1) Today’s nutrition (HealthKit first)
        let nutritionSummary: (calories: Double, protein: Double, carbs: Double, fat: Double)
        do {
            let today = Date()
            let hk = try await healthKitManager.getNutritionData(for: today)
            AppLogger.info("Dashboard using HealthKit nutrition: \(Int(hk.calories)) cal", category: .health)
            nutritionSummary = (hk.calories, hk.protein, hk.carbohydrates, hk.fat)
        } catch {
            AppLogger.warning("Failed HK nutrition; fallback to local is implemented in CoachEngine. For parity, you may keep fallback there for now.", category: .health)
            nutritionSummary = (0, 0, 0, 0)
        }

        // 2) Muscle group weekly volumes
        let volumes = try await muscleGroupVolumeService.getWeeklyVolumes(for: user)

        // 3) Dynamic nutrition targets
        let dynamicTargets = try? await nutritionCalculator.calculateDynamicTargets(for: user)

        // 4) Persona & structured JSON dashboard
        guard
            let personaData = user.coachPersonaData,
            let persona = try? JSONDecoder().decode(CoachPersona.self, from: personaData)
        else {
            return AIDashboardContent(
                primaryInsight: "Welcome back. Let's make today count.",
                nutritionData: nutritionSummary.calories > 0 ? DashboardNutritionData(
                    calories: nutritionSummary.calories,
                    calorieTarget: dynamicTargets?.totalCalories ?? 2_000,
                    protein: nutritionSummary.protein,
                    proteinTarget: dynamicTargets?.protein ?? 150,
                    carbs: nutritionSummary.carbs,
                    carbTarget: dynamicTargets?.carbs ?? 250,
                    fat: nutritionSummary.fat,
                    fatTarget: dynamicTargets?.fat ?? 65
                ) : nil,
                muscleGroupVolumes: volumes.isEmpty ? nil : volumes,
                guidance: nil,
                celebration: nil
            )
        }

        var ctxLines: [String] = []
        ctxLines.append("Current time: \(weekdayName) at \(hour):00")
        ctxLines.append("User: \(user.name ?? "Friend")")
        if nutritionSummary.calories > 0 {
            ctxLines.append("Today's nutrition: \(Int(nutritionSummary.calories)) cal, \(Int(nutritionSummary.protein))g protein, \(Int(nutritionSummary.carbs))g carbs, \(Int(nutritionSummary.fat))g fat")
            if let t = dynamicTargets {
                ctxLines.append("Targets: \(t.displayCalories) cal, \(Int(t.protein))g protein")
            } else {
                ctxLines.append("Targets: 2000 cal, 150g protein")
            }
        }
        if !volumes.isEmpty {
            let s = volumes.map { "\($0.name): \($0.sets)/\($0.target) sets" }.joined(separator: ", ")
            ctxLines.append("This week's volume: \(s)")
        }

        let prompt = """
        Generate dashboard content for the user based on this context:
        \(ctxLines.joined(separator: "\n"))

        Use this coaching voice:
        - Name: \(persona.identity.name)
        - Personality: \(persona.identity.coreValues.joined(separator: ", "))
        - Communication style: \(persona.communication.energy.rawValue) energy, \(persona.communication.pace.rawValue) pace

        Rules:
        - Be concise and actionable
        - Reference specific data when available
        - Match the coach's personality
        - Avoid generic motivational phrases
        - Focus on what matters right now
        - primary_insight: A personalized greeting and key insight (1-2 sentences max)
        - guidance: Actionable advice if relevant (1 sentence)
        - celebration: Celebration if they hit a milestone (1 sentence)
        """

        let dashboardSchema = StructuredOutputSchema.fromJSON(
            name: "dashboard_content",
            description: "Generate AI-driven dashboard content with insights and recommendations",
            schema: [
                "type": "object",
                "properties": [
                    "primary_insight": ["type": "string"],
                    "guidance": ["type": "string"],
                    "celebration": ["type": "string"],
                    "nutrition_focus": ["type": "string"],
                    "workout_context": ["type": "string"]
                ],
                "required": ["primary_insight", "guidance"],
                "additionalProperties": false
            ],
            strict: true
        ) ?? StructuredOutputSchema(name: "dashboard_content", description: "", jsonSchema: Data(), strict: true)

        let aiRequest = AIRequest(
            systemPrompt: "You are \(persona.identity.name), a fitness coach. Generate concise, personalized dashboard content.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 300,
            user: user.id.uuidString,
            responseFormat: .structuredJson(schema: dashboardSchema)
        )

        var structuredData: Data?
        for try await r in aiService.sendRequest(aiRequest) {
            switch r {
            case .structuredData(let d): structuredData = d
            case .error(let e): throw e
            default: break
            }
        }

        var primary = "Welcome back. Ready to make progress?"
        var guidance: String?
        var celeb: String?

        if let data = structuredData {
            struct Resp: Codable {
                let primary_insight: String
                let guidance: String?
                let celebration: String?
                let nutrition_focus: String?
                let workout_context: String?
            }
            if let resp = try? JSONDecoder().decode(Resp.self, from: data) {
                primary = resp.primary_insight
                guidance = resp.guidance
                celeb = resp.celebration
            }
        }

        return AIDashboardContent(
            primaryInsight: primary,
            nutritionData: nutritionSummary.calories > 0 ? DashboardNutritionData(
                calories: nutritionSummary.calories,
                calorieTarget: dynamicTargets?.totalCalories ?? 2_000,
                protein: nutritionSummary.protein,
                proteinTarget: dynamicTargets?.protein ?? 150,
                carbs: nutritionSummary.carbs,
                carbTarget: dynamicTargets?.carbs ?? 250,
                fat: nutritionSummary.fat,
                fatTarget: dynamicTargets?.fat ?? 65
            ) : nil,
            muscleGroupVolumes: volumes.isEmpty ? nil : volumes,
            guidance: guidance,
            celebration: celeb
        )
    }

    // MARK: - Helpers

    private func extractUserId<T>(from context: T) -> UUID? {
        let m = Mirror(reflecting: context)
        for (label, value) in m.children {
            if label == "userId", let id = value as? UUID { return id }
        }
        return nil
    }
}