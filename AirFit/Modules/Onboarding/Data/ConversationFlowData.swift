import Foundation

struct ConversationFlowData {
    static func defaultFlow() -> [String: ConversationNode] {
        var nodes: [String: ConversationNode] = [:]
        
        // Opening
        let openingNode = ConversationNode(
            nodeType: .opening,
            question: ConversationQuestion(
                primary: "Hey! I'm here to help create your perfect fitness coach. What should I call you?",
                clarifications: [],
                examples: nil,
                voicePrompt: "What's your name?"
            ),
            inputType: .text(minLength: 1, maxLength: 50, placeholder: "Your name"),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "goals-primary")
            ],
            dataKey: "userName"
        )
        nodes["opening"] = openingNode
        
        // Goals
        let goalsPrimaryNode = ConversationNode(
            nodeType: .goals,
            question: ConversationQuestion(
                primary: "What brings you here? What's your main fitness goal right now?",
                clarifications: [
                    "Think about what you want to achieve in the next 3-6 months",
                    "Be as specific as you're comfortable with"
                ],
                examples: nil,
                voicePrompt: "Tell me about your fitness goals"
            ),
            inputType: .hybrid(
                primary: .text(minLength: 20, maxLength: 500, placeholder: "I want to..."),
                secondary: .voice(maxDuration: 60)
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "goals-motivation")
            ],
            dataKey: "primaryGoal"
        )
        nodes["goals-primary"] = goalsPrimaryNode
        
        let goalsMotivationNode = ConversationNode(
            nodeType: .goals,
            question: ConversationQuestion(
                primary: "What's driving this goal? What motivates you?",
                clarifications: [
                    "Understanding your 'why' helps me coach you better"
                ],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .singleChoice(options: [
                ChoiceOption(
                    id: "health",
                    text: "Health & Longevity",
                    emoji: "❤️",
                    traits: ["dataOrientation": 0.2, "structureNeed": 0.1]
                ),
                ChoiceOption(
                    id: "performance",
                    text: "Athletic Performance",
                    emoji: "🏆",
                    traits: ["intensityPreference": 0.3, "authorityPreference": 0.2]
                ),
                ChoiceOption(
                    id: "appearance",
                    text: "Look & Feel Better",
                    emoji: "✨",
                    traits: ["emotionalSupport": 0.1, "socialOrientation": 0.1]
                ),
                ChoiceOption(
                    id: "lifestyle",
                    text: "Active Lifestyle",
                    emoji: "🌟",
                    traits: ["structureNeed": -0.1, "intensityPreference": -0.1]
                )
            ]),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "lifestyle-activity")
            ],
            dataKey: "primaryMotivation"
        )
        nodes["goals-motivation"] = goalsMotivationNode
        
        // Lifestyle
        let lifestyleActivityNode = ConversationNode(
            nodeType: .lifestyle,
            question: ConversationQuestion(
                primary: "How would you describe your current activity level?",
                clarifications: [
                    "Be honest - this helps me set realistic expectations"
                ],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .slider(
                min: 0,
                max: 10,
                step: 1,
                labels: SliderLabels(
                    min: "Sedentary",
                    max: "Very Active",
                    center: "Moderately Active"
                )
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "lifestyle-schedule")
            ],
            dataKey: "activityLevel"
        )
        nodes["lifestyle-activity"] = lifestyleActivityNode
        
        let lifestyleScheduleNode = ConversationNode(
            nodeType: .lifestyle,
            question: ConversationQuestion(
                primary: "Tell me about your daily schedule. When do you prefer to work out?",
                clarifications: [
                    "Knowing your routine helps me suggest the best times to train"
                ],
                examples: nil,
                voicePrompt: "Describe your typical day"
            ),
            inputType: .text(
                minLength: 30,
                maxLength: 500,
                placeholder: "I usually wake up at... and have time to exercise..."
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "personality-coaching")
            ],
            dataKey: "schedule",
            validationRules: ValidationRules(required: false)
        )
        nodes["lifestyle-schedule"] = lifestyleScheduleNode
        
        // Personality
        let personalityCoachingNode = ConversationNode(
            nodeType: .personality,
            question: ConversationQuestion(
                primary: "How do you like to be coached?",
                clarifications: [
                    "Everyone responds differently to motivation"
                ],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .singleChoice(options: [
                ChoiceOption(
                    id: "drill-sergeant",
                    text: "Push me hard! I need tough love",
                    emoji: "💪",
                    traits: ["authorityPreference": 0.4, "intensityPreference": 0.3]
                ),
                ChoiceOption(
                    id: "cheerleader",
                    text: "Encourage me! I thrive on positivity",
                    emoji: "🎉",
                    traits: ["authorityPreference": -0.3, "emotionalSupport": 0.3]
                ),
                ChoiceOption(
                    id: "teacher",
                    text: "Educate me! I want to understand why",
                    emoji: "🧠",
                    traits: ["dataOrientation": 0.4, "structureNeed": 0.2]
                ),
                ChoiceOption(
                    id: "friend",
                    text: "Support me! Like a workout buddy",
                    emoji: "🤝",
                    traits: ["socialOrientation": 0.3, "emotionalSupport": 0.2]
                )
            ]),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "personality-stress")
            ],
            dataKey: "coachingStyle"
        )
        nodes["personality-coaching"] = personalityCoachingNode
        
        let personalityStressNode = ConversationNode(
            nodeType: .personality,
            question: ConversationQuestion(
                primary: "How do you handle setbacks or tough days?",
                clarifications: [
                    "This helps me support you when things get challenging"
                ],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .multiChoice(
                options: [
                    ChoiceOption(
                        id: "analyze",
                        text: "I analyze what went wrong",
                        emoji: "🔍",
                        traits: ["dataOrientation": 0.2]
                    ),
                    ChoiceOption(
                        id: "push-through",
                        text: "I push through anyway",
                        emoji: "⚡",
                        traits: ["intensityPreference": 0.2]
                    ),
                    ChoiceOption(
                        id: "need-support",
                        text: "I need encouragement",
                        emoji: "🤗",
                        traits: ["emotionalSupport": 0.3]
                    ),
                    ChoiceOption(
                        id: "take-break",
                        text: "I take a step back",
                        emoji: "🌊",
                        traits: ["structureNeed": -0.2]
                    )
                ],
                minSelections: 1,
                maxSelections: 2
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "preferences-communication")
            ],
            dataKey: "stressResponse"
        )
        nodes["personality-stress"] = personalityStressNode
        
        // Preferences
        let preferencesCommunicationNode = ConversationNode(
            nodeType: .preferences,
            question: ConversationQuestion(
                primary: "How much detail do you want in your workouts?",
                clarifications: [],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .slider(
                min: 0,
                max: 10,
                step: 1,
                labels: SliderLabels(
                    min: "Just tell me what to do",
                    max: "Explain everything",
                    center: "Balanced approach"
                )
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "preferences-personality")
            ],
            dataKey: "detailPreference"
        )
        nodes["preferences-communication"] = preferencesCommunicationNode
        
        let preferencesPersonalityNode = ConversationNode(
            nodeType: .preferences,
            question: ConversationQuestion(
                primary: "One more thing - any specific personality traits you'd like your coach to have?",
                clarifications: [
                    "Think about coaches or mentors you've connected with before"
                ],
                examples: nil,
                voicePrompt: "Describe your ideal coach's personality"
            ),
            inputType: .text(
                minLength: 0,
                maxLength: 500,
                placeholder: "I'd love a coach who..."
            ),
            branchingRules: [
                BranchingRule(condition: .always, nextNodeId: "confirmation")
            ],
            dataKey: "personalityPreferences",
            validationRules: ValidationRules(required: false)
        )
        nodes["preferences-personality"] = preferencesPersonalityNode
        
        // Confirmation
        let confirmationNode = ConversationNode(
            nodeType: .confirmation,
            question: ConversationQuestion(
                primary: "Perfect! I have everything I need to create your personalized coach.",
                clarifications: [
                    "Your coach will be ready in just a moment"
                ],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .singleChoice(options: [
                ChoiceOption(
                    id: "ready",
                    text: "Let's do this!",
                    emoji: "🚀",
                    traits: [:]
                )
            ]),
            branchingRules: [], // No next node - conversation complete
            dataKey: "confirmed"
        )
        nodes["confirmation"] = confirmationNode
        
        return nodes
    }
}