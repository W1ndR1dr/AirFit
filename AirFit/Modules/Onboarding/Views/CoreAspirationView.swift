import SwiftUI
import Observation

// MARK: - CoreAspirationView
struct CoreAspirationView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible())]

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Title header
                HStack {
                    Text("Core Aspiration")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, 60)  // Account for status bar + extra space
                .padding(.bottom, AppSpacing.lg)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        // Primary Goal Category Selection
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("What's your primary fitness focus?")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)

                            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                                ForEach(Goal.GoalFamily.allCases, id: \.self) { family in
                                    goalCard(family: family)
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        // Weight Objectives Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Weight Goals")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            weightObjectivesSection()
                        }
                        
                        // Body Recomposition Goals Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Body Composition Goals")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            bodyRecompositionSection()
                        }
                        
                        // Functional Goals Section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Functional & Performance Goals")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            functionalGoalsSection()
                        }
                    }
                }
                .accessibilityIdentifier("onboarding.coreAspiration")

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.navigateToPreviousScreen()
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Button {
                        Task {
                            await viewModel.analyzeGoalText()
                            viewModel.navigateToNextScreen()
                        }
                    } label: {
                        Text("Next")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 40)  // Account for home indicator
            }
        }
    }

    private func goalCard(family: Goal.GoalFamily) -> some View {
        Button {
            HapticService.impact(.light)
            viewModel.goal.family = family
        } label: {
            HStack {
                Text(family.displayName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.goal.family == family {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GlassCard {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        viewModel.goal.family == family
                            ? LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.goal.\(family.rawValue)")
    }
    
    // MARK: - Multi-Goal Sections
    
    @ViewBuilder
    private func weightObjectivesSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Do you have specific weight goals?")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.lg)
            
            // Current Weight Display/Input
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let currentWeight = viewModel.currentWeight {
                    HStack {
                        Text("Current weight: \(currentWeight, format: .number) lbs")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if !viewModel.shouldShowManualWeightInput {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.red)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                } else if viewModel.shouldShowManualWeightInput {
                    Text("Enter your current weight (HealthKit data not available)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                if viewModel.shouldShowManualWeightInput {
                    TextField("Current weight (lbs)", value: $viewModel.manualCurrentWeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                TextField("Target weight (lbs)", value: $viewModel.targetWeight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            if let direction = viewModel.weightDirection {
                HStack {
                    Image(systemName: direction == .gain ? "arrow.up.circle.fill" : direction == .lose ? "arrow.down.circle.fill" : "equal.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Goal: \(direction.displayName)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchCurrentWeightFromHealthKit()
            }
        }
    }
    
    @ViewBuilder
    private func bodyRecompositionSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("What body composition changes are you targeting? (Select all that apply)")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.lg)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(BodyRecompositionGoal.allCases, id: \.self) { bodyGoal in
                    bodyCompositionCard(goal: bodyGoal)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    @ViewBuilder
    private func functionalGoalsSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("What functional or performance goals do you have?")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.lg)
            
            Text("Examples: \"Keep up with my kids\", \"Improve my tennis game\", \"Run a 5K without stopping\"")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppSpacing.lg)
            
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                TextField("Describe your functional goals...", text: $viewModel.goal.functionalGoalsText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityIdentifier("onboarding.functionalGoals.text")

                Button {
                    HapticService.impact(.light)
                    if viewModel.isTranscribing {
                        viewModel.stopVoiceCapture()
                    } else {
                        viewModel.startVoiceCapture()
                    }
                } label: {
                    Image(systemName: viewModel.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.isTranscribing
                                ? LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                }
                .accessibilityIdentifier("onboarding.functionalGoals.voice")
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    @ViewBuilder
    private func bodyCompositionCard(goal: BodyRecompositionGoal) -> some View {
        Button {
            HapticService.impact(.light)
            viewModel.toggleBodyRecompositionGoal(goal)
        } label: {
            HStack {
                Text(goal.displayName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if viewModel.goal.bodyRecompositionGoals.contains(goal) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GlassCard {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        viewModel.goal.bodyRecompositionGoals.contains(goal)
                            ? LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.bodyGoal.\(goal.rawValue)")
    }
}
