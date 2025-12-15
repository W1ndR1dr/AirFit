import SwiftUI

/// Celebratory confetti effect for milestone insights
struct ConfettiView: View {
    let colors: [Color]
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    init(colors: [Color] = [Theme.accent, Theme.warm, Theme.success, Theme.protein]) {
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                isAnimating = true
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? Theme.accent,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                targetY: size.height + 50,
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 1.5...2.5),
                wobble: CGFloat.random(in: -30...30)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let targetY: CGFloat
    let delay: Double
    let duration: Double
    let wobble: CGFloat
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var currentY: CGFloat
    @State private var currentRotation: Double
    @State private var opacity: Double = 1

    init(particle: ConfettiParticle) {
        self.particle = particle
        self._currentY = State(initialValue: particle.y)
        self._currentRotation = State(initialValue: particle.rotation)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: particle.x + sin(currentY / 30) * particle.wobble, y: currentY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    currentY = particle.targetY
                    currentRotation += Double.random(in: 360...720)
                }
                withAnimation(
                    .easeIn(duration: 0.5)
                    .delay(particle.delay + particle.duration - 0.5)
                ) {
                    opacity = 0
                }
            }
    }
}

/// Simpler burst effect for inline celebrations
struct CelebrationBurst: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .offset(x: scale * 30)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.5
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                opacity = 0
            }
        }
    }
}

/// Star burst for achievements
struct StarBurst: View {
    let color: Color
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 24))
            .foregroundStyle(color)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    scale = 1.2
                    rotation = 360
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.3)) {
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                    opacity = 0
                }
            }
    }
}

#Preview("Confetti") {
    ZStack {
        Theme.background.ignoresSafeArea()
        ConfettiView()
    }
}

#Preview("Burst") {
    ZStack {
        Theme.background.ignoresSafeArea()
        CelebrationBurst(color: Theme.warm)
    }
}
