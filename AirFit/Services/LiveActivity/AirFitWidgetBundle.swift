//
//  AirFitWidgetBundle.swift
//  AirFit
//
//  Created on 2025-09-06 for iPhone 16 Pro Dynamic Island integration
//  Widget Bundle containing all AirFit Live Activities
//

import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct AirFitWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Workout tracking Live Activity
        AirFitLiveActivity()
        
        // Nutrition tracking Live Activity  
        NutritionLiveActivity()
        
        // AI Coach session Live Activity
        CoachLiveActivity()
    }
}

// MARK: - iOS 26 Extension Methods

extension View {
    /// Applies iOS 26 Liquid Glass effect to views
    /// Available glass effect styles: .thin, .regular, .thick, .ultraThin
    func glassEffect(_ style: GlassEffectStyle = .regular, in shape: any Shape = RoundedRectangle(cornerRadius: 12)) -> some View {
        self.background(.ultraThinMaterial, in: AnyShape(shape))
            .overlay(
                AnyShape(shape)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: style.borderWidth
                    )
            )
            .shadow(
                color: .black.opacity(0.1),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowOffset
            )
    }
}

// MARK: - Glass Effect Styles

enum GlassEffectStyle {
    case ultraThin
    case thin
    case regular
    case thick
    
    var borderWidth: CGFloat {
        switch self {
        case .ultraThin: return 0.5
        case .thin: return 0.8
        case .regular: return 1.0
        case .thick: return 1.5
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .ultraThin: return 2
        case .thin: return 4
        case .regular: return 6
        case .thick: return 8
        }
    }
    
    var shadowOffset: CGFloat {
        switch self {
        case .ultraThin: return 1
        case .thin: return 2
        case .regular: return 3
        case .thick: return 4
        }
    }
}

// MARK: - Shape Type Erasure

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - iOS 26 Capsule Extension

extension View {
    func glassEffect(in shape: any Shape) -> some View {
        self.glassEffect(.regular, in: shape)
    }
}

extension Shape where Self == Capsule {
    static var capsule: Capsule { Capsule() }
}

// MARK: - Motion Tokens for Consistent Animations

struct WidgetMotionToken {
    static let standardSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let gentleSpring = Animation.spring(response: 0.7, dampingFraction: 0.9, blendDuration: 0)
    static let snappySpring = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
}

// MARK: - Preview Support

#if DEBUG
struct AirFitWidgetBundle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Workout Live Activity Preview
            AirFitLiveActivityPreview()
                .previewDisplayName("Workout Live Activity")
            
            // Nutrition Live Activity Preview
            NutritionLiveActivityPreview()
                .previewDisplayName("Nutrition Live Activity")
            
            // Coach Live Activity Preview
            CoachLiveActivityPreview()
                .previewDisplayName("Coach Live Activity")
        }
    }
}

// Preview helper views
struct AirFitLiveActivityPreview: View {
    var body: some View {
        VStack {
            Text("Workout Live Activity")
                .font(.headline)
            
            // Mock Dynamic Island expanded view
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.green)
                    Text("Running Workout")
                        .font(.headline)
                    Spacer()
                    Text("450 cal")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: 0.7)
                    .progressViewStyle(.linear)
            }
            .padding()
            .glassEffect()
        }
    }
}

struct NutritionLiveActivityPreview: View {
    var body: some View {
        VStack {
            Text("Nutrition Live Activity")
                .font(.headline)
            
            // Mock Dynamic Island expanded view
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text("Daily Nutrition")
                        .font(.headline)
                    Spacer()
                    Text("1,450 / 2,000")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: 0.725)
                    .progressViewStyle(.linear)
            }
            .padding()
            .glassEffect()
        }
    }
}

struct CoachLiveActivityPreview: View {
    var body: some View {
        VStack {
            Text("AI Coach Live Activity")
                .font(.headline)
            
            // Mock Dynamic Island expanded view
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Workout Guidance")
                        .font(.headline)
                    Spacer()
                    Text("5 msgs")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Great form on those squats. Try to go a bit deeper on the next set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .glassEffect()
        }
    }
}
#endif