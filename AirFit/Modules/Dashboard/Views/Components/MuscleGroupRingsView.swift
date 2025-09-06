import SwiftUI

struct MuscleGroupRingsView: View {
    let volumes: [MuscleGroupVolume]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var animateRings = false

    // Group muscles for layout
    private var upperBodyVolumes: [MuscleGroupVolume] {
        volumes.filter { ["Chest", "Back", "Shoulders", "Biceps", "Triceps"].contains($0.name) }
    }

    private var lowerBodyVolumes: [MuscleGroupVolume] {
        volumes.filter { ["Quads", "Hamstrings", "Glutes", "Calves"].contains($0.name) }
    }

    private var coreVolume: MuscleGroupVolume? {
        volumes.first { $0.name == "Core" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Volume")
                .font(.system(size: 18, weight: .light))
                .opacity(0.7)

            VStack(spacing: 20) {
                // Upper body row
                HStack(spacing: 12) {
                    ForEach(upperBodyVolumes) { volume in
                        MuscleRing(
                            volume: volume,
                            animate: animateRings
                        )
                    }
                }

                // Core in the middle
                if let core = coreVolume {
                    HStack {
                        Spacer()
                        MuscleRing(
                            volume: core,
                            animate: animateRings,
                            size: 65
                        )
                        Spacer()
                    }
                }

                // Lower body row
                HStack(spacing: 12) {
                    ForEach(lowerBodyVolumes) { volume in
                        MuscleRing(
                            volume: volume,
                            animate: animateRings
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateRings = true
            }
        }
    }
}

// MARK: - Individual Muscle Ring
private struct MuscleRing: View {
    let volume: MuscleGroupVolume
    let animate: Bool
    var size: CGFloat = 55

    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var ringColor: Color {
        switch volume.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "indigo": return .indigo
        default: return .gray
        }
    }

    private var progress: Double {
        animate ? volume.progress : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 5)
                    .frame(width: size, height: size)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor.opacity(0.8),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size, height: size)
                    .animation(
                        .bouncy(extraBounce: 0.2)
                            .delay(delayForMuscle(volume.name)),
                        value: progress
                    )

                // Sets in center
                VStack(spacing: 0) {
                    Text("\(volume.sets)")
                        .font(.system(size: size == 65 ? 18 : 16, weight: .semibold))
                        .foregroundStyle(ringColor)

                    if volume.sets != volume.target {
                        Text("/\(volume.target)")
                            .font(.system(size: size == 65 ? 11 : 10, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(muscleAbbreviation(volume.name))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func delayForMuscle(_ name: String) -> Double {
        let muscleOrder = ["Chest", "Back", "Shoulders", "Biceps", "Triceps",
                           "Core", "Quads", "Hamstrings", "Glutes", "Calves"]
        let index = muscleOrder.firstIndex(of: name) ?? 0
        return Double(index) * 0.05
    }

    private func muscleAbbreviation(_ name: String) -> String {
        switch name {
        case "Chest": return "CHE"
        case "Back": return "BAC"
        case "Shoulders": return "SHO"
        case "Biceps": return "BIC"
        case "Triceps": return "TRI"
        case "Quads": return "QUA"
        case "Hamstrings": return "HAM"
        case "Glutes": return "GLU"
        case "Calves": return "CAL"
        case "Core": return "CORE"
        default: return name.prefix(3).uppercased()
        }
    }
}

// Use existing MotionToken from app

// MARK: - Preview
#Preview {
    BaseScreen {
        VStack {
            MuscleGroupRingsView(
                volumes: [
                    MuscleGroupVolume(name: "Chest", sets: 12, target: 16, color: "blue"),
                    MuscleGroupVolume(name: "Back", sets: 14, target: 16, color: "green"),
                    MuscleGroupVolume(name: "Shoulders", sets: 8, target: 12, color: "orange"),
                    MuscleGroupVolume(name: "Biceps", sets: 6, target: 10, color: "purple"),
                    MuscleGroupVolume(name: "Triceps", sets: 7, target: 10, color: "pink"),
                    MuscleGroupVolume(name: "Core", sets: 5, target: 12, color: "yellow"),
                    MuscleGroupVolume(name: "Quads", sets: 10, target: 12, color: "red"),
                    MuscleGroupVolume(name: "Hamstrings", sets: 6, target: 10, color: "orange"),
                    MuscleGroupVolume(name: "Glutes", sets: 8, target: 10, color: "pink"),
                    MuscleGroupVolume(name: "Calves", sets: 4, target: 8, color: "indigo")
                ]
            )
            .padding()

            Spacer()
        }
    }
    .environmentObject(GradientManager())
}
