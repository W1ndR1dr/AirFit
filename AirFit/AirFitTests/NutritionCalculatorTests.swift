import XCTest
@testable import AirFit

final class NutritionCalculatorTests: XCTestCase {
    @MainActor
    func testCalculateBMR_WithBodyFat_UsesKatchMcArdle() async throws {
        let fake = HealthKitManagerFake()
        let calc = NutritionCalculator(healthKit: fake)
        let bmr = calc.calculateBMR(
            weight: 80,   // kg
            height: 180,  // cm
            bodyFat: 20,  // %
            age: 30,
            biologicalSex: "male"
        )
        XCTAssertGreaterThan(bmr, 1600)
        XCTAssertLessThan(bmr, 2200)
    }

    @MainActor
    func testCalculateBMR_WithHeight_UsesMifflinStJeor() async throws {
        let fake = HealthKitManagerFake()
        let calc = NutritionCalculator(healthKit: fake)
        let bmr = calc.calculateBMR(
            weight: 70,
            height: 175,
            bodyFat: nil,
            age: 28,
            biologicalSex: "female"
        )
        XCTAssertGreaterThan(bmr, 1200)
        XCTAssertLessThan(bmr, 2000)
    }

    @MainActor
    func testCalculateDynamicTargets_ProducesConsistentTotals() async throws {
        let fake = HealthKitManagerFake()
        fake.authorizationStatus = .authorized
        fake.stubBody = BodyMetrics(
            weight: Measurement(value: 75, unit: UnitMass.kilograms),
            height: Measurement(value: 170, unit: UnitLength.centimeters),
            bodyFatPercentage: 15,
            leanBodyMass: nil,
            bmi: nil
        )
        fake.stubActivity = ActivityMetrics(
            activeEnergyBurned: Measurement(value: 400, unit: UnitEnergy.kilocalories),
            basalEnergyBurned: nil,
            steps: 9000,
            distance: nil,
            flightsClimbed: nil,
            exerciseMinutes: 30,
            standHours: 10,
            moveMinutes: 60,
            currentHeartRate: 70,
            isWorkoutActive: false,
            workoutTypeRawValue: nil,
            moveProgress: 0.7,
            exerciseProgress: 0.6,
            standProgress: 0.8
        )

        let calc = NutritionCalculator(healthKit: fake)
        try await calc.configure()

        let user = User(
            email: nil,
            name: "Test",
            preferredUnits: "imperial",
            biologicalSex: "male",
            birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date())
        )
        // Make macros more deterministic
        user.proteinGramsPerPound = 1.0
        user.fatPercentage = 0.3

        let targets = try await calc.calculateDynamicTargets(for: user)
        // Totals should be at least base and include active calories
        XCTAssertGreaterThan(targets.totalCalories, targets.baseCalories)
        XCTAssertEqual(Int(targets.baseCalories + targets.activeCalorieBonus), Int(targets.totalCalories))

        // Sanity check macro calories won't exceed total grossly
        let macroCalories = targets.protein * 4 + targets.carbs * 4 + targets.fat * 9
        XCTAssertLessThanOrEqual(macroCalories, targets.totalCalories * 1.1)
    }
}
