import SwiftUI

// MARK: - CommunicationStyleView
struct CommunicationStyleView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false
    @State private var showInformationPreferences = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    
    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { viewModel.navigateToPrevious() }, label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundStyle(gradientManager.active.optimalTextColor(for: colorScheme))
                    })
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Title with cascade animation
                        if animateIn {
                            CascadeText("How do you like to be coached?")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.xl)
                        }
                        
                        // Subtitle
                        if animateIn {
                            Text("I can adapt - pick what resonates")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(gradientManager.active.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .opacity(animateIn ? 1 : 0)
                                .animation(.easeInOut(duration: 0.4).delay(0.8), value: animateIn)
                        }
                        
                        // Communication styles
                        if !showInformationPreferences {
                            communicationStylesList
                        }
                        
                        // Information preferences
                        if showInformationPreferences {
                            informationPreferencesList
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom button
                VStack(spacing: AppSpacing.sm) {
                    Button(action: { handleContinue() }, label: {
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
                    })
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: canContinue)
                    
                    // Skip option
                    if !showInformationPreferences && viewModel.communicationStyles.isEmpty {
                        Button(action: { skipToNext() }, label: {
                            Text("Surprise me - adapt as we go")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(gradientManager.active.accentColor(for: colorScheme))
                        })
                        .opacity(animateIn ? 0.7 : 0)
                        .animation(.easeInOut(duration: 0.4).delay(1.2), value: animateIn)
                    }
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
            applySmartDefaults()
        }
        .accessibilityIdentifier("onboarding.communicationStyle")
    }
    
    // MARK: - View Components
    
    @ViewBuilder private var communicationStylesList: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(CommunicationStyle.allCases, id: \.self) { style in
                CommunicationStyleRow(
                    style: style,
                    isSelected: viewModel.communicationStyles.contains(style),
                    action: { viewModel.toggleCommunicationStyle(style) }
                )
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1 : 0.9)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(CommunicationStyle.allCases.firstIndex(of: style)!) * 0.05 + 0.6),
                    value: animateIn
                )
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    @ViewBuilder private var informationPreferencesList: some View {
        VStack(spacing: AppSpacing.md) {
            // Section header
            Text("What information helps you most?")
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, AppSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            
            ForEach(InformationStyle.allCases, id: \.self) { style in
                InformationStyleRow(
                    style: style,
                    isSelected: viewModel.informationPreferences.contains(style),
                    action: { viewModel.toggleInformationPreference(style) }
                )
                .transition(.opacity.combined(with: .scale))
                .opacity(showInformationPreferences ? 1 : 0)
                .scaleEffect(showInformationPreferences ? 1 : 0.9)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(InformationStyle.allCases.firstIndex(of: style)!) * 0.05),
                    value: showInformationPreferences
                )
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        if showInformationPreferences {
            return !viewModel.informationPreferences.isEmpty
        } else {
            return !viewModel.communicationStyles.isEmpty
        }
    }
    
    private var continueButtonText: String {
        if showInformationPreferences {
            let count = viewModel.informationPreferences.count
            return !viewModel.informationPreferences.isEmpty ? "Continue with \(count) preference\(count == 1 ? "" : "s")" : "Continue"
        } else {
            let count = viewModel.communicationStyles.count
            return !viewModel.communicationStyles.isEmpty ? "Continue with \(count) style\(count == 1 ? "" : "s")" : "Continue"
        }
    }
    
    // MARK: - Methods
    
    private func handleContinue() {
        if !showInformationPreferences {
            // Move to information preferences
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showInformationPreferences = true
            }
        } else {
            // Move to next screen
            viewModel.navigateToNext()
        }
    }
    
    private func skipToNext() {
        // Set default preferences if skipping
        viewModel.communicationStyles = [.encouraging, .patient]
        viewModel.informationPreferences = [.keyMetrics, .celebrations]
        viewModel.navigateToNext()
    }
    
    private func applySmartDefaults() {
        // Apply smart defaults based on goals
        guard viewModel.communicationStyles.isEmpty else { return }
        
        let goalsText = viewModel.functionalGoalsText.lowercased()
        
        // Weight loss goals often benefit from encouragement and patience
        if goalsText.contains("weight") || goalsText.contains("lose") {
            viewModel.communicationStyles = [.encouraging, .patient]
        }
        // Performance goals might prefer direct and data-driven
        else if goalsText.contains("performance") || goalsText.contains("strength") {
            viewModel.communicationStyles = [.direct, .analytical]
        }
        // General fitness might like balanced approach
        else if !goalsText.isEmpty {
            viewModel.communicationStyles = [.encouraging]
        }
    }
}

// MARK: - CommunicationStyleRow
struct CommunicationStyleRow: View {
    let style: CommunicationStyle
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                checkboxView
                contentView
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(backgroundView)
            .overlay(overlayView)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder private var checkboxView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(checkboxFillColor)
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(checkboxBorderColor, lineWidth: 2)
                )
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    @ViewBuilder private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(style.displayName)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(style.description)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.8))
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundFillColor)
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(overlayBorderColor, lineWidth: 1)
    }
    
    // Computed colors
    private var checkboxFillColor: Color {
        isSelected ? gradientManager.active.colors(for: colorScheme)[0] : Color.clear
    }
    
    private var checkboxBorderColor: Color {
        isSelected ? Color.clear : Color.primary.opacity(0.3)
    }
    
    private var backgroundFillColor: Color {
        isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.1) : Color.clear
    }
    
    private var overlayBorderColor: Color {
        isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.3) : Color.clear
    }
}

// MARK: - InformationStyleRow
struct InformationStyleRow: View {
    let style: InformationStyle
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                checkboxView
                
                Text(style.displayName)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(backgroundView)
            .overlay(overlayView)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder private var checkboxView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(checkboxFillColor)
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(checkboxBorderColor, lineWidth: 2)
                )
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundFillColor)
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(overlayBorderColor, lineWidth: 1)
    }
    
    // Computed colors
    private var checkboxFillColor: Color {
        isSelected ? gradientManager.active.colors(for: colorScheme)[0] : Color.clear
    }
    
    private var checkboxBorderColor: Color {
        isSelected ? Color.clear : Color.primary.opacity(0.3)
    }
    
    private var backgroundFillColor: Color {
        isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.1) : Color.clear
    }
    
    private var overlayBorderColor: Color {
        isSelected ? gradientManager.active.accentColor(for: colorScheme).opacity(0.3) : Color.clear
    }
}
