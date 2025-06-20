import SwiftUI

// MARK: - LLMSynthesisView
struct LLMSynthesisView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var currentStep = 0
    @State private var gradientCycleProgress: CGFloat = 0
    @State private var processingFailed = false
    @State private var pulsateScale: CGFloat = 1.0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    
    // Processing steps that appear sequentially
    private var processingSteps: [(text: String, delay: Double)] {
        let context = viewModel.createContext()
        var steps: [(text: String, delay: Double)] = []
        
        // Health data step
        if context.healthData != nil {
            steps.append((text: "Looking at your health data...", delay: 0.5))
        } else {
            steps.append((text: "Getting the basics ready...", delay: 0.5))
        }
        
        // Lifestyle step
        if !context.lifeContext.isEmpty {
            steps.append((text: "Working around your life...", delay: 1.5))
        } else {
            steps.append((text: "Building flexible routines...", delay: 1.5))
        }
        
        // Goals step
        if let weight = context.weight {
            if weight.direction == .lose {
                steps.append((text: "Crafting your weight loss journey...", delay: 2.5))
            } else if weight.direction == .gain {
                steps.append((text: "Planning your gains...", delay: 2.5))
            } else {
                steps.append((text: "Optimizing everything for you...", delay: 2.5))
            }
        } else if !context.functionalGoals.isEmpty {
            steps.append((text: "Making this perfectly yours...", delay: 2.5))
        } else {
            steps.append((text: "Setting up your foundation...", delay: 2.5))
        }
        
        // Communication step
        if !context.communicationStyles.isEmpty {
            let styleCount = context.communicationStyles.count
            steps.append((text: "Mixing your \(styleCount) chosen vibes...", delay: 3.5))
        } else {
            steps.append((text: "Giving your coach personality...", delay: 3.5))
        }
        
        return steps
    }
    
    // Gradients to cycle through during processing
    private let cyclingGradients: [GradientToken] = [
        .sunrise,
        .skyLavender,
        .sproutMint,
        .peachRose,
        .morningGlow,
        .coralMist
    ]
    
    var body: some View {
        ZStack {
            // Custom gradient background that cycles
            currentCyclingGradient
                .ignoresSafeArea(.all)
                .animation(.linear(duration: 0.7), value: gradientCycleProgress)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: AppSpacing.xl) {
                    // Main title
                    if animateIn {
                        CascadeText("Working my magic...")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Processing indicator
                    processingIndicator
                        .padding(.vertical, AppSpacing.xl)
                    
                    // Processing steps
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<processingSteps.count, id: \.self) { index in
                            ProcessingStepView(
                                text: processingSteps[index].text,
                                isActive: currentStep >= index,
                                isComplete: currentStep > index
                            )
                            .opacity(currentStep >= index ? 1 : 0)
                            .offset(y: currentStep >= index ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(processingSteps[index].delay),
                                value: currentStep
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Error state
                    if processingFailed {
                        errorView
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                
                Spacer()
                
                // Bottom area for error recovery
                if processingFailed {
                    VStack(spacing: AppSpacing.md) {
                        Button(action: { retryProcessing() }, label: {
                            Text("Let's try that again")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(gradientManager.currentGradient(for: colorScheme))
                                )
                                .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 6)
                        })
                        
                        Button(action: { continueWithDefaults() }, label: {
                            Text("Skip this for now")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                        })
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startProcessing()
        }
        .accessibilityIdentifier("onboarding.synthesis")
    }
    
    // MARK: - View Components
    
    @ViewBuilder private var processingIndicator: some View {
        ZStack {
            // Background circles
            Circle()
                .fill(gradientManager.active.colors(for: colorScheme)[0].opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(pulsateScale)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: pulsateScale
                )
            
            Circle()
                .fill(gradientManager.active.colors(for: colorScheme)[0].opacity(0.05))
                .frame(width: 160, height: 160)
                .scaleEffect(pulsateScale * 1.2)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(0.3),
                    value: pulsateScale
                )
            
            // Center progress ring
            Circle()
                .trim(from: 0, to: gradientCycleProgress)
                .stroke(
                    gradientManager.currentGradient(for: colorScheme),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 4.0), value: gradientCycleProgress)
            
            // Center icon
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(gradientManager.active.optimalTextColor(for: colorScheme))
                .symbolEffect(.pulse, value: currentStep)
        }
        .onAppear {
            pulsateScale = 1.15
        }
    }
    
    @ViewBuilder private var errorView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.orange)
            
            Text("Hmm, this is taking longer than usual...")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xl)
    }
    
    // MARK: - Computed Properties
    
    private var currentCyclingGradient: LinearGradient {
        let index = Int(gradientCycleProgress * CGFloat(cyclingGradients.count)) % cyclingGradients.count
        let gradientToken = cyclingGradients[index]
        return LinearGradient(
            colors: gradientToken.colors(for: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Methods
    
    private func startProcessing() {
        // Start animations
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animateIn = true
        }
        
        // Start gradient cycling
        withAnimation(.linear(duration: 4.0)) {
            gradientCycleProgress = 1.0
        }
        
        // Progress through steps
        for (index, step) in processingSteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                withAnimation {
                    currentStep = index + 1
                }
                
                // Check if this is the last step
                if index == processingSteps.count - 1 {
                    // Complete processing after last step
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completeProcessing()
                    }
                }
            }
        }
        
        // Set a timeout for error state
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            if !viewModel.isLoading {
                // Already completed, do nothing
                return
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                processingFailed = true
            }
        }
    }
    
    private func completeProcessing() {
        // Check if synthesis actually completed
        if viewModel.synthesizedGoals != nil && viewModel.generatedPersona != nil {
            // Success - navigate to next screen
            viewModel.navigateToNext()
        } else if !processingFailed {
            // Still loading, wait a bit more
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completeProcessing()
            }
        }
    }
    
    private func retryProcessing() {
        // Reset state
        withAnimation {
            processingFailed = false
            currentStep = 0
            gradientCycleProgress = 0
        }
        
        // Restart processing
        startProcessing()
        
        // Actually retry the synthesis
        Task {
            await viewModel.retrySynthesis()
        }
    }
    
    private func continueWithDefaults() {
        // Continue with default persona
        viewModel.continueWithDefaultPersona()
        viewModel.navigateToNext()
    }
}

// MARK: - ProcessingStepView
struct ProcessingStepView: View {
    let text: String
    let isActive: Bool
    let isComplete: Bool
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Status indicator
            ZStack {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(gradientManager.active.accentColor(for: colorScheme))
                } else {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 20, height: 20)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isComplete)
            
            // Step text
            Text(text)
                .font(.system(size: 17, weight: isActive ? .medium : .regular, design: .rounded))
                .foregroundStyle(isActive ? .primary : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isActive)
            
            Spacer()
        }
    }
}

// MARK: - Preview

