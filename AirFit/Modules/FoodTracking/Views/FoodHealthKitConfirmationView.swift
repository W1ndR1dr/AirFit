import SwiftUI

/// Confirmation view shown before saving food to HealthKit
/// Allows users to review and edit parsed nutrition data
struct FoodHealthKitConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let foodEntry: FoodEntry
    let onConfirm: () async -> Void
    let onEdit: () -> Void

    @State private var isSaving = false
    @State private var showHealthKitDetails = false

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    nutritionSummarySection
                    foodItemsSection
                    healthKitInfoSection
                    actionButtonsSection
                }
            }
        }
        .sheet(isPresented: $showHealthKitDetails) {
            HealthKitDetailsView()
                .presentationDetents([.medium])
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color("BackgroundGradientStart"), Color("BackgroundGradientEnd")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Confirm Nutrition Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Review before saving to Apple Health")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private var nutritionSummarySection: some View {
        VStack(spacing: 16) {
            calorieRing
            macrosRow
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: calorieProgress)
                .stroke(calorieGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(foodEntry.totalCalories)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("calories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var calorieProgress: Double {
        min(1, Double(foodEntry.totalCalories) / 2_000)
    }

    private var calorieGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var macrosRow: some View {
        HStack(spacing: 32) {
            MacroView(
                label: "Protein",
                value: foodEntry.totalProtein,
                unit: "g",
                color: .blue
            )

            MacroView(
                label: "Carbs",
                value: foodEntry.totalCarbs,
                unit: "g",
                color: .orange
            )

            MacroView(
                label: "Fat",
                value: foodEntry.totalFat,
                unit: "g",
                color: .purple
            )
        }
    }

    private var foodItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Items")
                .font(.headline)
                .padding(.horizontal)

            ForEach(foodEntry.items) { item in
                foodItemRow(item)
            }
            .padding(.horizontal)
        }
    }

    private func foodItemRow(_ item: FoodItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)

                if let brand = item.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("\(item.formattedQuantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(item.calories ?? 0)) cal")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var healthKitInfoSection: some View {
        Button {
            showHealthKitDetails.toggle()
        } label: {
            HStack {
                Image(systemName: "heart.text.square")
                    .font(.title3)
                    .foregroundStyle(.pink)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health Integration")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Tap to learn more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            editButton
            saveButton
        }
        .padding()
    }

    private var editButton: some View {
        Button {
            onEdit()
        } label: {
            Label("Edit", systemImage: "pencil")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button {
            Task {
                isSaving = true
                await onConfirm()
                isSaving = false
                dismiss()
            }
        } label: {
            if isSaving {
                TextLoadingView(message: "Saving to HealthKit", style: .subtle)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Label("Save to Health", systemImage: "checkmark")
                    .foregroundStyle(.black)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }
}

// MARK: - Supporting Views

private struct MacroView: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HealthKitDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundGradientStart"), Color("BackgroundGradientEnd")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Data Syncing", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        Text("Your nutrition data will be saved to Apple Health, making it available to other health and fitness apps.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Privacy First", systemImage: "lock.shield")
                            .font(.headline)
                            .foregroundStyle(.green)

                        Text("Your health data stays on your device. AirFit only writes nutrition data you explicitly save.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Duplicate Prevention", systemImage: "doc.on.doc")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        Text("AirFit checks for similar entries within 5 minutes to prevent accidental duplicates.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Apple Health Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let entry = FoodEntry(
        loggedAt: Date(),
        mealType: .lunch
    )

    let item1 = FoodItem(
        name: "Grilled Chicken Breast",
        quantity: 150,
        unit: "g",
        calories: 248,
        proteinGrams: 46.5,
        carbGrams: 0,
        fatGrams: 5.4
    )

    let item2 = FoodItem(
        name: "Brown Rice",
        quantity: 1,
        unit: "cup",
        calories: 216,
        proteinGrams: 4.5,
        carbGrams: 44.8,
        fatGrams: 1.8
    )

    entry.items.append(item1)
    entry.items.append(item2)

    return FoodHealthKitConfirmationView(
        foodEntry: entry,
        onConfirm: { },
        onEdit: { }
    )
}
