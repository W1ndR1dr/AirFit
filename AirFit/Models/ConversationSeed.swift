import Foundation

// MARK: - Conversation Seed

/// A conversation seed is a lighthearted, fun conversation starter designed to
/// organically gather context about the user without feeling like an interview.
///
/// Philosophy: Context maximalist, human dominant vibe.
/// The AI should feel like a warm, curious friend who happens to be incredibly
/// knowledgeable—a savant personal trainer with a PhD who only surfaces that
/// knowledge when it's actually relevant.
struct ConversationSeed: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let aiOpener: String
    let gatheringFocus: [GatheringFocus]

    /// What context this seed is designed to subtly uncover
    enum GatheringFocus: String, CaseIterable {
        case communicationStyle = "communication_style"
        case schedule = "schedule"
        case energyPatterns = "energy_patterns"
        case motivation = "motivation"
        case experience = "experience"
        case dietaryPreferences = "dietary_preferences"
        case lifeContext = "life_context"
        case stressLevel = "stress_level"
        case goals = "goals"
        case personality = "personality"
        case trainingPreferences = "training_preferences"
        case recoveryHabits = "recovery_habits"
    }
}

// MARK: - Seed Library

extension ConversationSeed {
    /// The initial set of seeds for users without a profile yet.
    /// These are designed to feel fun and lighthearted, not clinical.
    static let initialSeeds: [ConversationSeed] = [
        .morningVibes,
        .fitnessStory,
        .foodTalk,
        .lifeLatley,
        .workoutFeels,
        .dreamScenario
    ]

    /// Seeds for users who already have a profile but want to deepen it.
    /// These are more tailored and can reference what's already known.
    static let enhancementSeeds: [ConversationSeed] = [
        .unwindingTime,
        .challengesAndWins,
        .socialFitness,
        .guiltyPleasures
    ]

    // MARK: - Initial Seeds

    static let morningVibes = ConversationSeed(
        id: "morning_vibes",
        icon: "sunrise.fill",
        title: "Morning vibes",
        subtitle: "Sunrise warrior or snooze champion?",
        aiOpener: "Okay real talk—when your alarm goes off, are you the type to spring out of bed ready to conquer, or do you have a 47-step snooze ritual? No judgment either way 😄",
        gatheringFocus: [.schedule, .energyPatterns, .personality, .communicationStyle]
    )

    static let fitnessStory = ConversationSeed(
        id: "fitness_story",
        icon: "figure.run",
        title: "Your fitness story",
        subtitle: "How'd you get into all this?",
        aiOpener: "I'm curious about your fitness origin story. Was there a moment that got you into working out, or has it always been your thing? Everyone's path is so different.",
        gatheringFocus: [.motivation, .experience, .personality, .goals]
    )

    static let foodTalk = ConversationSeed(
        id: "food_talk",
        icon: "fork.knife",
        title: "Food talk",
        subtitle: "The good, the bad, the delicious",
        aiOpener: "Let's talk food. What's something you could eat every day and never get bored of? And on the flip side, anything you absolutely refuse to eat?",
        gatheringFocus: [.dietaryPreferences, .personality, .communicationStyle]
    )

    static let lifeLatley = ConversationSeed(
        id: "life_lately",
        icon: "leaf.fill",
        title: "Life lately",
        subtitle: "What's your world looking like?",
        aiOpener: "Tell me a bit about what life looks like for you right now. Busy season? Chill vibes? Somewhere in between? I find it helps to know what you're working with.",
        gatheringFocus: [.lifeContext, .stressLevel, .schedule, .communicationStyle]
    )

    static let workoutFeels = ConversationSeed(
        id: "workout_feels",
        icon: "heart.circle.fill",
        title: "How workouts feel",
        subtitle: "Beyond the reps and sets",
        aiOpener: "Here's a fun one—when you finish a really good workout, how do you actually feel? And what makes a workout feel 'good' to you anyway?",
        gatheringFocus: [.motivation, .trainingPreferences, .personality, .recoveryHabits]
    )

    static let dreamScenario = ConversationSeed(
        id: "dream_scenario",
        icon: "sparkles",
        title: "If anything was possible",
        subtitle: "No limits, just vibes",
        aiOpener: "Okay dream scenario time—if you had unlimited time, energy, and resources for your health and fitness, what would that look like? Just curious where your mind goes.",
        gatheringFocus: [.goals, .motivation, .personality, .trainingPreferences]
    )

    // MARK: - Enhancement Seeds (for users with existing profiles)

    static let unwindingTime = ConversationSeed(
        id: "unwinding_time",
        icon: "moon.stars.fill",
        title: "Unwinding",
        subtitle: "How do you decompress?",
        aiOpener: "After a long day, what's your go-to way to unwind? Couch and Netflix? A walk? Something else entirely?",
        gatheringFocus: [.recoveryHabits, .stressLevel, .personality, .lifeContext]
    )

    static let challengesAndWins = ConversationSeed(
        id: "challenges_wins",
        icon: "trophy.fill",
        title: "Highs and lows",
        subtitle: "The real talk version",
        aiOpener: "What's been your biggest challenge with fitness or nutrition lately? And flip side—any recent wins, even small ones?",
        gatheringFocus: [.motivation, .goals, .stressLevel, .experience]
    )

    static let socialFitness = ConversationSeed(
        id: "social_fitness",
        icon: "person.2.fill",
        title: "Solo or squad",
        subtitle: "Your workout social style",
        aiOpener: "Are you more of a solo workout person, or do you thrive with a gym buddy or group class? There's no wrong answer—just curious about your vibe.",
        gatheringFocus: [.trainingPreferences, .personality, .motivation]
    )

    static let guiltyPleasures = ConversationSeed(
        id: "guilty_pleasures",
        icon: "face.smiling.fill",
        title: "Guilty pleasures",
        subtitle: "No judgment zone",
        aiOpener: "Okay, confession time—what's your guilty pleasure food or lazy habit that you'd never give up, no matter what? I promise I won't lecture you about it 😄",
        gatheringFocus: [.dietaryPreferences, .personality, .communicationStyle]
    )
}

// MARK: - System Prompt for Seed Conversations

extension ConversationSeed {
    /// The system prompt addendum for seed-initiated conversations.
    /// This guides the AI to be warm, curious, and human—not clinical.
    static let seedConversationSystemPrompt = """
You're having a casual, getting-to-know-you conversation with someone new. This is NOT a coaching session—it's just two people chatting and vibing.

YOUR VIBE:
• Warm, genuine, naturally curious
• Use natural language—contractions, maybe light humor when it fits
• Ask follow-up questions that show you're actually listening
• Keep it mutual—this is a conversation, not an interview
• NO fitness advice unless they specifically ask for it
• NO goal-setting, action items, or "coach mode"
• Just be a genuinely interested conversational partner

WHAT YOU'RE SUBTLY LEARNING (but never making obvious):
• How they communicate—formal vs casual, detailed vs brief, humor style
• Their life context—schedule, responsibilities, stress level
• Their relationship with fitness, food, and health
• What motivates them and what they value
• Their personality and vibe

RESPONSE STYLE:
• Keep it concise—2-3 sentences usually, unless they share something that deserves more
• Match their energy and communication style
• Use occasional emojis if they do, skip them if they don't
• Be genuinely curious, not performatively interested
• It's okay to share tiny relatable bits about yourself to keep it mutual

Remember: You're a savant—you have PhD-level knowledge of exercise science and nutrition—but you're NOT showing that off here. You're just being a warm human who happens to be curious about them. The expertise only comes out later, when it's actually helpful.
"""
}

// MARK: - Notification for Seed Selection

extension Notification.Name {
    /// Posted when a user selects a conversation seed.
    /// userInfo contains "seed" key with the ConversationSeed.
    static let conversationSeedSelected = Notification.Name("conversationSeedSelected")
}
