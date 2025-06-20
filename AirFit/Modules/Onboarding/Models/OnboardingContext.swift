import Foundation
import SwiftUI

// MARK: - OnboardingContext
/// Single source of truth for all onboarding data with intelligent prompts
@MainActor
final class OnboardingContext: ObservableObject {
    // MARK: - Published Data
    @Published var healthData: HealthKitSnapshot?
    @Published var lifeContext: String = ""
    @Published var weight: WeightObjective?
    @Published var bodyGoals: Set<BodyRecompositionGoal> = []
    @Published var functionalGoals: String = ""
    @Published var communicationStyles: Set<CommunicationStyle> = []
    @Published var informationPreferences: Set<InformationStyle> = []
    
    // MARK: - Intelligent Prompts Based on Data
    
    /// Activity-aware prompt for life context
    var activityPrompt: String {
        guard let metrics = healthData?.activityMetrics else {
            return "What's your day like? Work, family, whatever shapes your routine..."
        }
        
        // Let the context speak for itself based on actual metrics
        if metrics.averageDailySteps > 12000 {
            return "Wow, you're crushing it with \(Int(metrics.averageDailySteps)) steps daily! What's your secret?"
        } else if metrics.weeklyWorkoutCount >= 5 {
            return "I see you work out \(metrics.weeklyWorkoutCount) times a week - tell me about your routine"
        } else if metrics.weeklyExerciseMinutes > 150 {
            return "You're getting solid exercise time in - what keeps you moving?"
        } else if metrics.averageDailySteps < 3000 {
            return "I noticed you're not moving much lately. What's your work situation like?"
        } else {
            return "Tell me about your typical day - work, family, whatever shapes your routine"
        }
    }
    
    /// Weight-aware prompt for goals
    var weightGoalPrompt: String {
        guard let currentWeight = healthData?.weight else {
            return "What are your weight goals?"
        }
        
        let weight = Int(currentWeight)
        
        if currentWeight > 200 {
            return "I see you're at \(weight) lbs. Where would you like to be?"
        } else if currentWeight < 130 {
            return "At \(weight) lbs, are you looking to maintain or change?"
        } else {
            return "Current weight: \(weight) lbs. What's your goal?"
        }
    }
    
    /// Goal placeholder based on health data
    var goalPlaceholder: String {
        if let healthData = healthData {
            // Calculate BMI if we have weight and height
            if let weight = healthData.weight {
                if weight > 200 {
                    return "I want to lose weight and feel healthier..."
                } else if let metrics = healthData.activityMetrics, metrics.averageDailySteps < 3000 {
                    return "I want to get more active and build strength..."
                }
            }
            
            // Check sleep patterns
            if healthData.sleepSchedule == nil {
                return "I want more energy and better sleep..."
            }
        }
        return "I want to take my fitness to the next level..."
    }
    
    /// Smart communication style suggestions
    var suggestedCommunicationStyles: Set<CommunicationStyle> {
        var styles: Set<CommunicationStyle> = []
        
        // If weight loss goal, suggest encouraging
        if let weight = weight, weight.direction == .lose {
            styles.insert(.encouraging)
            styles.insert(.patient)
        }
        
        // If very active, suggest challenging
        if let metrics = healthData?.activityMetrics, 
           (metrics.averageDailySteps > 10000 || metrics.weeklyWorkoutCount >= 4) {
            styles.insert(.challenging)
            styles.insert(.analytical)
        }
        
        // If sedentary, suggest motivational
        if let metrics = healthData?.activityMetrics,
           metrics.averageDailySteps < 3000 && metrics.weeklyExerciseMinutes < 60 {
            styles.insert(.motivational)
            styles.insert(.educational)
        }
        
        // If building muscle, suggest direct
        if bodyGoals.contains(.gainMuscle) {
            styles.insert(.direct)
        }
        
        return styles
    }
    
    /// Information preference suggestions based on goals
    var suggestedInformationPreferences: Set<InformationStyle> {
        var prefs: Set<InformationStyle> = []
        
        // If analytical communication style, suggest detailed info
        if communicationStyles.contains(.analytical) {
            prefs.insert(.detailed)
            prefs.insert(.inDepthAnalysis)
        }
        
        // If weight loss, suggest progress celebrations
        if weight?.direction == .lose {
            prefs.insert(.celebrations)
            prefs.insert(.keyMetrics)
        }
        
        // If educational style, suggest educational content
        if communicationStyles.contains(.educational) {
            prefs.insert(.educational)
        }
        
        return prefs
    }
    
    /// Encouragement message for weight goals
    func weightEncouragement(current: Double, target: Double) -> String {
        let difference = abs(current - target)
        let pounds = Int(difference)
        
        if current > target {
            // Weight loss
            if pounds > 50 {
                return "A transformative \(pounds) lb journey - I'll be with you every step!"
            } else if pounds > 20 {
                return "A solid \(pounds) lb goal - totally achievable with the right approach!"
            } else {
                return "Just \(pounds) lbs - we'll get there together!"
            }
        } else if current < target {
            // Weight gain
            if pounds > 20 {
                return "Building \(pounds) lbs of healthy weight - let's do this right!"
            } else {
                return "Adding \(pounds) lbs - we'll focus on quality gains!"
            }
        } else {
            return "Maintaining your current weight - let's optimize your body composition!"
        }
    }
    
    /// Check if goals might conflict
    func hasConflictingGoals() -> Bool {
        // Aggressive weight loss + muscle gain can conflict
        if let weight = weight, weight.direction == .lose {
            if let target = weight.targetWeight, let current = weight.currentWeight {
                let weeklyLoss = (current - target) / 12 // Assume 12 week goal
                if weeklyLoss > 2 && bodyGoals.contains(.gainMuscle) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Generate conflict warning message
    var goalConflictMessage: String? {
        guard hasConflictingGoals() else { return nil }
        
        return "Building muscle while losing weight requires a careful approach - I'll help balance both goals!"
    }
    
    // MARK: - Helper Methods
    
    private func formatSteps() -> String {
        // Use actual step count if available
        if let steps = healthData?.activityMetrics?.averageDailySteps {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: steps)) ?? "\(Int(steps))"
        }
        return "your"
    }
    
    /// Build complete context for LLM synthesis
    func buildSynthesisContext() -> OnboardingRawData {
        OnboardingRawData(
            userName: "", // Add if collected
            lifeContextText: lifeContext,
            weightObjective: weight,
            bodyRecompositionGoals: Array(bodyGoals),
            functionalGoalsText: functionalGoals,
            communicationStyles: Array(communicationStyles),
            informationPreferences: Array(informationPreferences),
            healthKitData: healthData,
            manualHealthData: nil
        )
    }
}

// MARK: - Integration with OnboardingViewModel
extension OnboardingViewModel {
    /// Create context from current state
    func createContext() -> OnboardingContext {
        let context = OnboardingContext()
        
        // Populate with current data
        context.healthData = self.healthKitData
        context.lifeContext = self.lifeContext
        context.weight = WeightObjective(
            currentWeight: self.currentWeight,
            targetWeight: self.targetWeight,
            timeframe: nil
        )
        context.bodyGoals = Set(self.bodyRecompositionGoals)
        context.functionalGoals = self.functionalGoalsText
        context.communicationStyles = Set(self.communicationStyles)
        context.informationPreferences = Set(self.informationPreferences)
        
        return context
    }
}