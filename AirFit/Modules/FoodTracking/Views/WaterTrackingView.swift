import SwiftUI
import Charts // For potential future chart-based insights

/// A view for logging water intake, tracking hydration goals, and viewing hydration insights.
struct WaterTrackingView: View {
    @ObservedObject var viewModel: FoodTrackingViewModel
    @Environment(\\.dismiss) private var dismiss

    // State for custom input
    @State private var selectedAmount: Double = 250 // Default quick add selection
    @State private var selectedUnit: WaterUnit = .ml
    @State private var customAmountString: String = ""
    @State private var useCustomAmount: Bool = false

    // Configuration
    private let quickAmountsInML: [Double] = [250, 350, 500, 750] // Common amounts in mL
    private let dailyWaterGoalInML: Double = 2000 // Default daily goal, can be dynamic later

    // Animation states
    @State private var waterLevel: CGFloat = 0
    @State private var showTips: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    currentIntakeSection
                        .padding(.top)

                    quickAddSection

                    customAmountSection

                    hydrationTipsSection // Placeholder for Hydration Tips

                    // Placeholders for future features
                    // historicalInsightsSection
                    // smartRemindersSection
                }
                .padding()
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Log Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addWater) {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .disabled(isAddButtonDisabled)
                }
            }
            .onAppear(perform: initialSetup)
            .onChange(of: viewModel.waterIntakeML) { _, newValue in
                updateWaterLevelAnimation(intake: newValue)
            }
            .sheet(isPresented: $showTips) {
                HydrationTipsView()
            }
        }
    }

    // MARK: - Computed Properties
    private var currentCustomAmountValue: Double {
        Double(customAmountString) ?? 0
    }

    private var isAddButtonDisabled: Bool {
        if useCustomAmount {
            return currentCustomAmountValue <= 0
        }
        return false // Quick add always enabled
    }

    private var progressTowardsGoal: Double {
        guard dailyWaterGoalInML > 0 else { return 0 }
        return min(viewModel.waterIntakeML / dailyWaterGoalInML, 1.0) // Cap at 100% for main display
    }
    
    private var overGoalProgress: Double {
        guard dailyWaterGoalInML > 0 else { return 0 }
        let rawProgress = viewModel.waterIntakeML / dailyWaterGoalInML
        return max(0, rawProgress - 1.0) // Progress beyond 1.0
    }

    // MARK: - View Sections

    private var currentIntakeSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("Today's Intake")
                .font(AppFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            ZStack {
                // Background track for the ring
                Circle()
                    .stroke(AppColors.accentColor.opacity(0.2), lineWidth: 20)

                // Main progress ring
                Circle()
                    .trim(from: 0, to: waterLevel)
                    .stroke(
                        AppColors.accentColor.gradient, // Using accent color gradient
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Overage progress ring (dashed)
                if overGoalProgress > 0 && waterLevel >= 1.0 { // Only show if main ring is full
                    Circle()
                        .trim(from: 0, to: min(overGoalProgress, 1.0)) // Can also go over 200%
                        .stroke(
                            AppColors.accentColor.opacity(0.6),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round, dash: [10, 5])
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: waterLevel)
                }


                VStack(spacing: AppSpacing.xxSmall) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.accentColor)
                        .symbolEffect(.variableColor.iterative.reversing, options: .speed(0.5), value: waterLevel)


                    Text("\(Int(viewModel.waterIntakeML)) mL")
                        .font(AppFonts.title1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .contentTransition(.numericText(countsDown: viewModel.waterIntakeML < (Double(Int(viewModel.waterIntakeML)))))


                    Text("Goal: \(Int(dailyWaterGoalInML)) mL")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.bottom, AppSpacing.small)
            
            Text(goalStatusText)
                .font(AppFonts.footnote)
                .foregroundColor(progressTowardsGoal >= 1.0 ? AppColors.successColor : AppColors.textTertiary)
                .animation(.easeInOut, value: progressTowardsGoal)
        }
    }
    
    private var goalStatusText: String {
        if progressTowardsGoal >= 1.0 {
            let percentageOver = Int(( (viewModel.waterIntakeML / dailyWaterGoalInML) - 1.0) * 100)
            if percentageOver > 0 {
                return "Goal reached! \(percentageOver)% over."
            }
            return "Daily goal reached!"
        } else {
            let remaining = dailyWaterGoalInML - viewModel.waterIntakeML
            return "\(Int(remaining)) mL more to reach your goal."
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Quick Add")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                ForEach(quickAmountsInML, id: \.self) { amount in
                    QuickWaterButton(
                        amount: amount,
                        unit: .ml, // Quick adds are in mL
                        isSelected: !useCustomAmount && selectedAmount == amount && selectedUnit == .ml
                    ) {
                        self.selectedAmount = amount
                        self.selectedUnit = .ml
                        self.useCustomAmount = false
                        self.customAmountString = "" // Clear custom amount
                        HapticManager.selection()
                    }
                }
            }
        }
    }

    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Custom Amount")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: AppSpacing.medium) {
                TextField("Enter amount", text: $customAmountString)
                    .font(AppFonts.title3)
                    .keyboardType(.decimalPad)
                    .padding(AppSpacing.medium)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius.small)
                            .stroke(useCustomAmount ? AppColors.accentColor : AppColors.dividerColor, lineWidth: useCustomAmount ? 2 : 1)
                    )
                    .onTapGesture {
                        self.useCustomAmount = true
                        HapticManager.selection()
                    }
                    .onChange(of: customAmountString) { _, newValue in
                        // Ensure it's a valid number, could add more validation
                        if Double(newValue) == nil && !newValue.isEmpty {
                            // customAmountString = String(newValue.dropLast()) // Basic validation
                        }
                    }


                Picker("Unit", selection: $selectedUnit) {
                    ForEach(WaterUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 150)
                .onChange(of: selectedUnit) { _, _ in
                    self.useCustomAmount = true // Selecting unit implies custom amount
                    HapticManager.selection()
                }
            }
        }
    }

    private var hydrationTipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Hydration Tip")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button {
                    showTips = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColors.accentColor)
                }
            }
            Text("Carry a water bottle throughout the day as a visual reminder to drink.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.infoColor.opacity(0.1))
                .cornerRadius(AppConstants.Layout.defaultCornerRadius.small)
        }
    }
    
    // Placeholder for Historical Insights - Future Enhancement
    // private var historicalInsightsSection: some View { ... }

    // Placeholder for Smart Reminders - Future Enhancement
    // private var smartRemindersSection: some View { ... }


    // MARK: - Actions

    private func initialSetup() {
        updateWaterLevelAnimation(intake: viewModel.waterIntakeML)
        // Set default selection for quick add if not using custom
        if !useCustomAmount && !quickAmountsInML.contains(selectedAmount) {
            selectedAmount = quickAmountsInML.first ?? 250
            selectedUnit = .ml
        }
    }
    
    private func updateWaterLevelAnimation(intake: Double) {
        let rawProgress = (dailyWaterGoalInML > 0) ? (intake / dailyWaterGoalInML) : 0
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.8)) {
            // waterLevel can exceed 1.0 to drive overage ring, but main ring caps at 1.0
            waterLevel = rawProgress
        }
    }

    private func addWater() {
        let amountToAdd: Double
        let unitToLog: WaterUnit

        if useCustomAmount {
            guard currentCustomAmountValue > 0 else {
                // Optionally show an alert for invalid input
                return
            }
            amountToAdd = currentCustomAmountValue
            unitToLog = selectedUnit
        } else {
            amountToAdd = selectedAmount
            unitToLog = selectedUnit // Should be .ml for quick adds
        }

        Task {
            await viewModel.logWater(amount: amountToAdd, unit: unitToLog)
            HapticManager.success()

            // Reset custom input field after logging
            if useCustomAmount {
                customAmountString = ""
                // useCustomAmount = false // Optionally reset to quick add mode
            }
        }
    }
}

// MARK: - Supporting Views

/// A button for quick water logging.
struct QuickWaterButton: View {
    let amount: Double
    let unit: WaterUnit // Expecting .ml for consistency from quickAmountsInML
    let isSelected: Bool
    let action: () -> Void

    private var displayText: String {
        // Assuming quick amounts are always in mL as per quickAmountsInML
        return "\(Int(amount)) mL"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "drop.fill")
                    .font(AppFonts.title2)
                    .foregroundColor(isSelected ? AppColors.textOnAccent : AppColors.accentColor)
                Text(displayText)
                    .font(AppFonts.callout)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? AppColors.textOnAccent : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(isSelected ? AppColors.accentColor : AppColors.backgroundSecondary)
            .cornerRadius(AppConstants.Layout.defaultCornerRadius.medium)
            .shadow(color: isSelected ? AppColors.accentColor.opacity(0.3) : .clear, radius: 5, y: 3)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

/// A view to display hydration tips.
struct HydrationTipsView: View {
    @Environment(\\.dismiss) private var dismiss
    
    private let tips = [
        ("Start Early", "Drink a glass of water when you wake up."),
        ("Flavor It Up", "Add lemon, cucumber, or berries to your water."),
        ("Eat Water-Rich Foods", "Fruits like watermelon and vegetables like cucumber contribute to hydration."),
        ("Set Reminders", "Use app notifications or alarms to remind yourself to drink."),
        ("Before Meals", "Drink a glass of water before each meal."),
        ("Track Your Intake", "Use this app to monitor your progress!"),
        ("Listen to Your Body", "Drink when you feel thirsty, and check urine color (pale yellow is good).")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(tips, id: \.0) { tip in
                    Section(header: Text(tip.0).font(AppFonts.headline)) {
                        Text(tip.1)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Hydration Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Previews
#Preview("Water Tracking View - Initial") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared) // Ensure VoiceInputManager is available
    let nutritionService = NutritionService(modelContext: context)
    let foodDBService = FoodDatabaseService() // Mock or actual
    let coachEngine = CoachEngine.createDefault(modelContext: context)


    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )
    
    // Simulate some initial water intake for preview
    Task { await viewModel.logWater(amount: 750, unit: .ml) }

    return WaterTrackingView(viewModel: viewModel)
        .modelContainer(modelContainer) // Ensure modelContainer is passed for SwiftData
}

#Preview("Water Tracking View - Goal Reached") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared)
    let nutritionService = NutritionService(modelContext: context)
    let foodDBService = FoodDatabaseService()
    let coachEngine = CoachEngine.createDefault(modelContext: context)

    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )

    // Simulate goal reached
    Task {
        await viewModel.logWater(amount: 2000, unit: .ml)
    }
    
    return WaterTrackingView(viewModel: viewModel)
        .modelContainer(modelContainer)
}

#Preview("Water Tracking View - Over Goal") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared)
    let nutritionService = NutritionService(modelContext: context)
    let foodDBService = FoodDatabaseService()
    let coachEngine = CoachEngine.createDefault(modelContext: context)

    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )

    Task {
        await viewModel.logWater(amount: 2500, unit: .ml) // Exceed goal
    }
    
    return WaterTrackingView(viewModel: viewModel)
        .modelContainer(modelContainer)
}

#Preview("Hydration Tips Sheet") {
    HydrationTipsView()
}
