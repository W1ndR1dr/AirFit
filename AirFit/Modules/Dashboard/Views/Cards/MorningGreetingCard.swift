import SwiftUI

struct MorningGreetingCard: View {
    let greeting: String
    let context: GreetingContext?
    let currentEnergy: Int?
    let onEnergyLog: (Int) -> Void

    @State private var showEnergyPicker = false
    @State private var animateIn = false

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                // Greeting Text
                Text(greeting)
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                // Context Pills
                if let context = context {
                    contextPills(for: context)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }

                Divider()
                    .padding(.vertical, AppSpacing.xSmall)

                // Energy Logger
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("How's your energy?")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)

                    if let energy = currentEnergy {
                        HStack {
                            EnergyLevelIndicator(level: energy)
                            Spacer()
                            Button("Update") {
                                showEnergyPicker = true
                            }
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.accentColor)
                        }
                    } else {
                        Button {
                            showEnergyPicker = true
                        } label: {
                            Label("Log Energy", systemImage: "bolt.fill")
                                .font(AppFonts.callout)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.small)
                                .background(AppColors.accentColor.opacity(0.1))
                                .foregroundColor(AppColors.accentColor)
                                .cornerRadius(AppConstants.Layout.smallCornerRadius)
                        }
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showEnergyPicker) {
            EnergyPickerSheet(
                currentLevel: currentEnergy,
                onSelect: { level in
                    onEnergyLog(level)
                    showEnergyPicker = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateIn = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Morning greeting: \(greeting)")
        .accessibilityHint(
            currentEnergy == nil ? "Tap to log your energy level" : "Your energy is logged as \(currentEnergy!)"
        )
    }

    @ViewBuilder
    private func contextPills(for context: GreetingContext) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                if let sleep = context.sleepHours {
                    ContextPill(
                        icon: "bed.double.fill",
                        text: "\(Int(sleep))h sleep",
                        color: sleep >= 7 ? .green : .orange
                    )
                }

                if let weather = context.weather {
                    ContextPill(
                        icon: weatherIcon(for: weather),
                        text: weather,
                        color: .blue
                    )
                }

                if let temp = context.temperature {
                    ContextPill(
                        icon: "thermometer",
                        text: "\(Int(temp))°",
                        color: temperatureColor(for: temp)
                    )
                }
            }
        }
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy", "rain": return "cloud.rain.fill"
        case "snow": return "cloud.snow.fill"
        default: return "cloud.sun.fill"
        }
    }

    private func temperatureColor(for temp: Double) -> Color {
        switch temp {
        case ..<10: return .blue
        case 10..<20: return .teal
        case 20..<30: return .green
        default: return .orange
        }
    }
}

// MARK: - Supporting Views
struct ContextPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(AppFonts.caption)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

struct EnergyLevelIndicator: View {
    let level: Int

    private var emoji: String {
        switch level {
        case 1: return "😴"
        case 2: return "😪"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🔥"
        default: return "😐"
        }
    }

    private var description: String {
        switch level {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Energy: \(description)")
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= level ? AppColors.accentColor : AppColors.dividerColor)
                            .frame(width: 20, height: 4)
                    }
                }
            }
        }
    }
}

struct EnergyPickerSheet: View {
    let currentLevel: Int?
    let onSelect: (Int) -> Void

    @State private var selectedLevel: Int?
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                Text("How's your energy today?")
                    .font(AppFonts.title3)
                    .padding(.top)

                HStack(spacing: AppSpacing.medium) {
                    ForEach(1...5, id: \.self) { level in
                        EnergyOption(
                            level: level,
                            isSelected: selectedLevel == level,
                            onTap: {
                                selectedLevel = level
                                // TODO: Add haptic feedback via DI when needed
                                onSelect(level)
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Log Energy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedLevel = currentLevel
        }
    }
}

struct EnergyOption: View {
    let level: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var emoji: String {
        switch level {
        case 1: return "😴"
        case 2: return "😪"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🔥"
        default: return "😐"
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Text(emoji)
                .font(.system(size: 44))

            Text("\(level)")
                .font(AppFonts.caption)
                .foregroundColor(isSelected ? AppColors.accentColor : AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                .fill(isSelected ? AppColors.accentColor.opacity(0.1) : AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                        .stroke(isSelected ? AppColors.accentColor : AppColors.dividerColor, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture(perform: onTap)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MorningGreetingCard(
        greeting: "Good morning, Alex! Ready to conquer the day?",
        context: GreetingContext(
            sleepHours: 7.5,
            weather: "Sunny, 23°C",
            todaysSchedule: "Morning run at 7am",
            recentAchievements: ["5 day streak!"]
        ),
        currentEnergy: 3,
        onEnergyLog: { _ in }
    )
}
