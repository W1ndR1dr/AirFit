import SwiftUI

struct VoiceVisualizer: View {
    let isRecording: Bool
    let audioLevel: Float
    
    @State private var phase: CGFloat = 0
    
    private let barCount = 20
    private let baseHeight: CGFloat = 20
    private let maxAmplitude: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: geometry.size.width / CGFloat(barCount * 3)) {
                ForEach(0..<barCount, id: \.self) { index in
                    VoiceBar(
                        index: index,
                        totalBars: barCount,
                        audioLevel: audioLevel,
                        phase: phase,
                        isRecording: isRecording,
                        baseHeight: baseHeight,
                        maxAmplitude: maxAmplitude
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct VoiceBar: View {
    let index: Int
    let totalBars: Int
    let audioLevel: Float
    let phase: CGFloat
    let isRecording: Bool
    let baseHeight: CGFloat
    let maxAmplitude: CGFloat
    
    private var height: CGFloat {
        guard isRecording else { return baseHeight }
        
        let normalizedIndex = CGFloat(index) / CGFloat(totalBars)
        let waveOffset = sin(normalizedIndex * .pi * 2 + phase) * 0.5 + 0.5
        let audioBoost = CGFloat(audioLevel) * maxAmplitude
        
        return baseHeight + (waveOffset * audioBoost)
    }
    
    private var color: Color {
        if !isRecording {
            return Color.gray.opacity(0.3)
        }
        
        let intensity = height / (baseHeight + maxAmplitude)
        return Color.accentColor.opacity(0.3 + intensity * 0.7)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: height)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: height)
    }
}