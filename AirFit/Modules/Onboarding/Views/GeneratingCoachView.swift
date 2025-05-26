import SwiftUI
import Observation

// MARK: - GeneratingCoachView
struct GeneratingCoachView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var currentStep = 0

    private let steps: [LocalizedStringKey] = [
        "onboarding.generating.step1",
        "onboarding.generating.step2",
        "onboarding.generating.step3",
        "onboarding.generating.step4",
        "onboarding.generating.step5"
    ]

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()

            CircularProgress(progress: Double(currentStep) / Double(steps.count))
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(spacing: AppSpacing.xSmall) {
                        Image(systemName: index < currentStep ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(AppColors.accentColor)
                        Text(steps[index])
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .opacity(index <= currentStep ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .padding(.horizontal, AppSpacing.large)

            Spacer()
        }
        .padding(AppSpacing.large)
        .onAppear(perform: startGeneration)
        .accessibilityIdentifier("onboarding.generatingCoach")
    }

    private func startGeneration() {
        Task {
            for step in 1...steps.count {
                try? await Task.sleep(for: .milliseconds(600))
                await MainActor.run { currentStep = step }
            }

            do {
                try await viewModel.completeOnboarding()
                viewModel.navigateToNextScreen()
            } catch {
                // error is handled inside viewModel
            }
        }
    }
}

// MARK: - CircularProgress
private struct CircularProgress: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.dividerColor, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppColors.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
