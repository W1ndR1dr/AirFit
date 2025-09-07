import SwiftUI
import Charts

/// Detailed nutrition analytics view accessible from Today dashboard
struct NutritionDetailView: View {
    let user: User
    @State private var selectedTimeframe: TimeframeOption = .week
    @State private var animateIn = false

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(NavigationState.self) private var navigationState

    enum TimeframeOption: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.md)

                    // Timeframe picker
                    DashboardTimeframePicker(selection: $selectedTimeframe)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.lg)

                    // Content sections
                    DashboardContentView(delay: 0.1) {
                        macroTrendsSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.2) {
                        calorieTrendsSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.3) {
                        nutritionInsightsSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.4) {
                        quickActionsSection
                    }
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Nutrition Analytics")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)

            Text("Deep dive into your nutrition patterns")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Macro Trends

    @ViewBuilder
    private var macroTrendsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Macro Trends")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Macro distribution chart
                    Chart {
                        ForEach(mockMacroData) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Amount", data.protein),
                                width: .ratio(0.3)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .position(by: .value("Type", "Protein"))

                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Amount", data.carbs),
                                width: .ratio(0.3)
                            )
                            .foregroundStyle(Color.orange.gradient)
                            .position(by: .value("Type", "Carbs"))

                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Amount", data.fat),
                                width: .ratio(0.3)
                            )
                            .foregroundStyle(Color.green.gradient)
                            .position(by: .value("Type", "Fat"))
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }

                    // Average macros
                    HStack(spacing: AppSpacing.lg) {
                        macroAverageItem(title: "Protein", value: "142g", color: .blue)
                        macroAverageItem(title: "Carbs", value: "245g", color: .orange)
                        macroAverageItem(title: "Fat", value: "68g", color: .green)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func macroAverageItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Circle()
                .fill(color.gradient)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calorie Trends

    @ViewBuilder
    private var calorieTrendsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Calorie Trends")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Calorie chart
                    Chart {
                        ForEach(mockCalorieData) { data in
                            LineMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Calories", data.calories)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                            AreaMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Calories", data.calories)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.2) },
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }

                        // Target line
                        RuleMark(y: .value("Target", 2_200))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    .frame(height: 200)

                    // Stats
                    HStack(spacing: AppSpacing.xl) {
                        statItem(title: "Average", value: "2,245", subtitle: "cal/day")
                        statItem(title: "Consistency", value: "82%", subtitle: "on target")
                        statItem(title: "Trend", value: "-3%", subtitle: "vs last period", isPositive: true)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Nutrition Insights

    @ViewBuilder
    private var nutritionInsightsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "AI Insights")

            VStack(spacing: AppSpacing.md) {
                insightCard(
                    icon: "lightbulb.fill",
                    title: "Protein Timing",
                    message: "Your protein intake is well-distributed throughout the day. Keep it up!",
                    color: .blue
                )

                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekend Pattern",
                    message: "Calories tend to spike on weekends. Consider planning ahead.",
                    color: .orange
                )

                insightCard(
                    icon: "leaf.fill",
                    title: "Micronutrients",
                    message: "Great fiber intake! You're consistently hitting 25g+ daily.",
                    color: .green
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func insightCard(icon: String, title: String, message: String, color: Color) -> some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color.gradient)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Quick Actions")

            HStack(spacing: AppSpacing.md) {
                actionButton(
                    icon: "camera.fill",
                    title: "Log Meal",
                    action: { navigationState.navigateToTab(.nutrition) }
                )

                actionButton(
                    icon: "chart.bar.fill",
                    title: "View Reports",
                    action: { }
                )

                actionButton(
                    icon: "target",
                    title: "Update Goals",
                    action: { }
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .glassEffect(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func statItem(title: String, value: String, subtitle: String, isPositive: Bool = false) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(isPositive ? .green : .secondary)
        }
    }
}

// MARK: - Mock Data

private struct NutritionMacroData: Identifiable {
    let id = UUID()
    let date: Date
    let protein: Int
    let carbs: Int
    let fat: Int
}

private struct CalorieData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

private let mockMacroData: [NutritionMacroData] = {
    let calendar = Calendar.current
    let today = Date()

    return (0..<7).compactMap { dayOffset in
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
        return NutritionMacroData(
            date: date,
            protein: Int.random(in: 120...160),
            carbs: Int.random(in: 200...280),
            fat: Int.random(in: 50...80)
        )
    }
}()

private let mockCalorieData: [CalorieData] = {
    let calendar = Calendar.current
    let today = Date()

    return (0..<30).compactMap { dayOffset in
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
        let baseCalories = 2_200
        let variation = Int.random(in: -300...300)
        return CalorieData(date: date, calories: baseCalories + variation)
    }
}()
