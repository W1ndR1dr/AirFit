import SwiftUI

struct ContextualSlider: View {
    let min: Double
    let max: Double
    let step: Double
    let labels: SliderLabels
    let onSubmit: (Double) -> Void
    
    @State private var value: Double
    @State private var isDragging = false
    
    init(min: Double, max: Double, step: Double, labels: SliderLabels, onSubmit: @escaping (Double) -> Void) {
        self.min = min
        self.max = max
        self.step = step
        self.labels = labels
        self.onSubmit = onSubmit
        
        // Initialize to center value
        let initialValue = (min + max) / 2
        self._value = State(initialValue: initialValue)
    }
    
    private var normalizedValue: Double {
        (value - min) / (max - min)
    }
    
    private var formattedValue: String {
        if step >= 1 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private var contextualLabel: String {
        let percentage = normalizedValue
        
        if percentage < 0.2 {
            return labels.min
        } else if percentage > 0.8 {
            return labels.max
        } else if let center = labels.center {
            return center
        } else {
            return formattedValue
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Current value display
            VStack(spacing: 8) {
                Text(contextualLabel)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if contextualLabel != formattedValue {
                    Text(formattedValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .animation(.spring(response: 0.3), value: value)
            
            // Slider
            VStack(spacing: 12) {
                // Custom slider track
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * normalizedValue, height: 8)
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 3)
                            )
                            .scaleEffect(isDragging ? 1.2 : 1.0)
                            .offset(x: geometry.size.width * normalizedValue - 14)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        isDragging = true
                                        let newValue = min + (gesture.location.x / geometry.size.width) * (max - min)
                                        value = round(newValue / step) * step
                                        value = Swift.min(Swift.max(value, min), max)
                                        HapticService.play(.toggle)
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                            )
                    }
                    .animation(.spring(response: 0.3), value: isDragging)
                }
                .frame(height: 28)
                
                // Labels
                HStack {
                    Text(labels.min)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let center = labels.center {
                        Text(center)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(labels.max)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Visual indicators
            HStack(spacing: 20) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(normalizedValue >= Double(index) / 4 ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 12, height: 12)
                }
            }
            
            // Submit button
            Button(action: { onSubmit(value) }) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}