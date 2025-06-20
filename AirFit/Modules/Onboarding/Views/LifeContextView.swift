import SwiftUI
import Observation

// MARK: - LifeContextView
struct LifeContextView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showVoiceInput = false
    @State private var textOpacity: Double = 0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    // Smart prompts based on HealthKit data
    private var contextPrompt: String {
        let context = viewModel.createContext()
        return context.activityPrompt
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
                
                Spacer()
                
                // Main content
                VStack(spacing: AppSpacing.xl) {
                    // Title with cascade animation
                    if animateIn {
                        CascadeText("What's your day like?")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Smart prompt
                    Text(contextPrompt)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .opacity(textOpacity)
                        .animation(.easeIn(duration: 0.6).delay(0.8), value: textOpacity)
                    
                    // Text input area
                    VStack(spacing: AppSpacing.sm) {
                        ZStack(alignment: .topLeading) {
                            // Placeholder
                            if viewModel.lifeContext.isEmpty {
                                Text("Like: I'm a desk warrior with two kids, or I travel constantly for work...")
                                    .font(.system(size: 20, weight: .regular, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            // Text editor
                            TextEditor(text: $viewModel.lifeContext)
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .frame(minHeight: 150, maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.9)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateIn)
                        
                        // Character count and voice button
                        HStack {
                            Text("\(viewModel.lifeContext.count)/500")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary.opacity(0.6))
                            
                            Spacer()
                            
                            Button(action: { toggleVoiceInput() }) {
                                Image(systemName: showVoiceInput ? "mic.fill" : "mic")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(showVoiceInput ? Color.red : gradientManager.active.accentColor(for: colorScheme))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(1.2), value: animateIn)
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Voice input indicator
                    if showVoiceInput {
                        VStack(spacing: AppSpacing.xs) {
                            Text("Voice input coming soon!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                            
                            Text("For now, please type your response")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                        }
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: AppSpacing.sm) {
                    // Continue button
                    Button(action: { viewModel.navigateToNext() }) {
                        Text("Sounds good, let's keep going")
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
                    .disabled(viewModel.lifeContext.isEmpty)
                    .opacity(viewModel.lifeContext.isEmpty ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.lifeContext.isEmpty)
                    
                    // Skip option
                    Button(action: { 
                        viewModel.lifeContext = "I'll tell you more as we go"
                        viewModel.navigateToNext() 
                    }) {
                        Text("I'll share later")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xl)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.4), value: animateIn)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
            withAnimation {
                textOpacity = 1
            }
        }
        .onChange(of: viewModel.lifeContext) { _, newValue in
            // Limit to 500 characters
            if newValue.count > 500 {
                viewModel.lifeContext = String(newValue.prefix(500))
            }
        }
        .accessibilityIdentifier("onboarding.lifeContext")
    }
    
    private func toggleVoiceInput() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showVoiceInput = true
        }
        
        HapticService.impact(.light)
        
        // Auto-dismiss the message after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showVoiceInput = false
            }
        }
    }
}