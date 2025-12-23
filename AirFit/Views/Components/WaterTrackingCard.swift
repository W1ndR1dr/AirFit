import SwiftUI
import SwiftData

struct WaterTrackingCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: WaterEntry.today, sort: \WaterEntry.timestamp, order: .reverse)
    private var todayEntries: [WaterEntry]

    @State private var showHistory = false
    @State private var showCustomInput = false
    @State private var customAmount = ""

    private let targetOunces = 120  // 15 cups (adjustable in future)

    private var totalOunces: Int {
        todayEntries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 16))
                Text("Water")
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(totalOunces) / \(targetOunces) oz")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Quick add buttons
            HStack(spacing: 12) {
                QuickAddButton(label: "8 oz", icon: "drop") {
                    addWater(8)
                }
                QuickAddButton(label: "16 oz", icon: "drop.fill") {
                    addWater(16)
                }
                QuickAddButton(label: "Custom", icon: "plus") {
                    showCustomInput = true
                }
            }

            // Progress bar
            HeroProgressBar(
                label: "Hydration",
                current: totalOunces,
                target: targetOunces,
                unit: " oz",
                color: .blue
            )

            // Expandable history
            if showHistory && !todayEntries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(todayEntries) { entry in
                        HStack {
                            Text("\(entry.amount) oz")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(entry.timestamp, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Button {
                                deleteEntry(entry)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
            }

            // Show history toggle
            if !todayEntries.isEmpty {
                Button {
                    withAnimation(.airfit) { showHistory.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(showHistory ? "Hide" : "Show \(todayEntries.count) entries")
                            .font(.labelMedium)
                        Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        .alert("Add Water", isPresented: $showCustomInput) {
            TextField("Ounces", text: $customAmount)
                .keyboardType(.numberPad)
            Button("Add") {
                if let amount = Int(customAmount), amount > 0 {
                    addWater(amount)
                }
                customAmount = ""
            }
            Button("Cancel", role: .cancel) {
                customAmount = ""
            }
        } message: {
            Text("Enter amount in ounces")
        }
    }

    private func addWater(_ amount: Int) {
        let entry = WaterEntry(amount: amount)
        modelContext.insert(entry)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteEntry(_ entry: WaterEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct QuickAddButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.labelMedium)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WaterTrackingCard()
        .padding()
        .background(Theme.background)
}
