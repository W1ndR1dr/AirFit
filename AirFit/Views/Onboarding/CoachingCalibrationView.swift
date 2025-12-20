import SwiftUI
import SwiftData

// MARK: - Coaching Calibration View

/// Quick preference questionnaire that captures coaching STYLE.
///
/// This screen addresses the gap between user data extraction (who you ARE)
/// and coaching directives (HOW you want to be coached). The extraction system
/// can discover facts through conversation, but behavioral permissions like
/// "roast me" or "no unsolicited advice" need explicit consent.
///
/// Takes ~30 seconds. Fun chips, not boring forms.
struct CoachingCalibrationView: View {
    @Environment(\.modelContext) private var modelContext

    let onComplete: () -> Void
    let onSkip: () -> Void

    // MARK: - State

    @State private var currentQuestion = 0
    @State private var selections: [Int: Set<Int>] = [:]
    @State private var showingComplete = false

    // MARK: - Questions Configuration

    private let questions: [CalibrationQuestion] = [
        CalibrationQuestion(
            id: 0,
            emoji: "✨",
            title: "What's your vibe?",
            subtitle: "Pick all that resonate with you",
            options: [
                CalibrationOption(id: 0, label: "Bro energy", description: "Old friend who lifts", icon: "🤙"),
                CalibrationOption(id: 1, label: "Pro coach", description: "Direct and efficient", icon: "🎯"),
                CalibrationOption(id: 2, label: "Hype squad", description: "Cheerleader energy", icon: "📣"),
                CalibrationOption(id: 3, label: "Data nerd", description: "Numbers and analysis", icon: "📊"),
                CalibrationOption(id: 4, label: "Zen master", description: "Calm and mindful", icon: "🧘"),
                CalibrationOption(id: 5, label: "Drill sergeant", description: "No excuses, get it done", icon: "🪖"),
                CalibrationOption(id: 6, label: "Science geek", description: "Evidence-based everything", icon: "🔬"),
                CalibrationOption(id: 7, label: "Motivator", description: "Inspire and uplift", icon: "🌟")
            ],
            multiSelect: true
        ),
        CalibrationQuestion(
            id: 1,
            emoji: "🔥",
            title: "Feedback style?",
            subtitle: "How should I deliver truth bombs?",
            options: [
                CalibrationOption(id: 0, label: "Roast me", description: "Give me hell when needed", icon: "😈"),
                CalibrationOption(id: 1, label: "Playful jabs", description: "Light teasing is fine", icon: "😏"),
                CalibrationOption(id: 2, label: "Sandwich it", description: "Critique between praise", icon: "🥪"),
                CalibrationOption(id: 3, label: "Straight talk", description: "Just facts, no fluff", icon: "📏"),
                CalibrationOption(id: 4, label: "Gentle nudges", description: "Soft encouragement", icon: "🤗"),
                CalibrationOption(id: 5, label: "Celebrate wins", description: "Focus on the positive", icon: "🎉")
            ],
            multiSelect: true
        ),
        CalibrationQuestion(
            id: 2,
            emoji: "💡",
            title: "When should I chime in?",
            subtitle: "Pick your preferences",
            options: [
                CalibrationOption(id: 0, label: "Only when asked", description: "I'll come to you", icon: "🤐"),
                CalibrationOption(id: 1, label: "Proactive tips", description: "Share ideas freely", icon: "💬"),
                CalibrationOption(id: 2, label: "Call me out", description: "Flag when I slip", icon: "🚨"),
                CalibrationOption(id: 3, label: "Pattern alerts", description: "Notice my trends", icon: "📈"),
                CalibrationOption(id: 4, label: "Check-ins", description: "Regular pulse checks", icon: "👋"),
                CalibrationOption(id: 5, label: "Celebrate PRs", description: "Hype my wins", icon: "🏆")
            ],
            multiSelect: true
        ),
        CalibrationQuestion(
            id: 3,
            emoji: "📚",
            title: "Explanation depth?",
            subtitle: "How much detail do you want?",
            options: [
                CalibrationOption(id: 0, label: "Deep dives", description: "Full scientific breakdown", icon: "🔬"),
                CalibrationOption(id: 1, label: "TL;DR", description: "Bottom line up front", icon: "⚡"),
                CalibrationOption(id: 2, label: "Depends", description: "Read the room", icon: "🎲"),
                CalibrationOption(id: 3, label: "Analogies", description: "Make it relatable", icon: "🎭"),
                CalibrationOption(id: 4, label: "Visual learner", description: "Charts and examples", icon: "📊"),
                CalibrationOption(id: 5, label: "Step-by-step", description: "Clear action items", icon: "📋")
            ],
            multiSelect: true
        ),
        CalibrationQuestion(
            id: 4,
            emoji: "🎨",
            title: "Personality dial?",
            subtitle: "How expressive should I be?",
            options: [
                CalibrationOption(id: 0, label: "Unhinged", description: "Wild, weird, wonderful", icon: "🎢"),
                CalibrationOption(id: 1, label: "Spicy", description: "Colorful with focus", icon: "🌶️"),
                CalibrationOption(id: 2, label: "Balanced", description: "Warm but professional", icon: "⚖️"),
                CalibrationOption(id: 3, label: "Clean", description: "Minimal, efficient", icon: "🧹"),
                CalibrationOption(id: 4, label: "Emoji lover", description: "Express with emojis", icon: "😎"),
                CalibrationOption(id: 5, label: "Dry wit", description: "Deadpan humor", icon: "🗿")
            ],
            multiSelect: true
        )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                if showingComplete {
                    completionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    questionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentQuestion)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingComplete)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.textPrimary.opacity(0.1))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }

    private var progress: Double {
        if showingComplete { return 1.0 }
        return Double(currentQuestion) / Double(questions.count)
    }

    // MARK: - Question View

    private var questionView: some View {
        let question = questions[currentQuestion]

        return VStack(spacing: 24) {
            Spacer()

            // Emoji & Title
            VStack(spacing: 12) {
                Text(question.emoji)
                    .font(.system(size: 64))

                Text(question.title)
                    .font(.headlineLarge)
                    .foregroundStyle(Theme.textPrimary)

                Text(question.subtitle)
                    .font(.bodyLarge)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Options (scrollable for many choices)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(question.options) { option in
                        optionButton(option, for: question)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            Spacer()

            // Bottom buttons
            HStack(spacing: 16) {
                if currentQuestion > 0 {
                    Button {
                        currentQuestion -= 1
                    } label: {
                        Text("Back")
                            .font(.bodyLarge.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.textPrimary.opacity(0.05))
                            )
                    }
                    .frame(maxWidth: 100)
                }

                Button {
                    advanceOrComplete()
                } label: {
                    Text(isLastQuestion ? "Done" : "Next")
                        .font(.bodyLarge.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canAdvance ? Theme.accent : Theme.accent.opacity(0.3))
                        )
                }
                .disabled(!canAdvance)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Option Button

    private func optionButton(_ option: CalibrationOption, for question: CalibrationQuestion) -> some View {
        let isSelected = selections[question.id]?.contains(option.id) ?? false

        return Button {
            toggleSelection(option, for: question)
        } label: {
            HStack(spacing: 16) {
                Text(option.icon)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(.bodyLarge.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Text(option.description)
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.accent : Theme.textPrimary.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.textPrimary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Theme.accent : Theme.textPrimary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎯")
                .font(.system(size: 80))

            Text("Dialed in")
                .font(.headlineLarge)
                .foregroundStyle(Theme.textPrimary)

            Text("I'll coach you your way.")
                .font(.bodyLarge)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Button {
                saveAndComplete()
            } label: {
                Text("Let's go")
                    .font(.bodyLarge.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.accent)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Logic

    private var isLastQuestion: Bool {
        currentQuestion == questions.count - 1
    }

    private var canAdvance: Bool {
        // Must have at least one selection for current question
        guard let selected = selections[currentQuestion] else { return false }
        return !selected.isEmpty
    }

    private func toggleSelection(_ option: CalibrationOption, for question: CalibrationQuestion) {
        var current = selections[question.id] ?? []

        if question.multiSelect {
            if current.contains(option.id) {
                current.remove(option.id)
            } else {
                current.insert(option.id)
            }
        } else {
            // Single select - replace
            current = [option.id]
        }

        selections[question.id] = current
    }

    private func advanceOrComplete() {
        if isLastQuestion {
            withAnimation {
                showingComplete = true
            }
        } else {
            currentQuestion += 1
        }
    }

    private func saveAndComplete() {
        // Build coaching directives from selections
        let directives = buildCoachingDirectives()

        // Update profile
        let profile = LocalProfile.getOrCreate(in: modelContext)
        profile.coachingDirectives = directives
        profile.lastLocalUpdate = Date()
        try? modelContext.save()

        print("[CoachingCalibration] Saved directives: \(directives)")

        // Complete first, then trigger async persona synthesis
        onComplete()

        // Trigger async persona synthesis (non-blocking)
        // This synthesizes a rich prose coaching persona from:
        // - Profile data (who they are)
        // - Calibration directives (how they want coaching)
        // - Memories (relationship texture - empty for new users)
        // - Patterns (observed behaviors - empty for new users)
        //
        // The persona will be generic at first but matures over time
        // as the relationship develops through conversations.
        //
        // Note: Uses regular Task (not detached) to stay on MainActor
        // since ModelContext is MainActor-isolated
        Task {
            await PersonalitySynthesisService.shared.synthesizeAndSave(
                modelContext: modelContext
            )
        }
    }

    // MARK: - Build Directives

    private func buildCoachingDirectives() -> CoachingDirectives {
        var directives = CoachingDirectives()

        // Q0: Vibe (multi-select, 8 options → 4 enum values)
        // Priority: first selected option that maps to an enum wins
        if let vibeSelections = selections[0] {
            // Map each selection to a tone, take first match
            for id in vibeSelections.sorted() {
                switch id {
                case 0: directives.tone = .broEnergy; break    // Bro energy
                case 1: directives.tone = .professional; break  // Pro coach
                case 2: directives.tone = .supportive; break    // Hype squad
                case 3: directives.tone = .analytical; break    // Data nerd
                case 4: directives.tone = .supportive; break    // Zen master → calm supportive
                case 5: directives.tone = .professional; break  // Drill sergeant → direct
                case 6: directives.tone = .analytical; break    // Science geek → evidence-based
                case 7: directives.tone = .supportive; break    // Motivator → uplifting
                default: continue
                }
                break  // Stop after first match
            }
        }

        // Q1: Feedback style (multi-select, 6 options → 3 enum values)
        if let feedbackSelections = selections[1] {
            for id in feedbackSelections.sorted() {
                switch id {
                case 0: directives.roastTolerance = .roastMe; break    // Roast me
                case 1: directives.roastTolerance = .lightJokes; break // Playful jabs
                case 2: directives.roastTolerance = .lightJokes; break // Sandwich it
                case 3: directives.roastTolerance = .lightJokes; break // Straight talk
                case 4: directives.roastTolerance = .keepItKind; break // Gentle nudges
                case 5: directives.roastTolerance = .keepItKind; break // Celebrate wins
                default: continue
                }
                break
            }
        }

        // Q2: When to chime in (multi-select, 6 options → boolean flags)
        if let chimeSelections = selections[2] {
            directives.onlyAdviseWhenAsked = chimeSelections.contains(0) // Only when asked
            directives.proactiveSuggestions = chimeSelections.contains(1) || chimeSelections.contains(3) || chimeSelections.contains(4)
            // Proactive tips, Pattern alerts, or Check-ins all imply proactive behavior
            directives.callMeOut = chimeSelections.contains(2) // Call me out
            // Note: Pattern alerts (3) and Celebrate PRs (5) captured by proactiveSuggestions for now
        }

        // Q3: Explanation depth (multi-select, 6 options → 3 enum values)
        if let depthSelections = selections[3] {
            for id in depthSelections.sorted() {
                switch id {
                case 0: directives.explanationDepth = .deepDives; break  // Deep dives
                case 1: directives.explanationDepth = .quickHits; break  // TL;DR
                case 2: directives.explanationDepth = .contextual; break // Depends
                case 3: directives.explanationDepth = .contextual; break // Analogies
                case 4: directives.explanationDepth = .contextual; break // Visual learner
                case 5: directives.explanationDepth = .quickHits; break  // Step-by-step
                default: continue
                }
                break
            }
        }

        // Q4: Personality level (multi-select, 6 options → 3 enum values)
        if let personalitySelections = selections[4] {
            for id in personalitySelections.sorted() {
                switch id {
                case 0: directives.personalityLevel = .unhinged; break // Unhinged
                case 1: directives.personalityLevel = .spicy; break    // Spicy
                case 2: directives.personalityLevel = .spicy; break    // Balanced
                case 3: directives.personalityLevel = .clean; break    // Clean
                case 4: directives.personalityLevel = .spicy; break    // Emoji lover
                case 5: directives.personalityLevel = .spicy; break    // Dry wit
                default: continue
                }
                break
            }
        }

        return directives
    }
}

// MARK: - Supporting Types

struct CalibrationQuestion: Identifiable {
    let id: Int
    let emoji: String
    let title: String
    let subtitle: String
    let options: [CalibrationOption]
    let multiSelect: Bool
}

struct CalibrationOption: Identifiable {
    let id: Int
    let label: String
    let description: String
    let icon: String
}

// MARK: - Preview

#Preview {
    CoachingCalibrationView(
        onComplete: { print("Complete") },
        onSkip: { print("Skip") }
    )
}
