import SwiftUI

struct WorkoutHistoryDetailView: View {
    let workout: WorkoutHistory

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.lg) {
                    headerSection
                    exerciseSections

                    Spacer(minLength: 40)
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            // Title + date
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                Text(workout.workoutName)
                    .font(.keelTitle)
                    .foregroundStyle(K.Colors.primary)

                HStack(spacing: K.Spacing.sm) {
                    Text(workout.completedAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.secondary)

                    if let blockName = workout.blockName {
                        Text("\u{00B7}")
                            .foregroundStyle(K.Colors.tertiary)
                        Text(blockName)
                            .font(.keelCaption)
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }

                Text("C\(workout.cycleNumber) \u{00B7} Week \(workout.weekNumber) \u{00B7} Day \(workout.dayIndex + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(K.Colors.tertiary)
            }

            // Stats row
            HStack(spacing: K.Spacing.xl) {
                headerStat(value: workout.formattedDuration, label: "Duration")
                headerStat(value: formatVolume(workout.totalVolume), label: "Volume")
                headerStat(value: "\(workout.totalWorkingSets)", label: "Sets")
                headerStat(value: "\(workout.totalReps)", label: "Reps")
            }

            HStack(spacing: K.Spacing.xl) {
                if let avgRest = workout.averageRestSeconds {
                    headerStat(value: formatRestTime(avgRest), label: "Avg Rest")
                }
                if let bw = workout.bodyWeight {
                    headerStat(value: String(format: "%.1f", bw), label: "Body Wt")
                }
            }
        }
        .keelCard()
        .padding(.horizontal, K.Spacing.lg)
        .padding(.top, K.Spacing.lg)
    }

    @ViewBuilder
    private func headerStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(K.Colors.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(K.Colors.tertiary)
        }
    }

    // MARK: - Exercise Sections

    @ViewBuilder
    private var exerciseSections: some View {
        let groups = workout.exerciseGroups

        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                // Exercise header
                HStack(spacing: K.Spacing.sm) {
                    Text(group.exerciseName.uppercased())
                        .sectionHeader()

                    if let tag = group.tag {
                        Text(tag.prefix)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(tag.color)
                    }

                    Spacer()

                    // Per-exercise volume subtotal
                    let exerciseVol = group.sets
                        .filter { !$0.isSkipped && $0.setType == .working }
                        .reduce(0.0) { $0 + $1.volume }
                    if exerciseVol > 0 {
                        Text(formatVolume(exerciseVol) + " lbs")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)

                // Sets
                ForEach(group.sets, id: \.id) { set in
                    setRow(set)
                }
            }
            .padding(.top, K.Spacing.sm)
        }
    }

    @ViewBuilder
    private func setRow(_ set: SetHistory) -> some View {
        let isWarmup = set.setType == .warmup
        let warmupIndex = isWarmup ? set.setNumber + 1 : nil
        let workingIndex: Int? = isWarmup ? nil : {
            // Compute the working set number relative to this exercise group
            let groups = workout.exerciseGroups
            guard let group = groups.first(where: { g in g.sets.contains(where: { $0.id == set.id }) }) else { return nil }
            let workingSets = group.sets.filter { $0.setType == .working }
            guard let idx = workingSets.firstIndex(where: { $0.id == set.id }) else { return nil }
            return idx + 1
        }()

        HStack(spacing: K.Spacing.md) {
            // Set label
            Text(isWarmup ? "W\(warmupIndex ?? 0)" : "S\(workingIndex ?? 0)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(isWarmup ? K.Colors.tertiary : K.Colors.primary)
                .frame(width: 28, alignment: .leading)

            if set.isSkipped {
                Text("Skipped")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(K.Colors.tertiary)
                    .strikethrough()
            } else {
                // Weight x Reps
                HStack(spacing: K.Spacing.xs) {
                    if let w = set.weight {
                        Text("\(Int(w))")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(isWarmup ? K.Colors.secondary : K.Colors.primary)
                    }

                    if set.weight != nil && set.reps != nil {
                        Text("\u{00D7}")
                            .font(.system(size: 12))
                            .foregroundStyle(K.Colors.tertiary)
                    }

                    if let r = set.reps {
                        Text("\(r)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(isWarmup ? K.Colors.secondary : K.Colors.primary)
                    }
                }

                if isWarmup {
                    Text("(warmup)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(K.Colors.tertiary)
                }

                if let rpe = set.rpe, !isWarmup {
                    Text("RPE \(rpe, specifier: "%.0f")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(K.Colors.secondary)
                }
            }

            Spacer()

            // Rest time
            if let rest = set.formattedRest {
                Text("Rest \(rest)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(K.Colors.tertiary)
            }
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.xs)
        .background(isWarmup ? K.Colors.warmup : Color.clear)
        .opacity(set.isSkipped ? 0.5 : 1.0)
    }

    // MARK: - Formatting Helpers

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
    }

    private func formatRestTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
