import SwiftUI
import Charts // For potential future chart-based insights
import SwiftData

/// A view for logging water intake, tracking hydration goals, and viewing hydration insights.
struct WaterTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: FoodTrackingViewModel

    // State for custom input
    @State private var selectedAmount: Double = 250 // Default quick add selection
    @State private var selectedUnit: WaterUnit = .milliliters
    @State private var customAmountString: String = ""
    @State private var useCustomAmount: Bool = false

    // Configuration
    private let quickAmountsInML: [Double] = [250, 350, 500, 750] // Common amounts in mL
    private let dailyWaterGoalInML: Double = 2000 // Default daily goal, can be dynamic later

    // Animation states
    @State private var waterLevel: CGFloat = 0
    @State private var showTips: Bool = false
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        currentIntakeSection
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        quickAddSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        customAmountSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                        hydrationTipsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { 
                        HapticService.impact(.light)
                        dismiss() 
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        HapticService.impact(.medium)
                        addWater()
                    }) {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .disabled(isAddButtonDisabled)
                    .foregroundStyle(
                        isAddButtonDisabled ? 
                        AnyShapeStyle(Color.secondary.opacity(0.5)) :
                        AnyShapeStyle(LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                }
                
                ToolbarItem(placement: .principal) {
                    CascadeText("Hydration")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
            }
            .onAppear {
                initialSetup()
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
            .onChange(of: viewModel.waterIntakeML) { _, newValue in
                updateWaterLevelAnimation(intake: newValue)
            }
            .sheet(isPresented: $showTips) {
                HydrationTipsView()
                    .environmentObject(gradientManager)
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
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                CascadeText("Today's Intake")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                ZStack {
                    // Gradient glow behind rings
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? Color.clear,
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 20)
                        .opacity(waterLevel > 0 ? 1 : 0)
                    
                    // Background track for the ring
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 24)
                        .frame(width: 180, height: 180)

                    // Main progress ring with gradient
                    Circle()
                        .trim(from: 0, to: min(waterLevel, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#00B4D8"),
                                    Color(hex: "#0077B6")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 24, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: "#00B4D8").opacity(0.5), radius: 10, y: 5)
                    
                    // Overage progress ring (dashed)
                    if overGoalProgress > 0 && waterLevel >= 1.0 {
                        Circle()
                            .trim(from: 0, to: min(overGoalProgress, 1.0))
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#00B4D8").opacity(0.6),
                                        Color(hex: "#90E0EF").opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round, dash: [10, 5])
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(MotionToken.standardSpring.delay(0.5), value: waterLevel)
                    }

                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#00B4D8"),
                                        Color(hex: "#0077B6")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolEffect(.variableColor.iterative.reversing, options: .speed(0.5), value: waterLevel)
                            .scaleEffect(waterLevel > 0 ? 1.1 : 1.0)
                            .animation(MotionToken.standardSpring, value: waterLevel)

                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                GradientNumber(value: viewModel.waterIntakeML)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                Text("mL")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }
                            .contentTransition(.numericText(countsDown: viewModel.waterIntakeML < (Double(Int(viewModel.waterIntakeML)))))

                            Text("Goal: \(Int(dailyWaterGoalInML)) mL")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }
                }
                .frame(width: 220, height: 220)
                .padding(.bottom, AppSpacing.sm)
                
                // Goal status with gradient when complete
                if progressTowardsGoal >= 1.0 {
                    Text(goalStatusText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#52B788"),
                                    Color(hex: "#40916C")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .animation(.easeInOut, value: progressTowardsGoal)
                } else {
                    Text(goalStatusText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .animation(.easeInOut, value: progressTowardsGoal)
                }
            }
            .padding(AppSpacing.lg)
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                CascadeText("Quick Add")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                ForEach(Array(quickAmountsInML.enumerated()), id: \.element) { index, amount in
                    QuickWaterButton(
                        amount: amount,
                        unit: .milliliters,
                        isSelected: !useCustomAmount && selectedAmount == amount && selectedUnit == .milliliters,
                        index: index
                    ) {
                        HapticService.impact(.light)
                        withAnimation(MotionToken.microAnimation) {
                            self.selectedAmount = amount
                            self.selectedUnit = .milliliters
                            self.useCustomAmount = false
                            self.customAmountString = ""
                        }
                    }
                    .environmentObject(gradientManager)
                }
            }
        }
    }

    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                CascadeText("Custom Amount")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
            }

            GlassCard {
                HStack(spacing: AppSpacing.md) {
                    TextField("Enter amount", text: $customAmountString)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .keyboardType(.decimalPad)
                        .padding(AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    useCustomAmount ? 
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : 
                                    LinearGradient(
                                        colors: [Color.clear, Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: useCustomAmount ? 2 : 0
                                )
                        )
                        .onTapGesture {
                            HapticService.impact(.light)
                            withAnimation(MotionToken.microAnimation) {
                                self.useCustomAmount = true
                            }
                        }

                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(WaterUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(minWidth: 120)
                    .onChange(of: selectedUnit) { _, _ in
                        HapticService.impact(.light)
                        withAnimation(MotionToken.microAnimation) {
                            self.useCustomAmount = true
                        }
                    }
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private var hydrationTipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                CascadeText("Hydration Tip")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
                Button {
                    HapticService.impact(.light)
                    showTips = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            GlassCard {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#00B4D8"),
                                    Color(hex: "#0077B6")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Carry a water bottle throughout the day as a visual reminder to drink.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.md)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#00B4D8").opacity(0.2),
                                Color(hex: "#0077B6").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
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
            selectedUnit = .milliliters
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
            HapticService.play(.dataUpdated)
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
    let unit: WaterUnit
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var displayText: String {
        return "\(Int(amount)) mL"
    }

    var body: some View {
        Button(action: action) {
            GlassCard {
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            isSelected ?
                            AnyShapeStyle(Color.white) :
                            AnyShapeStyle(LinearGradient(
                                colors: [
                                    Color(hex: "#00B4D8"),
                                    Color(hex: "#0077B6")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                        )
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(MotionToken.microAnimation, value: isSelected)
                    
                    Text(displayText)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color(hex: "#00B4D8"),
                                Color(hex: "#0077B6")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#00B4D8"),
                                    Color(hex: "#90E0EF")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isSelected ? Color(hex: "#00B4D8").opacity(0.3) : .clear,
                radius: 10,
                y: 5
            )
            .animation(MotionToken.microAnimation, value: isPressed)
            .animation(MotionToken.standardSpring, value: isSelected)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// A view to display hydration tips.
struct HydrationTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false
    
    private let tips = [
        ("Start Early", "Drink a glass of water when you wake up.", "sunrise.fill"),
        ("Flavor It Up", "Add lemon, cucumber, or berries to your water.", "leaf.fill"),
        ("Eat Water-Rich Foods", "Fruits like watermelon and vegetables like cucumber contribute to hydration.", "carrot.fill"),
        ("Set Reminders", "Use app notifications or alarms to remind yourself to drink.", "bell.fill"),
        ("Before Meals", "Drink a glass of water before each meal.", "fork.knife"),
        ("Track Your Intake", "Use this app to monitor your progress!", "chart.line.uptrend.xyaxis"),
        ("Listen to Your Body", "Drink when you feel thirsty, and check urine color (pale yellow is good).", "figure.walk")
    ]
    
    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        CascadeText("💧 Hydration Tips")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .padding(.top, AppSpacing.md)
                            .padding(.horizontal, AppSpacing.md)
                        
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(Array(tips.enumerated()), id: \.element.0) { index, tip in
                                GlassCard {
                                    HStack(spacing: AppSpacing.md) {
                                        Image(systemName: tip.2)
                                            .font(.system(size: 24))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: "#00B4D8"),
                                                        Color(hex: "#0077B6")
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 32)
                                        
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text(tip.0)
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundStyle(Color.primary)
                                            
                                            Text(tip.1)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(AppSpacing.md)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(Double(index) * 0.1), value: animateIn)
                            }
                        }
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { 
                        HapticService.impact(.light)
                        dismiss() 
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }
}


// MARK: - Previews
#Preview("Hydration Tips Sheet") {
    HydrationTipsView()
}

#if DEBUG
// Using preview services from PhotoInputView.swift to avoid duplicates
#endif
