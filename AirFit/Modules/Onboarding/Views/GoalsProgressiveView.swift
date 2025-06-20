import SwiftUI
import Observation

// MARK: - GoalsProgressiveView
struct GoalsProgressiveView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showSuggestions = false
    @State private var isParsing = false
    @FocusState private var textFieldFocused: Bool
    @State private var llmUnderstanding = ""
    @State private var showRefinement = false
    @State private var refinementText = ""
    @State private var isConfirmed = false
    @State private var llmPrompt: String = "What are you hoping to accomplish?"
    @State private var llmPlaceholder: String = "I want to get stronger and have more energy..."
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
                        
                        // Text input area
                        if !showSuggestions {
                            goalTextInput
                        }
                        
                        // Parsing indicator
                        if isParsing {
                            HStack(spacing: AppSpacing.sm) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Let me think about this...")
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
            // Load LLM-generated content
            Task {
                await loadLLMContent()
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
        .accessibilityIdentifier("onboarding.goals")
    }
    
    // MARK: - View Components
    
    @ViewBuilder private var goalTextInput: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.functionalGoalsText.isEmpty {
                    Text(llmPlaceholder)
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
    
    @ViewBuilder private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            // LLM's understanding
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Got it! So you want to:")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(llmUnderstanding)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .transition(.opacity.combined(with: .move(edge: .top)))
            
            // Confirmation or refinement
            VStack(spacing: AppSpacing.md) {
                if !showRefinement {
                    // Initial confirmation buttons
                    HStack(spacing: AppSpacing.md) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isConfirmed = true
                            }
                        }, label: {
                            Text("That's exactly right!")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(gradientManager.currentGradient(for: colorScheme))
                                )
                        })
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showRefinement = true
                            }
                        }, label: {
                            Text("Actually, there's more...")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(gradientManager.active.accentColor(for: colorScheme).opacity(0.3), lineWidth: 1)
                                        )
                                )
                        })
                    }
                } else {
                    // Refinement text field
                    VStack(spacing: AppSpacing.sm) {
                        Text("Tell me what I missed:")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        TextField("Actually, I also want to...", text: $refinementText)
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            .onSubmit {
                                Task {
                                    await refineGoals()
                                }
                            }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        if showSuggestions {
            return isConfirmed || (!showRefinement && !llmUnderstanding.isEmpty)
        } else {
            return !viewModel.functionalGoalsText.isEmpty
        }
    }
    
    private var continueButtonText: String {
        if showSuggestions {
            if isConfirmed {
                return "Perfect, let's continue"
            } else if showRefinement {
                return "Got it, update my goals"
            } else {
                return "Sounds good to me"
            }
        } else {
            return "Keep going"
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
        
        // Use LLM to understand and expand on the user's goals
        let interpretation = await viewModel.interpretUserInput(viewModel.functionalGoalsText, for: .goals)
        let understanding: String
        if let interpretation = interpretation {
            understanding = interpretation
        } else {
            understanding = await viewModel.parseGoalsWithLLM()
        }
        
        // Update UI with LLM's understanding
        await MainActor.run {
            llmUnderstanding = understanding
            
            // Show the understanding for confirmation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isParsing = false
                showSuggestions = true
            }
        }
    }
    
    private func refineGoals() async {
        guard !refinementText.isEmpty else { return }
        
        // Append refinement to original goals
        viewModel.functionalGoalsText += ". " + refinementText
        
        // Re-parse with updated goals
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isParsing = true
            showRefinement = false
            refinementText = ""
        }
        
        // Re-run LLM understanding
        await parseGoals()
    }
    
    private func handleContinue() {
        // If user is refining, process the refinement first
        if showRefinement && !refinementText.isEmpty {
            Task {
                await refineGoals()
            }
            return
        }
        
        // The functional goals text already contains everything the user expressed
        // The LLM will handle all the parsing and understanding during synthesis
        viewModel.navigateToNext()
    }
    
    // MARK: - LLM Content Loading
    
    private func loadLLMContent() async {
        // Get dynamic prompt based on user's context
        let prompt = await viewModel.getLLMPrompt(for: .goals)
        if !prompt.isEmpty {
            llmPrompt = prompt
        }
        
        // Get personalized placeholder
        if let placeholder = await viewModel.getLLMPlaceholder(for: .goals) {
            llmPlaceholder = placeholder
        }
    }
}

