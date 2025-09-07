//
//  NutritionLiveActivity.swift
//  AirFit
//
//  Created on 2025-09-06 for iPhone 16 Pro Dynamic Island integration
//  Nutrition tracking Live Activity with iOS 26 Liquid Glass effects
//

import ActivityKit
import SwiftUI

// MARK: - Nutrition Live Activity Widget

struct NutritionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NutritionActivityAttributes.self) { context in
            // Lock screen view with iOS 26 Liquid Glass effects
            NutritionLockScreenView(context: context)
                .glassEffect(.regular)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view when user long-presses the Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Calories progress
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Calories")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        
                        let caloriesProgress = Double(context.state.currentCalories) / context.attributes.dailyGoal.calories
                        ProgressView(value: caloriesProgress)
                            .progressViewStyle(.linear)
                            .scaleEffect(y: 0.6)
                            .frame(width: 60)
                        
                        Text("\(Int(caloriesProgress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        // Meals logged indicator
                        HStack(spacing: 4) {
                            Text("\(context.state.mealsLogged)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("meals")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Last meal time
                        if let lastMeal = context.state.lastMealTime {
                            Text("Last: \(lastMeal.formatted(.dateTime.hour().minute()))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        // Current calories vs goal
                        Text("\(context.state.currentCalories) / \(Int(context.attributes.dailyGoal.calories))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        // Macronutrient distribution
                        HStack(spacing: 12) {
                            MacroIndicator(
                                current: context.state.currentProtein,
                                target: context.attributes.dailyGoal.protein,
                                label: "P",
                                color: .blue
                            )
                            
                            MacroIndicator(
                                current: context.state.currentCarbs,
                                target: context.attributes.dailyGoal.carbs,
                                label: "C",
                                color: .green
                            )
                            
                            MacroIndicator(
                                current: context.state.currentFat,
                                target: context.attributes.dailyGoal.fat,
                                label: "F",
                                color: .purple
                            )
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        // Status indicator
                        if context.state.isComplete {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 14))
                                Text("Goal reached")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            let remaining = Int(context.attributes.dailyGoal.calories) - context.state.currentCalories
                            Text("\(remaining) cal remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Quick action button
                        Button(intent: LogMealIntent()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.thin)
                        .frame(width: 32, height: 32)
                        .background(.regularMaterial, in: Circle())
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                // Compact left side - Calories flame icon
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.bounce, value: context.state.currentCalories)
            } compactTrailing: {
                // Compact right side - Calories and progress
                VStack(spacing: 1) {
                    Text("\(context.state.currentCalories)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    let progress = Double(context.state.currentCalories) / context.attributes.dailyGoal.calories
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } minimal: {
                // Minimal view - Just the nutrition icon
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14, weight: .medium))
                    .symbolEffect(.pulse, isActive: !context.state.isComplete)
            }
        }
    }
}

// MARK: - Lock Screen View

struct NutritionLockScreenView: View {
    let context: ActivityViewContext<NutritionActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with nutrition tracking
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Nutrition")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let lastMeal = context.state.lastMealTime {
                        Text("Last meal: \(lastMeal.formatted(.dateTime.hour().minute()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(context.state.currentCalories) / \(Int(context.attributes.dailyGoal.calories))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                    
                    let progress = Double(context.state.currentCalories) / context.attributes.dailyGoal.calories
                    if context.state.isComplete {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("Complete")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                    } else {
                        Text("\(Int(progress * 100))% of goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Macronutrient breakdown
            HStack(spacing: 24) {
                MacroProgressView(
                    current: context.state.currentProtein,
                    target: context.attributes.dailyGoal.protein,
                    label: "Protein",
                    unit: "g",
                    color: .blue
                )
                
                MacroProgressView(
                    current: context.state.currentCarbs,
                    target: context.attributes.dailyGoal.carbs,
                    label: "Carbs",
                    unit: "g",
                    color: .green
                )
                
                MacroProgressView(
                    current: context.state.currentFat,
                    target: context.attributes.dailyGoal.fat,
                    label: "Fat",
                    unit: "g",
                    color: .purple
                )
            }
            
            // Progress bar for overall calories
            VStack(spacing: 4) {
                HStack {
                    Text("Calorie Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(context.state.mealsLogged) meals logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                let progress = Double(context.state.currentCalories) / context.attributes.dailyGoal.calories
                ProgressView(value: min(1.0, progress))
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(16)
    }
}

// MARK: - Helper Views

struct MacroIndicator: View {
    let current: Double
    let target: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color)
            
            Text("\(Int(current))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            let progress = current / target
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(color, lineWidth: 2)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct MacroProgressView: View {
    let current: Double
    let target: Double
    let label: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(Int(current))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("of \(Int(target))\(unit)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            let progress = current / target
            ProgressView(value: min(1.0, progress))
                .progressViewStyle(.linear)
                .tint(color)
                .scaleEffect(y: 0.6)
                .frame(width: 40)
        }
    }
}

// MARK: - App Intent

struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    
    func perform() async throws -> some IntentResult {
        // Send notification to open meal logging
        NotificationCenter.default.post(name: .openMealLogging, object: nil)
        return .result()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let openMealLogging = Notification.Name("openMealLogging")
}