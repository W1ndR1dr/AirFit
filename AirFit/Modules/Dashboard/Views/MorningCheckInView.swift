import SwiftUI

/// Low-friction morning check-in for subjective feeling + recovery score display
struct MorningCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    
    @State private var subjectiveRating: Double = 5.0
    @State private var isAnalyzing = false
    @State private var recoveryOutput: RecoveryInference.Output?
    @State private var error: Error?
    
    private let contextAssembler: ContextAssemblerProtocol
    private let healthKitManager: HealthKitManaging
    
    init(contextAssembler: ContextAssemblerProtocol, healthKitManager: HealthKitManaging) {
        self.contextAssembler = contextAssembler
        self.healthKitManager = healthKitManager
    }
    
    var body: some View {
        BaseScreen {
            if let output = recoveryOutput {
                // Results view
                recoveryResultsView(output)
            } else {
                // Check-in view
                checkInView
            }
        }
        .animation(.smooth(duration: 0.3), value: recoveryOutput != nil)
    }
    
    private var checkInView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: AppSpacing.md) {
                Text("Good morning")
                    .font(.largeTitle)
                    .fontWeight(.light)
                
                Text("How are you feeling today?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            
            // Rating slider
            VStack(spacing: AppSpacing.lg) {
                HStack {
                    Text("😴")
                        .font(.title)
                    
                    Slider(value: $subjectiveRating, in: 1...10, step: 1)
                        .tint(Color.accentColor)
                    
                    Text("💪")
                        .font(.title)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Text("\(Int(subjectiveRating))")
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundStyle(colorForRating(subjectiveRating))
            }
            .padding(.vertical, AppSpacing.xl)
            
            Spacer()
            
            // Actions
            VStack(spacing: AppSpacing.md) {
                Button(action: { analyzeRecovery(skipRating: false) }) {
                    HStack {
                        if isAnalyzing {
                            TextLoadingView(message: "Analyzing recovery", style: .subtle)
                        } else {
                            Text("Analyze Recovery")
                        }
                    }
                }
                .buttonStyle(.softPrimary)
                .disabled(isAnalyzing)
                
                Button("Skip for now") {
                    // Analyze without subjective rating
                    Task {
                        analyzeRecovery(skipRating: true)
                    }
                }
                .buttonStyle(.softSecondary)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }
    
    private func recoveryResultsView(_ output: RecoveryInference.Output) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: gradientForStatus(output.recoveryStatus),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: AppSpacing.xs) {
                        Text("\(Int(output.readinessScore))")
                            .font(.system(size: 72, weight: .light, design: .rounded))
                        
                        Text(output.recoveryStatus.rawValue)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, AppSpacing.xl)
                
                // Training recommendation
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Label("Today's Training", systemImage: "figure.run")
                            .font(.headline)
                        
                        Text(output.trainingRecommendation.rawValue)
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text(output.trainingRecommendation.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Limiting factors (if any)
                if !output.limitingFactors.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("Recovery Factors", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                            
                            ForEach(output.limitingFactors, id: \.self) { factor in
                                HStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(factor)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
                
                // Confidence indicator
                if output.confidence < 0.8 {
                    Text("Limited data available (\(Int(output.confidence * 100))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Done button
                Button("Got it") {
                    dismiss()
                }
                .buttonStyle(.softPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.xl)
        }
    }
    
    private func analyzeRecovery(skipRating: Bool = false) {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            do {
                // Get current health context
                let context = await contextAssembler.assembleContext()
                
                // Prepare recovery input
                let adapter = RecoveryDataAdapter(healthKitManager: healthKitManager)
                let input = try await adapter.prepareRecoveryInput(
                    currentSnapshot: context,
                    subjectiveRating: skipRating ? nil : subjectiveRating
                )
                
                // Analyze recovery
                let inference = RecoveryInference()
                let output = await inference.analyzeRecovery(input: input)
                
                withAnimation {
                    recoveryOutput = output
                }
                
            } catch {
                self.error = error
                AppLogger.error("Failed to analyze recovery", error: error, category: .health)
            }
        }
    }
    
    private func colorForRating(_ rating: Double) -> Color {
        switch rating {
        case 8...:
            return .green
        case 5..<8:
            return .blue
        case 3..<5:
            return .orange
        default:
            return .red
        }
    }
    
    private func gradientForStatus(_ status: RecoveryInference.RecoveryStatus) -> [Color] {
        switch status {
        case .fullyRecovered:
            return [.green, .mint]
        case .adequate:
            return [.blue, .cyan]
        case .compromised:
            return [.orange, .yellow]
        case .needsRest:
            return [.red, .orange]
        }
    }
}

// MARK: - Preview
// #Preview {
//     MorningCheckInView(
//         contextAssembler: MockContextAssembler(),
//         healthKitManager: MockHealthKitManager()
//     )
//     .environmentObject(GradientManager())
// }
