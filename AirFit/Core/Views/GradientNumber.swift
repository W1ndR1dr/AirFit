import SwiftUI

/// Displays large numbers with gradient masking for visual cohesion
/// Automatically uses the active gradient from GradientManager
struct GradientNumber: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    let value: Double
    let format: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let animation: Bool
    
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        format: String = "%.0f",
        fontSize: CGFloat = 48,
        fontWeight: Font.Weight = .bold,
        animation: Bool = true
    ) {
        self.value = value
        self.format = format
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.animation = animation
    }
    
    var body: some View {
        Text(String(format: format, displayValue))
            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
            .foregroundStyle(
                gradientManager.currentGradient(for: colorScheme)
            )
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                if animation {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        displayValue = value
                    }
                } else {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                if animation {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        displayValue = newValue
                    }
                } else {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Gradient Number with Unit

struct GradientNumberWithUnit: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    let value: Double
    let unit: String
    let format: String
    let numberSize: CGFloat
    let unitSize: CGFloat
    
    init(
        value: Double,
        unit: String,
        format: String = "%.0f",
        numberSize: CGFloat = 48,
        unitSize: CGFloat = 24
    ) {
        self.value = value
        self.unit = unit
        self.format = format
        self.numberSize = numberSize
        self.unitSize = unitSize
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            GradientNumber(
                value: value,
                format: format,
                fontSize: numberSize
            )
            
            Text(unit)
                .font(.system(size: unitSize, weight: .medium, design: .rounded))
                .foregroundStyle(
                    gradientManager.currentGradient(for: colorScheme)
                        .opacity(0.7)
                )
        }
    }
}

// MARK: - Animated Number Counter

struct AnimatedNumberCounter: View {
    let from: Double
    let to: Double
    let duration: Double
    let format: String
    let fontSize: CGFloat
    
    @State private var value: Double = 0
    
    init(
        from: Double = 0,
        to: Double,
        duration: Double = 1.0,
        format: String = "%.0f",
        fontSize: CGFloat = 48
    ) {
        self.from = from
        self.to = to
        self.duration = duration
        self.format = format
        self.fontSize = fontSize
    }
    
    var body: some View {
        GradientNumber(
            value: value,
            format: format,
            fontSize: fontSize,
            animation: false
        )
        .onAppear {
            value = from
            withAnimation(.easeInOut(duration: duration)) {
                value = to
            }
        }
    }
}