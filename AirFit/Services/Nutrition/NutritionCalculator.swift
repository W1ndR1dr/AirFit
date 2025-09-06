import Foundation

/// Service for calculating dynamic nutrition targets based on body metrics and activity levels
actor NutritionCalculator: NutritionCalculatorProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "nutrition-calculator"
    private var _isConfigured = false

    nonisolated var isConfigured: Bool {
        // For actors, return true as services are ready when created
        true
    }

    // MARK: - Properties
    private let healthKit: HealthKitManaging

    // MARK: - Initialization
    init(healthKit: HealthKitManaging) {
        self.healthKit = healthKit
    }

    // MARK: - ServiceProtocol Methods
    func configure() async throws {
        guard !_isConfigured else { return }

        // Verify HealthKit authorization
        guard await healthKit.authorizationStatus == .authorized else {
            throw AppError.healthKitNotAuthorized
        }

        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["hasHealthKit": "true"]
        )
    }

    // MARK: - NutritionCalculatorProtocol Methods
    func calculateDynamicTargets(for user: User) async throws -> DynamicNutritionTargets {
        // Fetch body metrics from HealthKit
        async let bodyMetrics = healthKit.fetchLatestBodyMetrics()
        async let activityMetrics = healthKit.fetchTodayActivityMetrics()

        let (body, activity) = try await (bodyMetrics, activityMetrics)

        // Extract weight (required for calculation)
        guard let weightKg = body.weight?.value else {
            AppLogger.warning("No weight data available for nutrition calculation", category: .meals)
            throw AppError.validationError(message: "Weight required for nutrition calculations. Please add your weight in the Health app.")
        }

        // Calculate BMR
        let bmr = calculateBMR(
            weight: weightKg,
            height: body.height?.value, // Height in centimeters from HealthKit
            bodyFat: body.bodyFatPercentage,
            age: user.age ?? 30, // Default to 30 if age unknown
            biologicalSex: user.biologicalSex
        )

        // Calculate targets
        let baseCalories = bmr * 1.2 // Sedentary multiplier
        let activeBonus = activity.activeEnergyBurned?.value ?? 0
        let totalCalories = baseCalories + activeBonus

        // Convert weight to pounds for protein calculation
        let weightLbs = weightKg * 2.20462

        // Use personalized macro ratios from user preferences (set by AI or user)
        let proteinGrams = weightLbs * user.proteinGramsPerPound

        // Calculate fat based on user's preference
        let fatCalories = totalCalories * user.fatPercentage
        let fatGrams = fatCalories / 9 // 9 calories per gram of fat

        // Remaining calories go to carbs
        let proteinCalories = proteinGrams * 4
        let remainingCalories = totalCalories - proteinCalories - fatCalories
        let carbGrams = max(0, remainingCalories / 4) // 4 calories per gram of carbs

        return DynamicNutritionTargets(
            baseCalories: baseCalories,
            activeCalorieBonus: activeBonus,
            totalCalories: totalCalories,
            protein: proteinGrams,
            carbs: carbGrams,
            fat: fatGrams
        )
    }

    nonisolated func calculateBMR(
        weight: Double?,
        height: Double?,
        bodyFat: Double?,
        age: Int,
        biologicalSex: String?
    ) -> Double {
        // Validate we have minimum data
        guard let weight = weight else {
            // No weight = use population average
            AppLogger.warning("No weight for BMR calculation, using default", category: .meals)
            return 1_800 // Safe default
        }

        let weightKg = weight

        // Try Katch-McArdle first (most accurate with body fat)
        if let bodyFat = bodyFat, bodyFat > 0 {
            let leanMassKg = weightKg * (1 - bodyFat / 100)
            let bmr = 370 + (21.6 * leanMassKg)
            AppLogger.debug("BMR calculated using Katch-McArdle: \(bmr)", category: .meals)
            return bmr
        }

        // Try Mifflin-St Jeor (needs height)
        if let height = height, height > 0 {
            let heightCm = height
            let sexFactor = (biologicalSex == "male") ? 5.0 : -161.0
            let bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + sexFactor
            AppLogger.debug("BMR calculated using Mifflin-St Jeor: \(bmr)", category: .meals)
            return bmr
        }

        // Fallback: Modified Harris-Benedict (assume average height)
        let assumedHeight: Double = (biologicalSex == "male") ? 178.0 : 165.0
        let bmr: Double

        if biologicalSex == "male" {
            bmr = 88.362 + (13.397 * weightKg) + (4.799 * assumedHeight) - (5.677 * Double(age))
        } else {
            // Use female formula as safer default (lower BMR)
            bmr = 447.593 + (9.247 * weightKg) + (3.098 * assumedHeight) - (4.330 * Double(age))
        }

        AppLogger.debug("BMR calculated using Harris-Benedict with assumed height: \(bmr)", category: .meals)
        return bmr
    }
}
