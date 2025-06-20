import SwiftUI

// MARK: - WeightObjectivesView
struct WeightObjectivesView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showTargetWeight = false
    @State private var currentWeightText = ""
    @State private var targetWeightText = ""
    @FocusState private var currentWeightFocused: Bool
    @FocusState private var targetWeightFocused: Bool
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
                            CascadeText("Let's chat about your weight")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.xl)
                        }
                        
                        // Current weight section
                        VStack(spacing: AppSpacing.lg) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Current weight")
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.8))
                                
                                HStack(spacing: AppSpacing.md) {
                                    TextField("160", text: $currentWeightText)
                                        .font(.system(size: 48, weight: .light, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .focused($currentWeightFocused)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 150)
                                    
                                    Text("lbs")
                                        .font(.system(size: 24, weight: .light, design: .rounded))
                                        .foregroundStyle(.primary.opacity(0.6))
                                }
                                
                                // HealthKit prefill message
                                if viewModel.currentWeight != nil {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                                        Text("Got this from your Health app")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(.secondary)
                                    }
                                    .opacity(animateIn ? 0.8 : 0)
                                    .animation(.easeIn(duration: 0.4).delay(0.6), value: animateIn)
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateIn)
                            
                            // Transition to target weight
                            if !currentWeightText.isEmpty && !showTargetWeight {
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showTargetWeight = true
                                    }
                                }) {
                                    HStack(spacing: AppSpacing.sm) {
                                        Text("I have a goal in mind")
                                            .font(.system(size: 17, weight: .regular, design: .rounded))
                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 20))
                                    }
                                    .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                                }
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.md)
                            }
                        }
                        
                        // Target weight section
                        if showTargetWeight {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Target weight")
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.8))
                                
                                HStack(spacing: AppSpacing.md) {
                                    TextField("150", text: $targetWeightText)
                                        .font(.system(size: 48, weight: .light, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .focused($targetWeightFocused)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 150)
                                    
                                    Text("lbs")
                                        .font(.system(size: 24, weight: .light, design: .rounded))
                                        .foregroundStyle(.primary.opacity(0.6))
                                }
                                
                                // Smart encouragement
                                if let current = Double(currentWeightText),
                                   let target = Double(targetWeightText),
                                   target < current {
                                    Text("\(Int(current - target)) pounds? Totally doable!")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                                        .padding(.top, AppSpacing.xs)
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
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
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: canContinue)
                    
                    Button(action: { skipWeightGoals() }) {
                        Text("I'm happy where I am")
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
            // Prefill from HealthKit if available
            if let weight = viewModel.currentWeight {
                currentWeightText = String(format: "%.0f", weight)
            } else if let healthWeight = viewModel.healthKitData?.weight {
                // Try to get from health data if not already set
                currentWeightText = String(format: "%.0f", healthWeight)
                viewModel.currentWeight = healthWeight
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
        .onChange(of: currentWeightText) { _, newValue in
            // Update view model
            viewModel.currentWeight = Double(newValue)
        }
        .onChange(of: targetWeightText) { _, newValue in
            // Update view model
            viewModel.targetWeight = Double(newValue)
        }
        .onTapGesture {
            // Dismiss keyboard on tap outside
            currentWeightFocused = false
            targetWeightFocused = false
        }
        .accessibilityIdentifier("onboarding.weightObjectives")
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        !currentWeightText.isEmpty
    }
    
    private var continueButtonText: String {
        if showTargetWeight && !targetWeightText.isEmpty {
            return "Love it, let's keep going"
        } else if !currentWeightText.isEmpty {
            return "Next up"
        } else {
            return "What's your current weight?"
        }
    }
    
    // MARK: - Methods
    
    private func handleContinue() {
        // Dismiss keyboard
        currentWeightFocused = false
        targetWeightFocused = false
        
        // Continue to next screen
        viewModel.navigateToNext()
    }
    
    private func skipWeightGoals() {
        // Clear any entered data
        viewModel.currentWeight = nil
        viewModel.targetWeight = nil
        
        // Continue without weight goals
        viewModel.navigateToNext()
    }
}