import SwiftUI

struct MuscleVolumeView: View {
    let volumes: [MuscleGroupVolume]
    @State private var animateBars = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Volume")
                .font(.system(size: 18, weight: .light))
                .opacity(0.7)

            VStack(spacing: 12) {
                ForEach(volumes) { volume in
                    HStack(spacing: 12) {
                        Text(volume.name)
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 80, alignment: .leading)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)

                                // Progress
                                Rectangle()
                                    .fill(progressColor(for: volume.progress))
                                    .frame(
                                        width: animateBars ? geometry.size.width * volume.progress : 0,
                                        height: 4
                                    )
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                            .delay(Double(volumes.firstIndex(where: { $0.id == volume.id }) ?? 0) * 0.05),
                                        value: animateBars
                                    )
                            }
                        }
                        .frame(height: 4)

                        Text("\(volume.sets)/\(volume.target)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(progressColor(for: volume.progress))
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .onAppear {
            animateBars = true
        }
    }

    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.5:
            return .red.opacity(0.8)
        case 0.5..<0.8:
            return .yellow.opacity(0.8)
        default:
            return .green.opacity(0.8)
        }
    }
}

// MARK: - Preview
#Preview {
    BaseScreen {
        VStack {
            MuscleVolumeView(
                volumes: [
                    MuscleGroupVolume(name: "Chest", sets: 12, target: 16, color: "blue"),
                    MuscleGroupVolume(name: "Back", sets: 14, target: 16, color: "green"),
                    MuscleGroupVolume(name: "Shoulders", sets: 8, target: 12, color: "orange"),
                    MuscleGroupVolume(name: "Legs", sets: 10, target: 16, color: "red")
                ]
            )
            .padding()

            Spacer()
        }
    }
}
