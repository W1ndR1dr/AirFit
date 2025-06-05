import Foundation
import SwiftData

/// Implementation of DashboardNutritionServiceProtocol
@MainActor
final class DashboardNutritionService: DashboardNutritionServiceProtocol, @unchecked Sendable {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getTodaysSummary(for user: User) async throws -> NutritionSummary {
        // Fetch today's food entries
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let userID = user.id
        let predicate = #Predicate<FoodEntry> { entry in
            if let entryUser = entry.user {
                return entryUser.id == userID &&
                       entry.loggedAt >= startOfDay &&
                       entry.loggedAt < endOfDay
            } else {
                return false
            }
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
            calories += Double(entry.totalCalories)
            protein += entry.totalProtein
            carbs += entry.totalCarbs
            fat += entry.totalFat
            
            // Check for water entries in food items
            for item in entry.items {
                if item.name.lowercased().contains("water") {
                    water += (item.quantity ?? 1.0) * 8 // Assume 8 oz per unit for water
                }
                fiber += item.fiberGrams ?? 0
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
        let userProfile: UserProfileJsonBlob
        do {
            userProfile = try JSONDecoder().decode(UserProfileJsonBlob.self, from: profile.rawFullProfileData)
        } catch {
            // Use default profile if decoding fails
            return NutritionTargets.default
        }
        
        // Base calorie calculation
        var baseCalories = 2000.0 // Default
        
        // Use default calories for now - biologicalSex not in LifeContext
        // TODO: Add biologicalSex to LifeContext or UserProfile if needed
        baseCalories = 2200.0 // Average between typical male/female values
        
        // Adjust based on physical activity
        if userProfile.lifeContext.isPhysicallyActiveWork {
            baseCalories *= 1.2
        }
        
        // Adjust based on goal family
        switch userProfile.goal.family {
        case .strengthTone:
            baseCalories *= 1.1 // 10% surplus for muscle building
        case .endurance:
            baseCalories *= 1.05 // 5% surplus for endurance training
        case .performance:
            baseCalories *= 1.05 // 5% surplus for performance
        case .healthWellbeing, .recoveryRehab:
            break // No adjustment - maintenance calories
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