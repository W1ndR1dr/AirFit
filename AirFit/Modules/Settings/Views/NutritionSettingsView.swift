import SwiftUI

/// Settings view for adjusting personalized nutrition macros
struct NutritionSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var proteinPerPound: Double
    @State private var fatPercentage: Double
    @State private var macroFlexibility: String
    @State private var showingResetAlert = false
    @State private var hasChanges = false
    @State private var adaptiveEnabled: Bool = UserDefaults.standard.bool(forKey: "AirFit.AdaptiveNutritionEnabled")
    @State private var adjustments: [DailyNutritionAdjustment] = []

    let user: User
    private let originalProtein: Double
    private let originalFat: Double
    private let originalFlexibility: String

    init(user: User) {
        self.user = user
        self.originalProtein = user.proteinGramsPerPound
        self.originalFat = user.fatPercentage
        self.originalFlexibility = user.macroFlexibility

        self._proteinPerPound = State(initialValue: user.proteinGramsPerPound)
        self._fatPercentage = State(initialValue: user.fatPercentage * 100) // Convert to percentage
        self._macroFlexibility = State(initialValue: user.macroFlexibility)
    }

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        CascadeText("Nutrition Targets")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Customize your macro targets based on your goals")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)

                    // Current Approach
                    if let recommendations = getCurrentRecommendations() {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Label("AI Recommendation", systemImage: "sparkles")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)

                                Text(recommendations.approach)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))

                                Text(recommendations.rationale)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Adaptive Goals Toggle
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Adaptive Goals")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text("Automatically adjusts daily targets based on activity and recent intake")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $adaptiveEnabled)
                                .labelsHidden()
                                .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                                .onChange(of: adaptiveEnabled) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "AirFit.AdaptiveNutritionEnabled")
                                    HapticService.play(.dataUpdated)
                                }
                        }
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Recent Adjustments
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Recent Adjustments")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary.opacity(0.8))
                                Spacer()
                            }
                            if adjustments.isEmpty {
                                Text("No adjustments recorded yet.")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(adjustments.prefix(7), id: \.id) { adj in
                                    HStack(spacing: AppSpacing.sm) {
                                        let pct = adj.percent
                                        Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(pct >= 0 ? .green : .orange)
                                        Text("\(formattedDate(adj.date))")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "%+.0f%%", pct * 100))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        Spacer()
                                        if let r = adj.rationale, !r.isEmpty {
                                            Text(r)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    if adj.id != adjustments.prefix(7).last?.id { Divider() }
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Protein Settings
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Protein Target")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg + AppSpacing.xs)

                        GlassCard {
                            VStack(spacing: AppSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(String(format: "%.1f", proteinPerPound)) g/lb")
                                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        Text(proteinDescription)
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: proteinIcon)
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                Slider(value: $proteinPerPound, in: 0.6...1.5, step: 0.1)
                                    .tint(.blue)
                                    .onChange(of: proteinPerPound) { _, _ in
                                        hasChanges = true
                                    }

                                HStack {
                                    Text("0.6")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Maintenance")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("1.5")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(AppSpacing.lg)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Fat Settings
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Fat Target")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg + AppSpacing.xs)

                        GlassCard {
                            VStack(spacing: AppSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(fatPercentage))% of calories")
                                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        Text(fatDescription)
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                Slider(value: $fatPercentage, in: 20...40, step: 1)
                                    .tint(.orange)
                                    .onChange(of: fatPercentage) { _, _ in
                                        hasChanges = true
                                    }

                                HStack {
                                    Text("20%")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Balanced")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("40%")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(AppSpacing.lg)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Flexibility Settings
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Tracking Style")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg + AppSpacing.xs)

                        GlassCard {
                            VStack(spacing: AppSpacing.xs) {
                                ForEach(["strict", "balanced", "flexible"], id: \.self) { style in
                                    Button {
                                        withAnimation(.smooth(duration: 0.2)) {
                                            macroFlexibility = style
                                            hasChanges = true
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(flexibilityTitle(for: style))
                                                    .font(.system(size: 17, design: .rounded))
                                                    .foregroundStyle(.primary)
                                                Text(flexibilityDescription(for: style))
                                                    .font(.system(size: 12, design: .rounded))
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            if macroFlexibility == style {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(
                                                        LinearGradient(
                                                            colors: gradientManager.active.colors(for: colorScheme),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            }
                                        }
                                        .padding(AppSpacing.md)
                                        .background(
                                            macroFlexibility == style ?
                                                Color.white.opacity(0.05) : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)

                                    if style != "flexible" {
                                        Divider()
                                            .padding(.horizontal, AppSpacing.md)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Action Buttons
                    if hasChanges {
                        HStack(spacing: AppSpacing.md) {
                            Button {
                                resetToDefaults()
                            } label: {
                                Text("Reset")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                saveChanges()
                            } label: {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                    }

                    Spacer(minLength: AppSpacing.xl)
                }
            }
        }
        .task { await loadAdjustments() }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Reset to AI Recommendations?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToAIRecommendations()
            }
        } message: {
            Text("This will restore the macro targets your AI coach originally recommended based on your goals.")
        }
    }

    // MARK: - Computed Properties

    private var proteinDescription: String {
        switch proteinPerPound {
        case 0.6..<0.8:
            return "Light activity, maintenance"
        case 0.8..<1.0:
            return "General fitness, moderate activity"
        case 1.0..<1.2:
            return "Muscle building, strength training"
        case 1.2...1.5:
            return "Intense training, maximum growth"
        default:
            return "Custom target"
        }
    }

    private var proteinIcon: String {
        switch proteinPerPound {
        case 0.6..<0.9:
            return "leaf.fill"
        case 0.9..<1.1:
            return "figure.walk"
        case 1.1...1.5:
            return "figure.strengthtraining.traditional"
        default:
            return "fork.knife"
        }
    }

    private var fatDescription: String {
        switch Int(fatPercentage) {
        case 20..<25:
            return "Lower fat, higher carbs"
        case 25..<30:
            return "Moderate balance"
        case 30..<35:
            return "Balanced approach"
        case 35...40:
            return "Higher fat, lower carbs"
        default:
            return "Custom target"
        }
    }

    private func flexibilityTitle(for style: String) -> String {
        switch style {
        case "strict":
            return "Precise Tracking"
        case "balanced":
            return "Balanced Approach"
        case "flexible":
            return "Flexible Guidelines"
        default:
            return style.capitalized
        }
    }

    private func flexibilityDescription(for style: String) -> String {
        switch style {
        case "strict":
            return "Hit your macros within 5g daily"
        case "balanced":
            return "Focus on protein, balance the rest"
        case "flexible":
            return "Weekly averages, 80/20 rule"
        default:
            return ""
        }
    }

    // MARK: - Helper Methods

    private func getCurrentRecommendations() -> NutritionRecommendations? {
        // Try to get recommendations from persona if available
        guard let personaData = user.onboardingProfile?.personaData,
              let persona = try? JSONDecoder().decode(PersonaProfile.self, from: personaData) else {
            return nil
        }
        return persona.nutritionRecommendations
    }

    private func resetToDefaults() {
        withAnimation {
            proteinPerPound = originalProtein
            fatPercentage = originalFat * 100
            macroFlexibility = originalFlexibility
            hasChanges = false
        }
    }

    private func resetToAIRecommendations() {
        guard let recommendations = getCurrentRecommendations() else { return }

        withAnimation {
            proteinPerPound = recommendations.proteinGramsPerPound
            fatPercentage = recommendations.fatPercentage * 100

            // Map flexibility notes to simple preference
            if recommendations.flexibilityNotes.contains("strict") || recommendations.flexibilityNotes.contains("precise") {
                macroFlexibility = "strict"
            } else if recommendations.flexibilityNotes.contains("80/20") || recommendations.flexibilityNotes.contains("flexible") {
                macroFlexibility = "flexible"
            } else {
                macroFlexibility = "balanced"
            }

            hasChanges = true
        }
    }

    private func saveChanges() {
        user.proteinGramsPerPound = proteinPerPound
        user.fatPercentage = fatPercentage / 100 // Convert back to decimal
        user.macroFlexibility = macroFlexibility

        do {
            // TODO: Save through repository when implemented
            // For now, just update the user model directly
            hasChanges = false

            // Log the change
            AppLogger.info("Updated nutrition targets: \(proteinPerPound)g/lb protein, \(Int(fatPercentage))% fat", category: .data)

            // Haptic feedback
            HapticService.play(.dataUpdated)
        } catch {
            AppLogger.error("Failed to save nutrition settings", error: error, category: .data)
        }
    }

    private func loadAdjustments() async {
        // TODO: Move to repository pattern
        // For now, return empty adjustments to remove SwiftData dependency
        adjustments = []
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        NutritionSettingsView(user: {
            let user = User(name: "Test User")
            user.proteinGramsPerPound = 0.8
            user.fatPercentage = 0.25
            user.macroFlexibility = "balanced"
            return user
        }())
        .environmentObject(GradientManager())
    }
}
