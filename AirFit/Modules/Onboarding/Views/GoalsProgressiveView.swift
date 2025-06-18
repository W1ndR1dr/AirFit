import SwiftUI
import Observation

// MARK: - GoalsProgressiveView
struct GoalsProgressiveView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showSuggestions = false
    @State private var isParsing = false
    @FocusState private var textFieldFocused: Bool
    @State private var parsedPrimaryGoal = ""
    @State private var selectedGoals: Set<SuggestedGoal> = []
    @State private var additionalGoalText = ""
    @State private var showConflictWarning = false
    @State private var conflictMessage = ""
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    // Suggested goals based on common fitness objectives
    private let suggestedGoals: [SuggestedGoal] = [
        SuggestedGoal(id: "muscle", text: "Build muscle definition", icon: "figure.strengthtraining.traditional"),
        SuggestedGoal(id: "cardio", text: "Improve cardio endurance", icon: "figure.run"),
        SuggestedGoal(id: "energy", text: "Have more energy", icon: "bolt.fill"),
        SuggestedGoal(id: "sleep", text: "Sleep better", icon: "moon.fill"),
        SuggestedGoal(id: "stress", text: "Reduce stress", icon: "leaf.fill")
    ]
    
    // Smart placeholder based on HealthKit data
    private var goalPlaceholder: String {
        if let healthData = viewModel.healthKitData {
            // Calculate BMI if we have weight and height
            if let weight = healthData.weight {
                if weight > 200 {
                    return "Lose weight, feel healthier..."
                }
            }
            
            // Check activity patterns
            if healthData.sleepSchedule == nil {
                return "Get more active, build strength..."
            }
        }
        return "Take my fitness to the next level..."
    }
    
    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { viewModel.navigateToPrevious() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundStyle(gradientManager.active.optimalTextColor(for: colorScheme))
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Title with cascade animation
                        if animateIn {
                            CascadeText("What would you like to achieve?")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.xl)
                        }
                        
                        // Text input area
                        if !showSuggestions {
                            goalTextInput
                        }
                        
                        // Parsing indicator
                        if isParsing {
                            HStack(spacing: AppSpacing.sm) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Understanding your goals...")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                            }
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        // Suggestions section
                        if showSuggestions {
                            suggestionsList
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom button
                VStack(spacing: AppSpacing.sm) {
                    Button(action: { handleContinue() }) {
                        Text(continueButtonText)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(gradientManager.currentGradient(for: colorScheme))
                            )
                            .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 6)
                    }
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: canContinue)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xl)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateIn)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
        .onChange(of: viewModel.functionalGoalsText) { oldValue, newValue in
            // Limit to 200 characters
            if newValue.count > 200 {
                viewModel.functionalGoalsText = String(newValue.prefix(200))
            }
            
            // Trigger parsing after user stops typing
            if !newValue.isEmpty && newValue != oldValue {
                scheduleParsingIfNeeded()
            }
        }
        .onChange(of: selectedGoals) { _, _ in
            checkForConflicts()
        }
        .accessibilityIdentifier("onboarding.goals")
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var goalTextInput: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.functionalGoalsText.isEmpty {
                    Text(goalPlaceholder)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                // Text editor
                TextEditor(text: $viewModel.functionalGoalsText)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($textFieldFocused)
            }
            .frame(minHeight: 120, maxHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Character count
            HStack {
                Text("\(viewModel.functionalGoalsText.count)/200")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .opacity(animateIn && !showSuggestions ? 1 : 0)
        .scaleEffect(animateIn && !showSuggestions ? 1 : 0.9)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateIn)
    }
    
    @ViewBuilder
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Parsed primary goal
            if !parsedPrimaryGoal.isEmpty {
                Text("I heard: \(parsedPrimaryGoal). What else?")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Goal checkboxes
            VStack(spacing: AppSpacing.sm) {
                ForEach(suggestedGoals) { goal in
                    GoalCheckbox(
                        goal: goal,
                        isSelected: selectedGoals.contains(goal),
                        onToggle: { toggleGoal(goal) }
                    )
                }
                
                // Something else option
                somethingElseOption
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Conflict warning
            if showConflictWarning {
                conflictWarningView
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    @ViewBuilder
    private var somethingElseOption: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: selectedGoals.contains(where: { $0.id == "other" }) ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(selectedGoals.contains(where: { $0.id == "other" }) ? 
                        gradientManager.active.accentColor(for: colorScheme) : .secondary)
                
                Text("Something else:")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleOtherGoal()
            }
            
            if selectedGoals.contains(where: { $0.id == "other" }) {
                TextField("Describe your goal", text: $additionalGoalText)
                    .font(.system(size: 17, weight: .regular))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            selectedGoals.contains(where: { $0.id == "other" }) ?
                            gradientManager.active.accentColor(for: colorScheme).opacity(0.5) :
                            Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
    
    @ViewBuilder
    private var conflictWarningView: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.orange)
            
            Text(conflictMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .padding(.horizontal, AppSpacing.screenPadding)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        if showSuggestions {
            return !selectedGoals.isEmpty || !additionalGoalText.isEmpty
        } else {
            return !viewModel.functionalGoalsText.isEmpty
        }
    }
    
    private var continueButtonText: String {
        if showSuggestions {
            let count = selectedGoals.count + (additionalGoalText.isEmpty ? 0 : 1)
            return count > 0 ? "Continue with \(count) goal\(count == 1 ? "" : "s")" : "Continue"
        } else {
            return "Continue"
        }
    }
    
    // MARK: - Methods
    
    private func scheduleParsingIfNeeded() {
        // Cancel previous parsing task
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // Schedule new parsing after 1.5 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak viewModel] in
            guard let viewModel = viewModel,
                  !viewModel.functionalGoalsText.isEmpty else { return }
            
            Task {
                await parseGoals()
            }
        }
    }
    
    private func parseGoals() async {
        // Start parsing animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isParsing = true
            textFieldFocused = false
        }
        
        // Simulate LLM parsing (in real app, call OnboardingService)
        try? await Task.sleep(for: .seconds(1.5))
        
        // Extract primary goal from text
        let text = viewModel.functionalGoalsText.lowercased()
        if text.contains("lose") && text.contains("weight") {
            parsedPrimaryGoal = "lose weight"
        } else if text.contains("build") && text.contains("muscle") {
            parsedPrimaryGoal = "build muscle"
        } else if text.contains("get") && text.contains("fit") {
            parsedPrimaryGoal = "get fit"
        } else if text.contains("improve") && text.contains("health") {
            parsedPrimaryGoal = "improve health"
        } else {
            parsedPrimaryGoal = "achieve your fitness goals"
        }
        
        // Show suggestions
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isParsing = false
            showSuggestions = true
        }
    }
    
    private func toggleGoal(_ goal: SuggestedGoal) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedGoals.contains(goal) {
                selectedGoals.remove(goal)
            } else {
                selectedGoals.insert(goal)
            }
        }
        HapticService.impact(.light)
    }
    
    private func toggleOtherGoal() {
        let otherGoal = SuggestedGoal(id: "other", text: "Other", icon: "plus.circle")
        toggleGoal(otherGoal)
    }
    
    private func checkForConflicts() {
        // Check for conflicting goals
        let hasMuscleGoal = selectedGoals.contains(where: { $0.id == "muscle" })
        let hasWeightLossGoal = parsedPrimaryGoal.contains("lose")
        
        if hasMuscleGoal && hasWeightLossGoal {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showConflictWarning = true
                conflictMessage = "Note: Building muscle while losing weight requires a careful approach - I'll help balance these goals!"
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showConflictWarning = false
            }
        }
    }
    
    private func handleContinue() {
        // Store selected goals in view model
        viewModel.bodyRecompositionGoals = selectedGoals.compactMap { goal in
            switch goal.id {
            case "muscle": return .gainMuscle
            case "cardio": return .improveDefinition
            default: return nil
            }
        }
        
        // Add additional goal text if provided
        if !additionalGoalText.isEmpty {
            viewModel.functionalGoalsText += ". Also: \(additionalGoalText)"
        }
        
        viewModel.navigateToNext()
    }
}

// MARK: - Supporting Types

struct SuggestedGoal: Identifiable, Hashable {
    let id: String
    let text: String
    let icon: String
}

// MARK: - Goal Checkbox Component

struct GoalCheckbox: View {
    let goal: SuggestedGoal
    let isSelected: Bool
    let onToggle: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? 
                    gradientManager.active.accentColor(for: colorScheme) : .secondary)
            
            Image(systemName: goal.icon)
                .font(.system(size: 18))
                .foregroundStyle(.primary.opacity(0.8))
            
            Text(goal.text)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? 
                            gradientManager.active.accentColor(for: colorScheme).opacity(0.5) :
                            Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}