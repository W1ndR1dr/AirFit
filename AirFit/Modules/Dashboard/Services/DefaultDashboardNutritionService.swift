import Foundation
import SwiftData

/// Default implementation of DashboardNutritionServiceProtocol
actor DefaultDashboardNutritionService: DashboardNutritionServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getTodaysSummary(for user: User) async throws -> NutritionSummary {
        // Fetch today's food entries
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = #Predicate<FoodEntry> { entry in
            entry.user?.id == user.id &&
            entry.loggedAt >= startOfDay &&
            entry.loggedAt < endOfDay
        }
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt)]
        )
        
        let entries = try modelContext.fetch(descriptor)
        
        // Calculate totals
        var calories = 0.0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber = 0.0
        var water = 0.0
        
        for entry in entries {
            if let nutrition = entry.nutritionData {
                calories += nutrition.calories
                protein += nutrition.protein
                carbs += nutrition.carbohydrates
                fat += nutrition.fat
                fiber += nutrition.fiber ?? 0
            }
            
            // Check if this is a water entry
            if entry.name.lowercased().contains("water") {
                water += entry.quantity * 8 // Assume 8 oz per unit for water
            }
        }
        
        // Get targets
        let targets = try await getTargets(from: user.onboardingProfile!)
        
        return NutritionSummary(
            calories: calories,
            caloriesTarget: targets.calories,
            protein: protein,
            proteinTarget: targets.protein,
            carbs: carbs,
            carbsTarget: targets.carbs,
            fat: fat,
            fatTarget: targets.fat,
            fiber: fiber,
            fiberTarget: targets.fiber,
            water: water,
            waterTarget: targets.water,
            mealCount: entries.filter { $0.mealType != nil }.count
        )
    }
    
    func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {
        // Calculate nutrition targets based on profile
        let userProfile = profile.formData ?? UserProfileJsonBlob()
        
        // Base calorie calculation
        var baseCalories = 2000.0 // Default
        
        // Adjust based on sex
        if userProfile.biologicalSex == .male {
            baseCalories = 2500.0
        } else if userProfile.biologicalSex == .female {
            baseCalories = 2000.0
        }
        
        // Adjust based on activity level
        switch userProfile.activityLevel {
        case .sedentary:
            baseCalories *= 0.9
        case .lightlyActive:
            baseCalories *= 1.0
        case .moderatelyActive:
            baseCalories *= 1.1
        case .veryActive:
            baseCalories *= 1.2
        case .extremelyActive:
            baseCalories *= 1.3
        case .none:
            break
        }
        
        // Adjust based on goals
        switch userProfile.goals.first {
        case .loseWeight:
            baseCalories *= 0.85 // 15% deficit
        case .buildMuscle:
            baseCalories *= 1.1 // 10% surplus
        case .maintainWeight, .improveHealth, .increaseEndurance, .buildStrength:
            break // No adjustment
        case .none:
            break
        }
        
        // Calculate macros (default balanced approach)
        let proteinCalories = baseCalories * 0.30
        let carbCalories = baseCalories * 0.40
        let fatCalories = baseCalories * 0.30
        
        return NutritionTargets(
            calories: baseCalories,
            protein: proteinCalories / 4, // 4 cal per gram
            carbs: carbCalories / 4, // 4 cal per gram
            fat: fatCalories / 9, // 9 cal per gram
            fiber: 25.0, // Default recommendation
            water: 64.0 // 8 cups default
        )
    }
}