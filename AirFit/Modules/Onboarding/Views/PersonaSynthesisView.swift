import SwiftUI

struct PersonaSynthesisView: View {
    @StateObject private var previewGenerator: PreviewGenerator
    @State private var animateElements = false
    @State private var pulseAnimation = false
    
    let insights: PersonalityInsights
    let conversationData: ConversationData
    let onCompletion: (PersonaProfile) -> Void
    
    init(
        synthesizer: PersonaSynthesizer,
        insights: PersonalityInsights,
        conversationData: ConversationData,
        onCompletion: @escaping (PersonaProfile) -> Void
    ) {
        self._previewGenerator = StateObject(wrappedValue: PreviewGenerator(synthesizer: synthesizer))
        self.insights = insights
        self.conversationData = conversationData
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Progress indicator
                SynthesisProgressView(
                    stage: previewGenerator.currentStage,
                    progress: previewGenerator.progress
                )
                .padding(.top, 40)
                
                // Main content
                VStack(spacing: 24) {
                    // Stage text
                    Text(previewGenerator.currentStage.displayText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .id(previewGenerator.currentStage.displayText)
                    
                    // Preview card
                    if let preview = previewGenerator.preview {
                        PersonaPreviewCard(preview: preview)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 1.1).combined(with: .opacity)
                            ))
                    }
                    
                    // Loading animation
                    if previewGenerator.currentStage.isActive {
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                        value: pulseAnimation
                                    )
                            }
                        }
                        .onAppear {
                            pulseAnimation = true
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if case .complete(let persona) = previewGenerator.currentStage {
                        Button(action: { onCompletion(persona) }) {
                            HStack {
                                Text("Meet Your Coach")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if case .failed = previewGenerator.currentStage {
                        Button(action: retry) {
                            Text("Try Again")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            startSynthesis()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: previewGenerator.currentStage)
        .animation(.spring(response: 0.3), value: animateElements)
    }
    
    private func startSynthesis() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateElements = true
            }
            
            previewGenerator.startSynthesis(
                insights: insights,
                conversationData: conversationData
            )
        }
    }
    
    private func retry() {
        previewGenerator.startSynthesis(
            insights: insights,
            conversationData: conversationData
        )
    }
}

// MARK: - Progress View

struct SynthesisProgressView: View {
    let stage: SynthesisStage
    let progress: Double
    
    private let stages: [(SynthesisStage, String, String)] = [
        (.analyzingPersonality, "brain.head.profile", "Analyze"),
        (.creatingIdentity, "person.fill.badge.plus", "Create"),
        (.buildingPersonality, "sparkles", "Build"),
        (.finalizing, "checkmark.seal", "Finalize")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stageInfo in
                StageIndicator(
                    icon: stageInfo.1,
                    label: stageInfo.2,
                    isActive: isStageActive(stageInfo.0),
                    isCompleted: isStageCompleted(stageInfo.0)
                )
                
                if index < stages.count - 1 {
                    ProgressConnector(
                        progress: connectorProgress(for: index)
                    )
                }
            }
        }
        .padding(.horizontal, 32)
    }
    
    private func isStageActive(_ checkStage: SynthesisStage) -> Bool {
        switch (stage, checkStage) {
        case (.analyzingPersonality, .analyzingPersonality),
             (.creatingIdentity, .creatingIdentity),
             (.buildingPersonality, .buildingPersonality),
             (.finalizing, .finalizing):
            return true
        default:
            return false
        }
    }
    
    private func isStageCompleted(_ checkStage: SynthesisStage) -> Bool {
        let stageOrder: [SynthesisStage] = [
            .analyzingPersonality,
            .creatingIdentity,
            .buildingPersonality,
            .finalizing
        ]
        
        guard let currentIndex = stageOrder.firstIndex(where: { isStageActive($0) }),
              let checkIndex = stageOrder.firstIndex(where: { 
                  switch ($0, checkStage) {
                  case (.analyzingPersonality, .analyzingPersonality),
                       (.creatingIdentity, .creatingIdentity),
                       (.buildingPersonality, .buildingPersonality),
                       (.finalizing, .finalizing):
                      return true
                  default:
                      return false
                  }
              }) else {
            // If we can't find the stage indices, check if we're complete
            if case .complete = stage {
                return true
            }
            return false
        }
        
        // Check if we've passed this stage or if we're complete
        if checkIndex < currentIndex {
            return true
        }
        
        if case .complete = stage {
            return true
        }
        
        return false
    }
    
    private func connectorProgress(for index: Int) -> Double {
        let stageProgress = progress * 4 // 4 stages
        let connectorStart = Double(index)
        let connectorEnd = Double(index + 1)
        
        if stageProgress <= connectorStart {
            return 0
        } else if stageProgress >= connectorEnd {
            return 1
        } else {
            return stageProgress - connectorStart
        }
    }
}

struct StageIndicator: View {
    let icon: String
    let label: String
    let isActive: Bool
    let isCompleted: Bool
    
    private var iconColor: Color {
        if isActive { return .white }
        else if isCompleted { return .white }
        else { return Color(.systemGray3) }
    }
    
    private var backgroundColor: Color {
        if isActive { return .accentColor }
        else if isCompleted { return .green }
        else { return Color(.systemGray5) }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(isActive || isCompleted ? .primary : .secondary)
        }
        .animation(.spring(response: 0.3), value: isActive)
        .animation(.spring(response: 0.3), value: isCompleted)
    }
}

struct ProgressConnector: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 2)
                
                // Progress
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.linear(duration: 0.3), value: progress)
            }
        }
        .frame(height: 2)
        .frame(maxWidth: .infinity)
    }
}