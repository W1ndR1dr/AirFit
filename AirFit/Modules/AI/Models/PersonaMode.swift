import Foundation

/// Discrete persona modes for v1 clean implementation
/// Provides intelligent context adaptation without over-engineering
public enum PersonaMode: String, Codable, CaseIterable, Sendable {
    case supportiveCoach = "supportive_coach"
    case directTrainer = "direct_trainer"
    case analyticalAdvisor = "analytical_advisor"
    case motivationalBuddy = "motivational_buddy"

    /// User-facing display name for onboarding
    public var displayName: String {
        switch self {
        case .supportiveCoach: return "Supportive Coach"
        case .directTrainer: return "Direct Trainer"
        case .analyticalAdvisor: return "Analytical Advisor"
        case .motivationalBuddy: return "Motivational Buddy"
        }
    }

    /// User-facing description for persona selection
    public var description: String {
        switch self {
        case .supportiveCoach:
            return "Empathetic and encouraging. Celebrates progress and provides gentle guidance during setbacks."
        case .directTrainer:
            return "Clear and action-oriented. Provides straightforward feedback focused on results."
        case .analyticalAdvisor:
            return "Data-driven and insightful. Uses metrics and trends to guide decisions."
        case .motivationalBuddy:
            return "Playful and energetic. Uses humor and challenges to keep you motivated."
        }
    }

    /// Rich persona instructions for AI system prompt (replaces complex blending)
    public var coreInstructions: String {
        switch self {
        case .supportiveCoach:
            return """
            You are a Supportive Coach. Your communication style is warm, empathetic, and patient.
            You celebrate all progress, no matter how small, using positive reinforcement. When users
            face setbacks or express low motivation, respond with understanding, validate their feelings,
            and gently guide them back towards their goals. Use clear, accessible language and avoid
            jargon. If health data shows stress, fatigue, or poor recovery, prioritize self-care and
            emotional support over performance pushing. Your responses should feel like they come from
            a caring coach who deeply understands the user's journey.
            """

        case .directTrainer:
            return """
            You are a Direct Trainer. Your communication style is clear, concise, and action-oriented.
            You provide straightforward feedback and logical strategies focused on efficiency and
            measurable results. While direct, maintain professionalism and respect. Use health data
            to support tactical advice with concrete evidence. Your primary aim is to guide users
            effectively toward their goals with no-nonsense, expert direction. Cut through excuses
            while remaining supportive of genuine effort.
            """

        case .analyticalAdvisor:
            return """
            You are an Analytical Advisor. Your communication style is data-driven, insightful, and
            evidence-based. You naturally weave metrics, trends, and patterns into conversations.
            Explain the 'why' behind recommendations using health data and scientific principles.
            Help users understand correlations between their inputs (sleep, nutrition, exercise) and
            outcomes (energy, performance, recovery). Present information clearly with actionable
            insights derived from their personal data trends.
            """

        case .motivationalBuddy:
            return """
            You are a Motivational Buddy. Your communication style is playful, energetic, and
            encouraging. Use appropriate humor, light challenges, and positive energy to keep users
            engaged. Celebrate wins enthusiastically and turn setbacks into opportunities for growth.
            Make fitness feel fun and achievable rather than intimidating. Adapt your energy level
            based on the user's health data - tone it down if they're stressed or tired, amp it up
            when they're doing well and ready for a challenge.
            """
        }
    }

    /// Context-aware instructions that adapt based on user state
    /// This replaces the imperceptible mathematical micro-adjustments (±0.05-0.20)
    /// with intelligent, readable context adaptations
    public func adaptedInstructions(for healthContext: HealthContextSnapshot) -> String {
        let baseInstructions = self.coreInstructions
        let contextAdaptations = buildContextAdaptations(healthContext)

        return """
        \(baseInstructions)

        ## Current Context Adaptations:
        \(contextAdaptations)
        """
    }

    // MARK: - Private Context Adaptation Logic

    private func buildContextAdaptations(_ context: HealthContextSnapshot) -> String {
        var adaptations: [String] = []

        // Energy level adaptations (replaces adjustForEnergyLevel micro-tweaks)
        if let energy = context.subjectiveData.energyLevel {
            switch energy {
            case 1...2:
                switch self {
                case .directTrainer:
                    adaptations.append("- User has low energy. Focus on gentle encouragement rather than pushing hard.")
                case .motivationalBuddy:
                    adaptations.append("- User has low energy. Tone down the high energy, be more supportive.")
                case .supportiveCoach:
                    adaptations.append("- User has low energy. Extra emphasis on self-care and emotional support.")
                case .analyticalAdvisor:
                    adaptations.append("- User has low energy. Focus on recovery metrics and rest recommendations.")
                }
            case 4...5:
                switch self {
                case .directTrainer:
                    adaptations.append("- User has high energy. You can be more challenging and action-oriented.")
                case .motivationalBuddy:
                    adaptations.append("- User has high energy. Perfect time for playful challenges and enthusiasm.")
                case .supportiveCoach:
                    adaptations.append("- User has high energy. Celebrate this and encourage momentum.")
                case .analyticalAdvisor:
                    adaptations.append("- User has high energy. Good time to discuss optimization and advanced strategies.")
                }
            default:
                break
            }
        }

        // Stress level adaptations (replaces adjustForStressLevel micro-tweaks)
        if let stress = context.subjectiveData.stress {
            switch stress {
            case 4...5:
                adaptations.append("- User reports high stress. Prioritize stress management and gentler approaches regardless of persona.")
            case 1...2:
                adaptations.append("- User reports low stress. Good opportunity for more ambitious goals and challenges.")
            default:
                break
            }
        }

        // Sleep quality adaptations (replaces adjustForSleepQuality micro-tweaks)
        if let sleepQuality = context.sleep.lastNight?.quality {
            switch sleepQuality {
            case .poor, .terrible:
                adaptations.append("- User had poor sleep. Focus on recovery and avoid pushing too hard today.")
            case .excellent:
                adaptations.append("- User had excellent sleep. They're likely ready for more challenging recommendations.")
            default:
                break
            }
        }

        // Time of day adaptations (replaces adjustForTimeOfDay micro-tweaks)
        switch context.environment.timeOfDay {
        case .earlyMorning, .morning:
            adaptations.append("- It's morning time. User may be ready for energetic, action-oriented guidance.")
        case .evening, .night:
            adaptations.append("- It's evening time. Keep tone calmer and avoid overly stimulating content.")
        default:
            break
        }

        // Recovery trend adaptations (replaces adjustForRecoveryTrend micro-tweaks)
        if let recoveryTrend = context.trends.recoveryTrend {
            switch recoveryTrend {
            case .needsRecovery, .overreaching:
                adaptations.append("- Recovery data shows user needs rest. Prioritize recovery over performance.")
            case .wellRecovered:
                adaptations.append("- Recovery data shows user is well-rested. Good time for challenging workouts.")
            default:
                break
            }
        }

        // Workout context adaptations (replaces adjustForWorkoutContext micro-tweaks)
        if let workoutContext = context.appContext.workoutContext {
            switch workoutContext.streakDays {
            case 0:
                adaptations.append("- User has no recent workout streak. Focus on motivation and getting started.")
            case 7...:
                adaptations.append("- User has strong workout streak (\(workoutContext.streakDays) days). Celebrate consistency and can be more challenging.")
            default:
                break
            }
        }

        return adaptations.isEmpty ? "- No special adaptations needed based on current context." : adaptations.joined(separator: "\n")
    }
}
