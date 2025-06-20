import SwiftUI

// MARK: - BodyCompositionGoalsView
struct BodyCompositionGoalsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showGoals = false
    @State private var llmPrompt: String = "Any body transformation goals?"
    @State private var llmSubtitle: String = "Choose what excites you (or none at all!)"
    @State private var suggestedDefaults: [BodyRecompositionGoal] = []
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
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
                            CascadeText(llmPrompt)
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.xl)
                        }
                        
                        // Subtitle
                        if showGoals {
                            Text(llmSubtitle)
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Goals list
                        if showGoals {
                            VStack(spacing: AppSpacing.md) {
                                ForEach(Array(BodyRecompositionGoal.allCases.enumerated()), id: \.element) { index, goal in
                                    BodyCompositionGoalRow(
                                        goal: goal,
                                        isSelected: viewModel.bodyRecompositionGoals.contains(goal),
                                        action: { viewModel.toggleBodyGoal(goal) }
                                    )
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.08 + 0.6),
                                        value: animateIn
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenPadding)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom buttons
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
                    
                    Button(action: { skipBodyGoals() }) {
                        Text("Just overall fitness for me")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                    }
                    .opacity(animateIn ? 0.8 : 0)
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
            
            // Show goals after title animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showGoals = true
                }
            }
            
            // Load LLM-generated content and smart defaults
            Task {
                await loadLLMContent()
            }
        }
        .accessibilityIdentifier("onboarding.bodyComposition")
    }
    
    // MARK: - Computed Properties
    
    
    private var continueButtonText: String {
        let count = viewModel.bodyRecompositionGoals.count
        if count == 0 {
            return "Let's move on"
        } else if count == 1 {
            return "Great choice! Let's continue"
        } else {
            return "Love these \(count) goals! Next"
        }
    }
    
    // MARK: - Methods
    
    private func handleContinue() {
        viewModel.navigateToNext()
    }
    
    private func skipBodyGoals() {
        // Clear any selected goals
        viewModel.bodyRecompositionGoals = []
        
        // Continue without body goals
        viewModel.navigateToNext()
    }
    
    // MARK: - LLM Content Loading
    
    private func loadLLMContent() async {
        // Get dynamic prompt
        let prompt = await viewModel.getLLMPrompt(for: .bodyComposition)
        if !prompt.isEmpty {
            llmPrompt = prompt
        }
        
        // Get LLM-suggested defaults
        let defaults = await viewModel.getLLMDefaults(for: .bodyComposition)
        if !defaults.isEmpty {
            // Map string defaults to BodyRecompositionGoal enum
            let goalDefaults = defaults.compactMap { goalString -> BodyRecompositionGoal? in
                switch goalString.lowercased() {
                case "lose fat", "losefat":
                    return .loseFat
                case "gain muscle", "gainmuscle", "build muscle":
                    return .gainMuscle
                case "get toned", "gettoned", "tone up":
                    return .getToned
                case "improve definition", "improvedefinition", "get defined":
                    return .improveDefinition
                case "body recomposition", "bodyrecomposition", "recomp":
                    return .bodyRecomposition
                default:
                    return nil
                }
            }
            
            // Apply smart defaults if nothing selected yet
            if viewModel.bodyRecompositionGoals.isEmpty && !goalDefaults.isEmpty {
                viewModel.bodyRecompositionGoals = goalDefaults
                suggestedDefaults = goalDefaults
                
                // Update subtitle to indicate we pre-selected
                llmSubtitle = "Picked a few based on your profile - feel free to change!"
            }
        }
        
        // Get LLM-generated subtitle if no defaults were applied
        if suggestedDefaults.isEmpty {
            if let llmService = viewModel.onboardingLLMService,
               let userId = await viewModel.userService.getCurrentUserId() {
                do {
                    let responses = viewModel.collectPreviousResponses()
                    let content = try await llmService.generateScreenContent(
                        for: .bodyComposition,
                        userId: userId,
                        previousResponses: responses.asDictionary
                    )
                    
                    if let placeholder = content.placeholderText {
                        await MainActor.run {
                            llmSubtitle = placeholder
                        }
                    }
                } catch {
                    // Keep default subtitle
                }
            }
        }
    }
    
    private func applySmartDefaults() {
        // This method is now replaced by LLM-driven defaults in loadLLMContent()
        // Keeping empty method to avoid breaking changes
    }
}

// MARK: - Goal Row Component
private struct BodyCompositionGoalRow: View {
    let goal: BodyRecompositionGoal
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? gradientManager.active.accentColor(for: colorScheme) : Color.primary.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    // Helpful description
                    Text(goalDescription(for: goal))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func goalDescription(for goal: BodyRecompositionGoal) -> String {
        switch goal {
        case .loseFat:
            return "Reduce body fat percentage"
        case .gainMuscle:
            return "Increase lean muscle mass"
        case .getToned:
            return "Create definition and firmness"
        case .improveDefinition:
            return "Enhance muscle visibility"
        case .bodyRecomposition:
            return "Transform your physique"
        }
    }
}

// Preview removed - use app preview for testing