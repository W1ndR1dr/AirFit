import SwiftUI

/// Main dashboard view shown after onboarding completion
struct DashboardView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var user: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.large) {
                    // Welcome Header
                    VStack(spacing: AppConstants.Spacing.medium) {
                        Text("Welcome to AirFit!")
                            .font(AppFonts.title)
                            .foregroundColor(AppColors.textPrimary)

                        if let userName = user?.name {
                            Text("Hello, \(userName)")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Text("Your personalized AI coach is ready")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppConstants.Spacing.large)

                    // Quick Stats Card
                    VStack(spacing: AppConstants.Spacing.medium) {
                        HStack {
                            Text("Your Journey")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }

                        HStack(spacing: AppConstants.Spacing.large) {
                            StatCard(
                                title: "Days Active",
                                value: "\(user?.daysActive ?? 0)",
                                color: AppColors.accentColor
                            )

                            StatCard(
                                title: "Profile Complete",
                                value: "✓",
                                color: AppColors.successColor
                            )
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppConstants.CornerRadius.medium)

                    // Coming Soon Section
                    VStack(spacing: AppConstants.Spacing.medium) {
                        Text("Coming Soon")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)

                        VStack(spacing: AppConstants.Spacing.small) {
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress Tracking",
                                description: "Visualize your health journey"
                            )

                            FeatureCard(
                                icon: "brain.head.profile",
                                title: "AI Coach Chat",
                                description: "Get personalized guidance"
                            )

                            FeatureCard(
                                icon: "fork.knife",
                                title: "Meal Logging",
                                description: "Track your nutrition effortlessly"
                            )
                        }
                    }

                    Spacer(minLength: AppConstants.Spacing.large)
                }
                .padding(.horizontal)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await loadUser()
        }
        .accessibilityIdentifier("dashboard.main")
    }

    // MARK: - Private Methods
    private func loadUser() async {
        do {
            let userDescriptor = FetchDescriptor<User>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let users = try modelContext.fetch(userDescriptor)
            user = users.first
        } catch {
            AppLogger.error("Failed to load user in dashboard", error: error, category: .app)
        }
    }
}

// MARK: - Supporting Views
private struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppConstants.Spacing.small) {
            Text(value)
                .font(AppFonts.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppConstants.CornerRadius.small)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppConstants.Spacing.xsmall) {
                Text(title)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.CornerRadius.small)
    }
}

// MARK: - Previews
#Preview {
    DashboardView()
        .modelContainer(try! ModelContainer(.init(for: OnboardingProfile.self)))
}
