import SwiftUI

struct OnboardingStateView: View {
    let state: OnboardingState
    let progress: OnboardingProgress
    let onAction: (OnboardingAction) -> Void
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Main content
            VStack {
                // Progress indicator
                if shouldShowProgress {
                    OnboardingProgressBar(progress: progress)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // State-specific content
                stateContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: state)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var backgroundColors: [Color] {
        switch state {
        case .error:
            return [Color.red.opacity(0.1), Color.red.opacity(0.05)]
        case .completed:
            return [Color.green.opacity(0.1), Color.green.opacity(0.05)]
        default:
            return [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)]
        }
    }
    
    private var shouldShowProgress: Bool {
        switch state {
        case .conversationInProgress, .synthesizingPersona:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private var stateContent: some View {
        switch state {
        case .notStarted:
            EmptyView()
            
        case .conversationInProgress:
            ConversationInProgressView(
                progress: progress,
                onPause: { onAction(.pause) }
            )
            
        case .synthesizingPersona:
            SynthesizingView(progress: progress)
            
        case .reviewingPersona(let persona):
            ReviewingPersonaView(
                persona: persona,
                onAccept: { onAction(.accept) },
                onAdjust: { onAction(.adjust($0)) }
            )
            
        case .adjustingPersona(let persona):
            AdjustingPersonaView(persona: persona)
            
        case .saving:
            SavingView()
            
        case .completed:
            CompletedView(onContinue: { onAction(.continue) })
            
        case .paused:
            PausedStateView(
                onResume: { onAction(.resume) },
                onRestart: { onAction(.restart) }
            )
            
        case .cancelled:
            CancelledStateView(
                onRestart: { onAction(.restart) },
                onExit: { onAction(.exit) }
            )
            
        case .error(let error):
            ErrorStateView(
                error: error,
                onRetry: { onAction(.retry) },
                onExit: { onAction(.exit) }
            )
        }
    }
}

// MARK: - Supporting Types

enum OnboardingAction {
    case pause
    case resume
    case accept
    case adjust(PersonaAdjustments)
    case `continue`
    case restart
    case retry
    case exit
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let progress: OnboardingProgress
    
    private var displayProgress: Double {
        if progress.synthesisComplete {
            return 1.0
        } else if progress.synthesisStarted {
            return 0.7 + (progress.completionPercentage * 0.3)
        } else {
            return progress.completionPercentage * 0.7
        }
    }
    
    private var progressText: String {
        if let timeRemaining = progress.estimatedTimeRemaining {
            let minutes = Int(timeRemaining / 60)
            let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d remaining", minutes, seconds)
        }
        return "\(Int(displayProgress * 100))% complete"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * displayProgress, height: 8)
                        .animation(.spring(response: 0.5), value: displayProgress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - State-Specific Views

struct ConversationInProgressView: View {
    let progress: OnboardingProgress
    let onPause: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated conversation bubbles
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.2)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: true
                        )
                }
            }
            
            Text("Question \(progress.nodesCompleted + 1) of \(progress.totalNodes)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: onPause) {
                Label("Pause", systemImage: "pause.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom)
        }
    }
}

struct SynthesizingView: View {
    let progress: OnboardingProgress
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.3),
                                    Color.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(
                            width: 100 + CGFloat(index * 30),
                            height: 100 + CGFloat(index * 30)
                        )
                        .rotationEffect(.degrees(rotation + Double(index * 120)))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            VStack(spacing: 8) {
                Text("Creating Your Coach")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This will take just a moment...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ReviewingPersonaView: View {
    let persona: PersonaProfile
    let onAccept: () -> Void
    let onAdjust: (PersonaAdjustments) -> Void
    @State private var showAdjustments = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Coach card
                PersonaCard(persona: persona)
                    .padding(.horizontal)
                
                // Sample interaction
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    MessageBubble(
                        text: "\(persona.interactionStyle.greetingStyle) Ready to crush your workout today?",
                        isFromCoach: true
                    )
                }
                .padding(.horizontal)
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: onAccept) {
                        Text("I Love It!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { showAdjustments = true }) {
                        Text("Make Adjustments")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showAdjustments) {
            PersonaAdjustmentSheet(
                currentPersona: persona,
                onSave: { adjustments in
                    showAdjustments = false
                    onAdjust(adjustments)
                }
            )
        }
    }
}

struct PersonaCard: View {
    let persona: PersonaProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Text(String(persona.name.prefix(2)).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 8) {
                Text(persona.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(persona.archetype)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Traits
            HStack(spacing: 8) {
                ForEach(persona.metadata.sourceInsights.dominantTraits.prefix(3), id: \.self) { trait in
                    TraitBadge(trait: trait)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

struct TraitBadge: View {
    let trait: String
    
    var body: some View {
        Text(trait.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
    }
}

struct MessageBubble: View {
    let text: String
    let isFromCoach: Bool
    
    var body: some View {
        HStack {
            if !isFromCoach { Spacer() }
            
            Text(text)
                .font(.body)
                .foregroundColor(isFromCoach ? .primary : .white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isFromCoach ? Color(.systemGray6) : Color.accentColor)
                )
            
            if isFromCoach { Spacer() }
        }
    }
}

struct PersonaAdjustmentSheet: View {
    let currentPersona: PersonaProfile
    let onSave: (PersonaAdjustments) -> Void
    
    @State private var selectedType: PersonaAdjustments.AdjustmentType = .tone
    @State private var adjustmentValue: Double = 0
    @State private var feedback: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Adjustment type picker
                Picker("Adjustment Type", selection: $selectedType) {
                    ForEach([
                        PersonaAdjustments.AdjustmentType.tone,
                        .energy,
                        .formality,
                        .humor,
                        .supportiveness
                    ], id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Adjustment slider
                VStack(alignment: .leading, spacing: 8) {
                    Text(adjustmentDescription)
                        .font(.headline)
                    
                    HStack {
                        Text(sliderMinLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $adjustmentValue, in: -1...1)
                            .accentColor(.accentColor)
                        
                        Text(sliderMaxLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Feedback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Feedback (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $feedback)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Adjust Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let adjustments = PersonaAdjustments(
                            type: selectedType,
                            value: adjustmentValue,
                            feedback: feedback.isEmpty ? nil : feedback
                        )
                        onSave(adjustments)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var adjustmentDescription: String {
        switch selectedType {
        case .tone:
            return "Adjust Communication Tone"
        case .energy:
            return "Adjust Energy Level"
        case .formality:
            return "Adjust Formality"
        case .humor:
            return "Adjust Humor Level"
        case .supportiveness:
            return "Adjust Supportiveness"
        }
    }
    
    private var sliderMinLabel: String {
        switch selectedType {
        case .tone: return "Softer"
        case .energy: return "Calmer"
        case .formality: return "Casual"
        case .humor: return "Serious"
        case .supportiveness: return "Direct"
        }
    }
    
    private var sliderMaxLabel: String {
        switch selectedType {
        case .tone: return "Stronger"
        case .energy: return "Intense"
        case .formality: return "Formal"
        case .humor: return "Playful"
        case .supportiveness: return "Nurturing"
        }
    }
}

struct AdjustingPersonaView: View {
    let persona: PersonaProfile
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("Adjusting \(persona.name)...")
                .font(.headline)
            
            Text("Making your coach perfect for you")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct SavingView: View {
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.accentColor)
                    .scaleEffect(checkmarkScale)
            }
            
            Text("Saving Your Coach")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.5)) {
                checkmarkScale = 1.0
            }
        }
    }
}

struct CompletedView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .symbolEffect(.bounce)
            
            VStack(spacing: 16) {
                Text("Welcome to AirFit!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personalized AI coach is ready to help you achieve amazing results.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Let's Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct PausedStateView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Taking a Break")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your progress is saved. Come back anytime!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Button(action: onResume) {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onRestart) {
                    Text("Start Fresh")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CancelledStateView: View {
    let onRestart: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Setup Cancelled")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button(action: onRestart) {
                    Text("Start Over")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onExit) {
                    Text("Exit Setup")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ErrorStateView: View {
    let error: OnboardingOrchestratorError
    let onRetry: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 16) {
                Text("Oops!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onExit) {
                    Text("Exit Setup")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}