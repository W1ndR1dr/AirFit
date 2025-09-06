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
    let mealCount: Int
    let meals: [FoodEntry]

    init(
        calories: Double = 0,
        caloriesTarget: Double = 2_000,
        protein: Double = 0,
        proteinTarget: Double = 150,
        carbs: Double = 0,
        carbsTarget: Double = 250,
        fat: Double = 0,
        fatTarget: Double = 65,
        fiber: Double = 0,
        fiberTarget: Double = 25,
        mealCount: Int = 0,
        meals: [FoodEntry] = []
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
        self.mealCount = mealCount
        self.meals = meals
    }
}

// MARK: - Nutrition Targets
struct NutritionTargets: Sendable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double

    static let `default` = NutritionTargets(
        calories: 2_000,
        protein: 150,
        carbs: 250,
        fat: 65,
        fiber: 25
    )
}

// MARK: - Greeting Context
struct GreetingContext: Sendable {
    let userName: String
    let sleepHours: Double?
    let sleepQuality: String?
    let weather: String?
    let temperature: Double?
    let todaysSchedule: String?
    let energyYesterday: String?
    let dayOfWeek: String
    let recentAchievements: [String]

    init(
        userName: String = "",
        sleepHours: Double? = nil,
        sleepQuality: String? = nil,
        weather: String? = nil,
        temperature: Double? = nil,
        todaysSchedule: String? = nil,
        energyYesterday: String? = nil,
        dayOfWeek: String = "",
        recentAchievements: [String] = []
    ) {
        self.userName = userName
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.weather = weather
        self.temperature = temperature
        self.todaysSchedule = todaysSchedule
        self.energyYesterday = energyYesterday
        self.dayOfWeek = dayOfWeek
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
public struct QuickAction: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let systemImage: String
    public let color: String
    public let action: QuickActionType

    public enum QuickActionType: Sendable, Equatable, Hashable {
        case logMeal(type: MealType)
        case logMealWithPhoto(type: MealType)
        case startWorkout
        case checkIn
    }

    public init(title: String, subtitle: String, systemImage: String, color: String, action: QuickActionType) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.action = action
    }
}
