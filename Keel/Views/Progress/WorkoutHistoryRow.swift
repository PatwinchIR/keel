import SwiftUI

struct WorkoutHistoryRow: View {
    let workout: WorkoutHistory

    var body: some View {
        VStack(alignment: .leading, spacing: K.Spacing.xs) {
            // Row 1: Workout name + duration
            HStack {
                Text(workout.workoutName)
                    .font(.keelHeadline)
                    .foregroundStyle(K.Colors.primary)
                    .lineLimit(1)

                Spacer()

                Text(workout.formattedDuration)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(K.Colors.secondary)
            }

            // Row 2: Cycle / Week / Day + Date
            HStack {
                Text("C\(workout.cycleNumber) \u{00B7} Week \(workout.weekNumber) \u{00B7} Day \(workout.dayIndex + 1)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(K.Colors.tertiary)

                Spacer()

                Text(workout.completedAt.formatted(.dateTime.month(.abbreviated).day().year(.twoDigits)))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(K.Colors.tertiary)
            }

            // Row 3: Stats
            HStack(spacing: K.Spacing.sm) {
                let volume = workout.totalVolume
                if volume > 0 {
                    statLabel(formatVolume(volume) + " lbs")
                }

                if workout.totalWorkingSets > 0 {
                    statLabel("\(workout.totalWorkingSets) sets")
                }

                if let avgRest = workout.averageRestSeconds {
                    let mins = Int(avgRest) / 60
                    let secs = Int(avgRest) % 60
                    statLabel("Avg rest \(mins):\(String(format: "%02d", secs))")
                }
            }
        }
        .keelCard(padding: K.Spacing.md)
    }

    @ViewBuilder
    private func statLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(K.Colors.secondary)
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
    }
}
