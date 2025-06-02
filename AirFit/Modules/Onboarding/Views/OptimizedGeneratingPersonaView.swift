import SwiftUI

/// Optimized loading view with real-time progress - Carmack style
struct OptimizedGeneratingPersonaView: View {
    let coordinator: OnboardingFlowCoordinator
    
    @State private var currentStep = 0
    @State private var stepProgress: [Double] = [0, 0, 0, 0]
    @State private var estimatedTimeRemaining = 5.0
    @State private var startTime = Date()
    
    private let steps = [
        (icon: "brain", title: "Analyzing responses", duration: 0.5),
        (icon: "sparkles", title: "Extracting personality", duration: 1.0),
        (icon: "person.fill.badge.plus", title: "Creating unique identity", duration: 2.0),
        (icon: "text.bubble", title: "Crafting communication style", duration: 1.5)
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Main animation
            ZStack {
                // Background pulse
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.accent.opacity(0.3), .clear]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(1 + 0.1 * sin(Date().timeIntervalSince1970 * 2))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
                
                // Center icon
                Image(systemName: steps[min(currentStep, steps.count - 1)].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)
                    .symbolEffect(.variableColor.iterative.reversing)
            }
            
            // Progress text
            VStack(spacing: 8) {
                Text("Creating Your Coach")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(steps[min(currentStep, steps.count - 1)].title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Time estimate
                if estimatedTimeRemaining > 0 {
                    Text("\(Int(ceil(estimatedTimeRemaining)))s remaining")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            
            // Step progress
            VStack(spacing: 12) {
                ForEach(0..<steps.count, id: \.self) { index in
                    StepProgressRow(
                        icon: steps[index].icon,
                        title: steps[index].title,
                        progress: stepProgress[index],
                        isActive: index == currentStep,
                        isComplete: index < currentStep
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Cancel button (if taking too long)
            if Date().timeIntervalSince(startTime) > 10 {
                Button("Taking longer than expected...") {
                    // Could offer to retry or use cached persona
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear {
            startProgress()
        }
    }
    
    private func startProgress() {
        startTime = Date()
        
        // Simulate realistic progress
        Task {
            for (index, step) in steps.enumerated() {
                currentStep = index
                
                // Animate this step's progress
                await animateStepProgress(index: index, duration: step.duration)
                
                // Update time remaining
                let elapsed = Date().timeIntervalSince(startTime)
                let totalEstimated = steps.map(\.duration).reduce(0, +)
                estimatedTimeRemaining = max(0, totalEstimated - elapsed)
            }
            
            // Small delay before transition
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }
    
    private func animateStepProgress(index: Int, duration: Double) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 1...steps {
            stepProgress[index] = Double(i) / Double(steps)
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
}

struct StepProgressRow: View {
    let icon: String
    let title: String
    let progress: Double
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .stroke(
                        isComplete ? Color.green : (isActive ? Color.accent : Color.secondary.opacity(0.3)),
                        lineWidth: 2
                    )
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(isActive ? .accent : .secondary)
                }
            }
            
            // Title and progress
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isComplete ? .primary : (isActive ? .primary : .secondary))
                
                if isActive && progress > 0 {
                    ProgressView(value: progress)
                        .tint(.accent)
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
            
            Spacer()
            
            // Duration (debug info)
            if isActive {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .opacity(isComplete ? 0.8 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    OptimizedGeneratingPersonaView(
        coordinator: OnboardingFlowCoordinator(
            conversationManager: ConversationFlowManager(),
            personaService: PersonaService(
                personaSynthesizer: PersonaSynthesizer(llmOrchestrator: LLMOrchestrator()),
                llmOrchestrator: LLMOrchestrator(),
                modelContext: DataManager.previewContainer.mainContext
            ),
            userService: MockUserService(),
            modelContext: DataManager.previewContainer.mainContext
        )
    )
}