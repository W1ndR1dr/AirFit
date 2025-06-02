import Foundation

// MARK: - Nutrition Summary
struct NutritionSummary: Sendable {
    let calories: Double
    let caloriesTarget: Double
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double
    let fiber: Double
    let fiberTarget: Double
    let water: Double
    let waterTarget: Double
    let mealCount: Int
    
    init(
        calories: Double = 0,
        caloriesTarget: Double = 2000,
        protein: Double = 0,
        proteinTarget: Double = 150,
        carbs: Double = 0,
        carbsTarget: Double = 250,
        fat: Double = 0,
        fatTarget: Double = 65,
        fiber: Double = 0,
        fiberTarget: Double = 25,
        water: Double = 0,
        waterTarget: Double = 64,
        mealCount: Int = 0
    ) {
        self.calories = calories
        self.caloriesTarget = caloriesTarget
        self.protein = protein
        self.proteinTarget = proteinTarget
        self.carbs = carbs
        self.carbsTarget = carbsTarget
        self.fat = fat
        self.fatTarget = fatTarget
        self.fiber = fiber
        self.fiberTarget = fiberTarget
        self.water = water
        self.waterTarget = waterTarget
        self.mealCount = mealCount
    }
}

// MARK: - Nutrition Targets
struct NutritionTargets: Sendable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let water: Double
    
    static let `default` = NutritionTargets(
        calories: 2000,
        protein: 150,
        carbs: 250,
        fat: 65,
        fiber: 25,
        water: 64
    )
}

// MARK: - Greeting Context
struct GreetingContext: Sendable {
    let sleepHours: Double?
    let weather: String?
    let todaysSchedule: String?
    let recentAchievements: [String]
    
    init(
        sleepHours: Double? = nil,
        weather: String? = nil,
        todaysSchedule: String? = nil,
        recentAchievements: [String] = []
    ) {
        self.sleepHours = sleepHours
        self.weather = weather
        self.todaysSchedule = todaysSchedule
        self.recentAchievements = recentAchievements
    }
}

// MARK: - Recovery Score
struct RecoveryScore: Sendable {
    enum Status: String, Sendable {
        case poor = "Poor"
        case moderate = "Moderate"
        case good = "Good"
        
        var color: String {
            switch self {
            case .poor: return "red"
            case .moderate: return "yellow"
            case .good: return "green"
            }
        }
    }
    
    let score: Int
    let status: Status
    let factors: [String]
}

// MARK: - Performance Insight
struct PerformanceInsight: Sendable {
    enum Trend: String, Sendable {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Declining"
        
        var systemImage: String {
            switch self {
            case .improving: return "arrow.up.circle.fill"
            case .stable: return "minus.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            }
        }
    }
    
    let trend: Trend
    let metric: String
    let value: String
    let insight: String
}

// MARK: - Quick Action
struct QuickAction: Sendable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let color: String
    let action: QuickActionType
    
    enum QuickActionType: Sendable {
        case logMeal
        case startWorkout
        case logWater
        case checkIn
    }
}