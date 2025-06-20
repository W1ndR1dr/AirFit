import SwiftUI

// MARK: - BodyCompositionGoalsView
struct BodyCompositionGoalsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showGoals = false
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
                            CascadeText("Any body transformation goals?")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.xl)
                        }
                        
                        // Subtitle
                        if showGoals {
                            Text(subtitleText)
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
                                        action: { viewModel.toggleBodyRecompositionGoal(goal) }
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
            
            // Apply smart defaults if no goals selected yet
            applySmartDefaults()
        }
        .accessibilityIdentifier("onboarding.bodyComposition")
    }
    
    // MARK: - Computed Properties
    
    private var subtitleText: String {
        let context = viewModel.createContext()
        
        // Check if we pre-selected some goals
        if !viewModel.bodyRecompositionGoals.isEmpty {
            if let weight = context.weight, weight.direction == .lose {
                return "Picked a few based on your weight goals - feel free to change!"
            } else if let metrics = context.healthData?.activityMetrics, 
                     (metrics.averageDailySteps > 10000 || metrics.weeklyWorkoutCount >= 4) {
                return "You're pretty active - thought these might appeal to you"
            }
        }
        
        // Default friendly prompt
        return "Choose what excites you (or none at all!)"
    }
    
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
    
    private func applySmartDefaults() {
        // Only apply defaults if nothing selected yet
        guard viewModel.bodyRecompositionGoals.isEmpty else { return }
        
        let context = viewModel.createContext()
        
        // Weight loss goal suggests fat loss
        if let weight = context.weight, weight.direction == .lose {
            if !viewModel.bodyRecompositionGoals.contains(.loseFat) {
                viewModel.bodyRecompositionGoals.append(.loseFat)
            }
            
            // If moderate weight loss, also suggest toning
            if let current = weight.currentWeight, 
               let target = weight.targetWeight,
               current - target <= 20 {
                if !viewModel.bodyRecompositionGoals.contains(.getToned) {
                    viewModel.bodyRecompositionGoals.append(.getToned)
                }
            }
        }
        
        // Weight gain suggests muscle building
        if let weight = context.weight, weight.direction == .gain {
            if !viewModel.bodyRecompositionGoals.contains(.gainMuscle) {
                viewModel.bodyRecompositionGoals.append(.gainMuscle)
            }
        }
        
        // Active users might want definition
        if let metrics = context.healthData?.activityMetrics,
           (metrics.averageDailySteps > 10000 || metrics.weeklyWorkoutCount >= 4) {
            if !viewModel.bodyRecompositionGoals.contains(.improveDefinition) {
                viewModel.bodyRecompositionGoals.append(.improveDefinition)
            }
        }
        
        // Add haptic feedback if we selected anything
        if !viewModel.bodyRecompositionGoals.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                HapticService.impact(.light)
            }
        }
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