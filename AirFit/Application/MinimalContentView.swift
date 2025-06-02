import SwiftUI
import SwiftData

/// Minimal ContentView for Module 3 (Onboarding) testing
struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var showOnboarding = true

    var body: some View {
        VStack {
            if showOnboarding {
                if let aiService = DependencyContainer.shared.aiService {
                    OnboardingFlowView(
                        aiService: aiService,
                        onboardingService: OnboardingService(modelContext: modelContext),
                        onCompletion: {
                            showOnboarding = false
                        }
                    )
                } else {
                    Text("AI Service not configured")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.errorColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.backgroundPrimary)
                }
            } else {
                VStack(spacing: AppSpacing.large) {
                    Text("Onboarding Complete!")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Module 3 testing successful")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)

                    Button("Restart Onboarding") {
                        showOnboarding = true
                    }
                    .font(AppFonts.bodyBold)
                    .foregroundColor(AppColors.textOnAccent)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
                .padding(AppSpacing.large)
            }
        }
        .background(AppColors.backgroundPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: OnboardingProfile.self)
}
