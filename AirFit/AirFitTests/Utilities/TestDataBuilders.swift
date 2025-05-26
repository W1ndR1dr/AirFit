import Foundation
@testable import AirFit

// Builder for creating test data with Swift 6 features
@MainActor
final class UserProfileBuilder {
    private var age: Int = 30
    private var weight: Double = 70
    private var height: Double = 175
    private var biologicalSex: BiologicalSex = .male
    private var activityLevel: ActivityLevel = .moderate
    private var goal: FitnessGoal = .maintainWeight
    
    func with(age: Int) -> Self {
        self.age = age
        return self
    }
    
    func with(weight: Double) -> Self {
        self.weight = weight
        return self
    }
    
    func with(height: Double) -> Self {
        self.height = height
        return self
    }
    
    func with(biologicalSex: BiologicalSex) -> Self {
        self.biologicalSex = biologicalSex
        return self
    }
    
    func with(activityLevel: ActivityLevel) -> Self {
        self.activityLevel = activityLevel
        return self
    }
    
    func with(goal: FitnessGoal) -> Self {
        self.goal = goal
        return self
    }
    
    func build() -> UserProfile {
        UserProfile(
            age: age,
            weight: weight,
            height: height,
            biologicalSex: biologicalSex,
            activityLevel: activityLevel,
            goal: goal
        )
    }
}

@MainActor
final class MealBuilder {
    private var id: UUID = UUID()
    private var name: String = "Test Meal"
    private var calories: Double = 500
    private var protein: Double = 30
    private var carbs: Double = 50
    private var fat: Double = 20
    private var loggedAt: Date = Date()
    
    func with(name: String) -> Self {
        self.name = name
        return self
    }
    
    func with(calories: Double) -> Self {
        self.calories = calories
        return self
    }
    
    func with(macros protein: Double, carbs: Double, fat: Double) -> Self {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.calories = (protein * 4) + (carbs * 4) + (fat * 9)
        return self
    }
    
    func with(loggedAt: Date) -> Self {
        self.loggedAt = loggedAt
        return self
    }
    
    func build() -> Meal {
        Meal(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            loggedAt: loggedAt
        )
    }
}

@MainActor
final class WorkoutBuilder {
    private var id: UUID = UUID()
    private var type: WorkoutType = .strength
    private var duration: TimeInterval = 3600
    private var caloriesBurned: Double = 300
    private var startDate: Date = Date()
    private var exercises: [Exercise] = []
    
    func with(type: WorkoutType) -> Self {
        self.type = type
        return self
    }
    
    func with(duration: TimeInterval) -> Self {
        self.duration = duration
        return self
    }
    
    func with(caloriesBurned: Double) -> Self {
        self.caloriesBurned = caloriesBurned
        return self
    }
    
    func with(exercises: [Exercise]) -> Self {
        self.exercises = exercises
        return self
    }
    
    func build() -> Workout {
        Workout(
            id: id,
            type: type,
            duration: duration,
            caloriesBurned: caloriesBurned,
            startDate: startDate,
            exercises: exercises
        )
    }
} 