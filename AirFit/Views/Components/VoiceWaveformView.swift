import SwiftUI

// MARK: - Voice Waveform Visualization

/// Beautiful real-time waveform visualization that responds to microphone input
/// Inspired by Claude and ChatGPT voice interfaces - organic, breathing animation
struct VoiceWaveformView: View {
    /// Audio levels array from WhisperTranscriptionService (0.0 - 1.0)
    let audioLevels: [Float]

    /// Whether speech is currently being detected
    var isSpeechDetected: Bool = false

    /// Number of bars to display
    var barCount: Int = 24

    /// Minimum bar height
    var minHeight: CGFloat = 4

    /// Maximum bar height
    var maxHeight: CGFloat = 40

    /// Bar width
    var barWidth: CGFloat = 3

    /// Spacing between bars
    var spacing: CGFloat = 3

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        level: barLevel(for: index),
                        index: index,
                        time: time,
                        isSpeechDetected: isSpeechDetected,
                        minHeight: minHeight,
                        maxHeight: maxHeight,
                        barWidth: barWidth,
                        totalBars: barCount
                    )
                }
            }
        }
    }

    /// Get the audio level for a specific bar
    private func barLevel(for index: Int) -> Float {
        // Map bar index to audio levels array
        guard !audioLevels.isEmpty else { return 0 }

        // Sample from different parts of the audio levels array
        let normalizedIndex = Float(index) / Float(barCount)
        let levelsIndex = Int(normalizedIndex * Float(audioLevels.count - 1))
        let safeIndex = min(max(0, levelsIndex), audioLevels.count - 1)

        return audioLevels[safeIndex]
    }
}

// MARK: - Individual Waveform Bar

struct WaveformBar: View {
    let level: Float
    let index: Int
    let time: Double
    let isSpeechDetected: Bool
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let barWidth: CGFloat
    let totalBars: Int

    private var height: CGFloat {
        // Base height from audio level
        let audioHeight = CGFloat(level) * (maxHeight - minHeight)

        // Add ambient breathing animation when not speaking
        let breathingOffset: CGFloat
        if !isSpeechDetected {
            // Gentle sine wave for idle breathing
            let phase = time * 2.0 + Double(index) * 0.3
            breathingOffset = sin(phase) * 4 + 4
        } else {
            breathingOffset = 0
        }

        // Add slight wave motion for visual interest
        let waveOffset = sin(time * 3.0 + Double(index) * 0.5) * 2

        return max(minHeight, min(maxHeight, minHeight + audioHeight + breathingOffset + waveOffset))
    }

    private var barOpacity: Double {
        // Center bars are more prominent
        let center = CGFloat(max(totalBars - 1, 1)) / 2
        let centerDistance = abs(CGFloat(index) - center) / max(center, 1)
        let baseOpacity = 1.0 - (centerDistance * 0.3)

        // Boost opacity when speaking
        let speechBoost = isSpeechDetected ? 0.2 : 0
        return min(1.0, baseOpacity + speechBoost + Double(level) * 0.3)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.accent,
                        Theme.accent.opacity(0.7),
                        Theme.warmPeach
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: barWidth, height: height)
            .opacity(barOpacity)
            .shadow(
                color: isSpeechDetected ? Theme.accent.opacity(0.4) : .clear,
                radius: isSpeechDetected ? 4 : 0
            )
    }
}

// MARK: - Compact Waveform (for inline use)

/// Smaller waveform for use inside text fields or buttons
struct CompactWaveformView: View {
    let audioLevels: [Float]
    var isSpeechDetected: Bool = false

    var body: some View {
        VoiceWaveformView(
            audioLevels: audioLevels,
            isSpeechDetected: isSpeechDetected,
            barCount: 5,
            minHeight: 3,
            maxHeight: 16,
            barWidth: 2,
            spacing: 2
        )
    }
}

// MARK: - Full-Width Waveform (for text field backgrounds)

/// Full-width waveform that adapts bar count to available space
struct FullWidthWaveformView: View {
    let audioLevels: [Float]
    var isSpeechDetected: Bool = false
    var minHeight: CGFloat = 6
    var maxHeight: CGFloat = 28
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let barCount = max(10, Int((geo.size.width + spacing) / (barWidth + spacing)))
            VoiceWaveformView(
                audioLevels: audioLevels,
                isSpeechDetected: isSpeechDetected,
                barCount: barCount,
                minHeight: minHeight,
                maxHeight: maxHeight,
                barWidth: barWidth,
                spacing: spacing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Circular Waveform (ChatGPT-style)

/// Circular pulsing waveform visualization
struct CircularWaveformView: View {
    let audioLevel: Float
    var isSpeechDetected: Bool = false

    @State private var pulsePhase: CGFloat = 0
    @State private var rotationAngle: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            Theme.accent.opacity(0.15 - Double(ring) * 0.04),
                            lineWidth: 2
                        )
                        .frame(
                            width: ringSize(for: ring, level: audioLevel, time: time),
                            height: ringSize(for: ring, level: audioLevel, time: time)
                        )
                }

                // Main waveform circle
                WaveformCircle(
                    audioLevel: audioLevel,
                    time: time,
                    isSpeechDetected: isSpeechDetected
                )
                .frame(width: 80, height: 80)

                // Center microphone icon
                Image(systemName: isSpeechDetected ? "waveform" : "mic.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse, options: .repeating, value: isSpeechDetected)
            }
        }
    }

    private func ringSize(for ring: Int, level: Float, time: Double) -> CGFloat {
        let baseSize: CGFloat = 100 + CGFloat(ring) * 30
        let levelBoost = CGFloat(level) * 20
        let breathe = sin(time * 1.5 + Double(ring) * 0.5) * 5
        return baseSize + levelBoost + breathe
    }
}

// MARK: - Waveform Circle Shape

struct WaveformCircle: View {
    let audioLevel: Float
    let time: Double
    let isSpeechDetected: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 2 - 4

            var path = Path()
            let segments = 64

            for i in 0..<segments {
                let angle = (Double(i) / Double(segments)) * 2 * .pi

                // Create organic wobble based on audio level
                let wobbleFreq1 = sin(angle * 3 + time * 4) * Double(audioLevel) * 8
                let wobbleFreq2 = sin(angle * 5 + time * 3) * Double(audioLevel) * 4
                let wobbleFreq3 = cos(angle * 2 + time * 2) * Double(audioLevel) * 6

                // Breathing animation when idle
                let breathe = isSpeechDetected ? 0 : sin(time * 2) * 3

                let radius = baseRadius + wobbleFreq1 + wobbleFreq2 + wobbleFreq3 + breathe

                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()

            // Fill with gradient
            let gradient = Gradient(colors: [
                Color(Theme.accent).opacity(0.3),
                Color(Theme.warmPeach).opacity(0.2)
            ])

            context.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            // Stroke
            context.stroke(
                path,
                with: .color(Theme.accent.opacity(0.6)),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Preview

#Preview("Waveform Bars") {
    VStack(spacing: 40) {
        VoiceWaveformView(
            audioLevels: (0..<50).map { _ in Float.random(in: 0.2...0.8) },
            isSpeechDetected: true
        )

        VoiceWaveformView(
            audioLevels: Array(repeating: Float(0.1), count: 50),
            isSpeechDetected: false
        )

        CompactWaveformView(
            audioLevels: (0..<50).map { _ in Float.random(in: 0.3...0.7) },
            isSpeechDetected: true
        )
    }
    .padding(40)
    .background(Theme.background)
}

#Preview("Circular Waveform") {
    CircularWaveformView(
        audioLevel: 0.6,
        isSpeechDetected: true
    )
    .padding(60)
    .background(Theme.background)
}
