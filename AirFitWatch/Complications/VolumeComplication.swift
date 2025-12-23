import SwiftUI
import WidgetKit

/// Rectangular complication showing muscle group volume progress.
/// Shows top 3 muscle groups with progress bars.
struct VolumeRectangularComplication: View {
    let volume: VolumeProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(volume.muscleGroups.prefix(3)) { group in
                HStack(spacing: 4) {
                    Text(group.name.prefix(5))
                        .font(.system(size: 9, weight: .medium))
                        .frame(width: 32, alignment: .leading)
                        .foregroundColor(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(statusColor(for: group.status).opacity(0.2))

                            // Progress
                            RoundedRectangle(cornerRadius: 2)
                                .fill(statusColor(for: group.status))
                                .frame(width: geo.size.width * group.progress)
                        }
                    }
                    .frame(height: 8)

                    if group.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("\(group.currentSets)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(statusColor(for: group.status))
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "in_zone": return .green
        case "above": return .blue
        case "below": return .yellow
        case "at_floor": return .red
        default: return .gray
        }
    }
}

/// Circular complication - overall volume score
struct VolumeCircularComplication: View {
    let volume: VolumeProgress

    private var overallProgress: Double {
        guard !volume.muscleGroups.isEmpty else { return 0 }
        let total = volume.muscleGroups.map(\.progress).reduce(0, +)
        return total / Double(volume.muscleGroups.count)
    }

    private var completedCount: Int {
        volume.muscleGroups.filter(\.isComplete).count
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: overallProgress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 0) {
                Text("\(completedCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Corner complication - muscle groups completed
struct VolumeCornerComplication: View {
    let volume: VolumeProgress

    private var completedCount: Int {
        volume.muscleGroups.filter(\.isComplete).count
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("\(completedCount)/\(volume.muscleGroups.count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Rectangular") {
    VolumeRectangularComplication(volume: VolumeProgress(
        muscleGroups: [
            .init(name: "Chest", currentSets: 8, targetSets: 16, status: "below"),
            .init(name: "Back", currentSets: 15, targetSets: 15, status: "in_zone"),
            .init(name: "Legs", currentSets: 18, targetSets: 16, status: "above")
        ],
        lastUpdated: Date()
    ))
    .frame(width: 150, height: 60)
}

#Preview("Circular") {
    VolumeCircularComplication(volume: VolumeProgress(
        muscleGroups: [
            .init(name: "Chest", currentSets: 8, targetSets: 16, status: "below"),
            .init(name: "Back", currentSets: 15, targetSets: 15, status: "in_zone"),
            .init(name: "Legs", currentSets: 18, targetSets: 16, status: "above")
        ],
        lastUpdated: Date()
    ))
    .frame(width: 50, height: 50)
}
