import SwiftUI
#if DEBUG
import HealthKit

// MARK: - HealthKit Test Data Detail View
struct HealthKitTestDataDetailView: View {
    @State private var selectedDataTypes: Set<HealthKitDataType> = []
    @State private var dateRange = DateRange.today
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var isGenerating = false
    @State private var statusMessage = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.diContainer) private var container
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    enum DateRange: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case lastWeek = "Last 7 Days"
        case lastMonth = "Last 30 Days"
        case custom = "Custom Range"

        var displayName: String { rawValue }
    }

    enum HealthKitDataType: String, CaseIterable, Identifiable {
        case activity = "Activity Data"
        case nutrition = "Nutrition"
        case bodyMetrics = "Body Metrics"
        case workouts = "Workouts"
        case sleep = "Sleep"
        case heartHealth = "Heart Health"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .activity: return "figure.walk"
            case .nutrition: return "fork.knife"
            case .bodyMetrics: return "scalemass"
            case .workouts: return "figure.run"
            case .sleep: return "bed.double"
            case .heartHealth: return "heart.fill"
            }
        }

        var description: String {
            switch self {
            case .activity: return "Steps, calories, distance, stand hours"
            case .nutrition: return "Meals, macros, water intake"
            case .bodyMetrics: return "Weight, body fat, BMI"
            case .workouts: return "Various workout types with heart rate"
            case .sleep: return "Sleep stages and duration"
            case .heartHealth: return "Heart rate, HRV, VO2 Max"
            }
        }
    }

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.largeTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Spacer()
                        }

                        Text("Custom Test Data Generator")
                            .font(.title2.bold())

                        Text("Select the types of data you want to generate and the date range")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Data Type Selection
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Data Types")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: AppSpacing.sm) {
                            ForEach(HealthKitDataType.allCases) { dataType in
                                GlassCard {
                                    HStack(spacing: AppSpacing.md) {
                                        Image(systemName: dataType.icon)
                                            .font(.title3)
                                            .foregroundStyle(
                                                selectedDataTypes.contains(dataType) ?
                                                    LinearGradient(
                                                        colors: gradientManager.active.colors(for: colorScheme),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) : LinearGradient(colors: [.secondary], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(dataType.rawValue)
                                                .font(.subheadline.weight(.medium))
                                            Text(dataType.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Toggle("", isOn: Binding(
                                            get: { selectedDataTypes.contains(dataType) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedDataTypes.insert(dataType)
                                                } else {
                                                    selectedDataTypes.remove(dataType)
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                        .tint(Color(gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                                    }
                                    .padding(.vertical, AppSpacing.xs)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Date Range Selection
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Date Range")
                            .font(.headline)
                            .padding(.horizontal)

                        GlassCard {
                            VStack(spacing: 0) {
                                Picker("Date Range", selection: $dateRange) {
                                    ForEach(DateRange.allCases, id: \.self) { range in
                                        Text(range.displayName).tag(range)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.bottom, AppSpacing.sm)

                                if dateRange == .custom {
                                    VStack(spacing: AppSpacing.sm) {
                                        DatePicker(
                                            "Start Date",
                                            selection: $customStartDate,
                                            in: ...Date(),
                                            displayedComponents: .date
                                        )

                                        DatePicker(
                                            "End Date",
                                            selection: $customEndDate,
                                            in: customStartDate...Date(),
                                            displayedComponents: .date
                                        )
                                    }
                                    .padding(.top, AppSpacing.sm)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: AppSpacing.sm) {
                            Button(action: selectAll) {
                                Text("Select All")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }

                            Button(action: deselectAll) {
                                Text("Deselect All")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Generate Button
                    Button(action: generateData) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }

                            Text(isGenerating ? "Generating..." : "Generate Test Data")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(selectedDataTypes.isEmpty || isGenerating ? 0.5 : 1.0)
                    }
                    .disabled(selectedDataTypes.isEmpty || isGenerating)
                    .padding(.horizontal)

                    // Status Message
                    if !statusMessage.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                    }

                    // Info Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Important Notes", systemImage: "info.circle")
                                .font(.subheadline.bold())

                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                bulletPoint("Test data is marked with metadata for easy identification")
                                bulletPoint("Data generation may take a few moments")
                                bulletPoint("HealthKit authorization is required")
                                bulletPoint("Best used in iOS Simulator for testing")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Custom Test Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Test data has been generated successfully")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func selectAll() {
        selectedDataTypes = Set(HealthKitDataType.allCases)
        HapticService.impact(.soft)
    }

    private func deselectAll() {
        selectedDataTypes.removeAll()
        HapticService.impact(.soft)
    }

    private func generateData() {
        isGenerating = true
        statusMessage = "Requesting HealthKit authorization..."

        Task {
            do {
                // Get HealthKit manager from DI container
                let healthKitManager = try await container.resolve(HealthKitManaging.self)

                // Request authorization if needed
                if let manager = healthKitManager as? HealthKitManager,
                   manager.authorizationStatus != .authorized {
                    try await manager.requestAuthorization()
                }

                statusMessage = "Generating test data..."

                // Create generator
                let generator = HealthKitTestDataGenerator(healthStore: HKHealthStore())

                // Determine date range
                let calendar = Calendar.current
                let dates: [Date]

                switch dateRange {
                case .today:
                    dates = [Date()]
                case .yesterday:
                    dates = [calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()]
                case .lastWeek:
                    dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
                case .lastMonth:
                    dates = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
                case .custom:
                    let daysBetween = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 0
                    dates = (0...daysBetween).compactMap { calendar.date(byAdding: .day, value: $0, to: customStartDate) }
                }

                // Generate data for each selected type and date
                for (index, date) in dates.enumerated() {
                    let progress = Double(index + 1) / Double(dates.count)
                    await MainActor.run {
                        statusMessage = "Generating data... \(Int(progress * 100))%"
                    }

                    // Use reflection to call appropriate methods based on selected types
                    // This is a simplified approach - in production, you'd want more granular control
                    for dataType in selectedDataTypes {
                        switch dataType {
                        case .activity:
                            try await generator.generateActivityData(for: date)
                        case .nutrition:
                            try await generator.generateNutritionData(for: date)
                        case .bodyMetrics:
                            if index % 3 == 0 { // Body metrics less frequently
                                try await generator.generateBodyMetrics(for: date)
                            }
                        case .workouts:
                            if [0, 2, 4, 5].contains(index % 7) { // Workouts on some days
                                try await generator.generateWorkoutData(for: date)
                            }
                        case .sleep:
                            try await generator.generateSleepData(for: date)
                        case .heartHealth:
                            try await generator.generateHeartHealthData(for: date)
                        }
                    }
                }

                await MainActor.run {
                    isGenerating = false
                    statusMessage = ""
                    showSuccessAlert = true
                    HapticService.play(.success)
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    statusMessage = ""
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    HapticService.play(.error)
                }
            }
        }
    }
}


#endif // DEBUG
