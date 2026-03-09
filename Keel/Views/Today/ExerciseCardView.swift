import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    let oneRepMaxes: [CompoundLift: Double]
    let isExpanded: Bool
    let onTap: () -> Void
    let onSetComplete: (SetLog) -> Void
    var onSetUncomplete: ((SetLog) -> Void)? = nil
    let onLongPress: () -> Void
    var onStartRest: ((Int) -> Void)? = nil
    var previousSets: [SetLog]?

    @Environment(PlateSettings.self) private var plateSettings

    private var calculatedLoad: Double? {
        guard let lift = exercise.percentageOf,
              let orm = oneRepMaxes[lift] else { return nil }
        return exercise.calculatedLoad(oneRepMax: orm)
    }

    private var allComplete: Bool {
        exercise.sortedSetLogs.allSatisfy(\.isCompleted)
    }

    private var currentBreakdown: PlateBreakdown? {
        let weight = exercise.sortedSetLogs.first(where: { $0.setType == .working })?.weight ?? calculatedLoad
        guard let w = weight, w > 0 else { return nil }
        return PlateCalculator.calculate(
            targetWeight: w,
            barWeight: plateSettings.barWeight,
            availablePlates: plateSettings.availablePlates
        )
    }

    var body: some View {
        let breakdown = currentBreakdown

        VStack(alignment: .leading, spacing: 0) {
            // Header
            exerciseHeader(breakdown: breakdown)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
                .onLongPressGesture(perform: onLongPress)

            // Expanded: Set logging
            if isExpanded {
                Divider()
                    .background(K.Colors.surfaceBorder)

                // Plate calculator visual
                if let breakdown, !breakdown.platesPerSide.isEmpty {
                    PlateVisualView(breakdown: breakdown, unit: plateSettings.weightUnit)
                        .padding(.horizontal, K.Spacing.lg)
                        .padding(.top, K.Spacing.lg)
                }

                // Previous performance
                if let prev = previousSets, !prev.isEmpty {
                    previousPerformanceRow(prev)
                        .padding(.top, K.Spacing.xs)
                }

                setLoggingContent
            }
        }
        .keelCard(padding: 0)
        .opacity(allComplete ? 0.6 : 1.0)
    }

    // MARK: - Header

    @ViewBuilder
    private func exerciseHeader(breakdown: PlateBreakdown?) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.xs) {
            // Row 1: ring + name (left), weight + chevron (right)
            HStack(spacing: K.Spacing.md) {
                completionIndicator

                HStack(spacing: K.Spacing.sm) {
                    if let tag = exercise.tag {
                        Image(systemName: tag.icon)
                            .font(.subheadline)
                            .foregroundStyle(tag.color)
                    }

                    Text(exercise.displayName)
                        .font(.keelHeadline)
                        .foregroundStyle(K.Colors.primary)
                        .lineLimit(1)

                    if exercise.activeSubstitution != nil {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.caption2)
                            .foregroundStyle(K.Colors.accent)
                    }
                }

                Spacer()

                if let load = calculatedLoad {
                    Text(load.weightString())
                        .font(.system(.headline, design: .monospaced, weight: .bold))
                        .foregroundStyle(K.Colors.accent)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(K.Colors.tertiary)
            }

            // Row 2: sets × reps  ·  percentage  ·  RPE  ·  est time
            HStack(spacing: K.Spacing.sm) {
                Text("\(exercise.workingSets) \u{00D7} \(exercise.targetReps)")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.primary.opacity(0.7))

                if let pct = exercise.percentage {
                    Text("\u{00B7}")
                        .foregroundStyle(K.Colors.secondary)
                    Text(pct.percentageString())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(K.Colors.accent)
                }

                if let rpe = exercise.rpeTarget {
                    Text("\u{00B7}")
                        .foregroundStyle(K.Colors.secondary)
                    Text(rpe)
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.primary.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("~\(exercise.estimatedMinutes)m")
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundStyle(K.Colors.tertiary)
            }
            .padding(.leading, 36 + K.Spacing.md)

            // Row 3: compact plate summary (collapsed only)
            if let breakdown, !breakdown.platesPerSide.isEmpty, !isExpanded {
                PlateCompactView(breakdown: breakdown, unit: plateSettings.weightUnit)
                    .padding(.leading, 36 + K.Spacing.md)
            }
        }
        .padding(K.Spacing.lg)
    }

    @ViewBuilder
    private var completionIndicator: some View {
        let completed = exercise.sortedSetLogs.filter(\.isCompleted).count
        let total = exercise.totalSets

        ZStack {
            Circle()
                .stroke(K.Colors.surfaceBorder, lineWidth: 2)
                .frame(width: 36, height: 36)

            Circle()
                .trim(from: 0, to: total > 0 ? CGFloat(completed) / CGFloat(total) : 0)
                .stroke(allComplete ? K.Colors.success : K.Colors.accent, lineWidth: 2)
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))

            Text("\(completed)/\(total)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(K.Colors.secondary)
        }
    }

    // MARK: - Previous Performance

    @ViewBuilder
    private func previousPerformanceRow(_ sets: [SetLog]) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.xs) {
            Text("PREVIOUS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(K.Colors.tertiary)
                .tracking(0.8)

            HStack(spacing: K.Spacing.md) {
                ForEach(Array(sets.prefix(5).enumerated()), id: \.offset) { _, set in
                    HStack(spacing: 2) {
                        if let w = set.weight {
                            Text("\(Int(w))")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(K.Colors.tertiary)
                        }
                        Text("×")
                            .font(.system(size: 11))
                            .foregroundStyle(K.Colors.tertiary)
                        if let r = set.reps {
                            Text("\(r)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(K.Colors.tertiary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.top, K.Spacing.sm)
    }

    // MARK: - Set Logging

    @ViewBuilder
    private var setLoggingContent: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("WEIGHT")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("REPS")
                    .frame(width: 60, alignment: .center)
                Text("RPE")
                    .frame(width: 50, alignment: .center)
                Text("")
                    .frame(width: 44)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(K.Colors.tertiary)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, K.Spacing.lg)
            .padding(.top, K.Spacing.md)
            .padding(.bottom, K.Spacing.sm)

            ForEach(Array(exercise.sortedSetLogs.enumerated()), id: \.element.id) { _, setLog in
                let displayNum: Int = {
                    let sorted = exercise.sortedSetLogs
                    let sameType = sorted.filter { $0.setType == setLog.setType }
                    let idx = sameType.firstIndex(where: { $0.id == setLog.id }) ?? 0
                    return idx + 1
                }()

                SetRowView(
                    setLog: setLog,
                    isBodyweightExercise: exercise.loadType == .rpe && exercise.percentageOf == nil,
                    displayNumber: displayNum,
                    onComplete: { onSetComplete(setLog) },
                    onUncomplete: { onSetUncomplete?(setLog) }
                )
            }

            // Coaching notes
            if !exercise.notes.isEmpty {
                HStack(alignment: .top, spacing: K.Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(K.Colors.accent.opacity(0.6))
                    Text(exercise.notes)
                        .font(.caption)
                        .foregroundStyle(K.Colors.secondary)
                }
                .padding(K.Spacing.lg)
            }

            // Rest timer button — shown when some sets are done but not all
            if !allComplete && exercise.sortedSetLogs.contains(where: \.isCompleted) {
                Button {
                    let seconds = Exercise.parseRestSeconds(exercise.restPeriod)
                    onStartRest?(seconds)
                } label: {
                    HStack(spacing: K.Spacing.sm) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("Rest \(exercise.restPeriod)")
                            .font(.system(.caption, weight: .medium))
                    }
                    .foregroundStyle(K.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: K.Radius.sharp)
                            .stroke(K.Colors.accent.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.bottom, K.Spacing.md)
            }
        }
    }
}

// MARK: - Set Row

struct SetRowView: View {
    @Bindable var setLog: SetLog
    var isBodyweightExercise: Bool = false
    var displayNumber: Int? = nil
    let onComplete: () -> Void
    var onUncomplete: (() -> Void)? = nil
    @State private var showNote = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Set label
                Text(setLog.setType == .warmup ? "W\(displayNumber ?? (setLog.setNumber + 1))" : "S\(displayNumber ?? (setLog.setNumber + 1))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(setLog.setType == .warmup ? K.Colors.tertiary : K.Colors.secondary)
                    .frame(width: 40, alignment: .leading)

                // Weight (with unit label)
                HStack(spacing: 2) {
                    if isBodyweightExercise && setLog.weight == nil {
                        Text("BW")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(K.Colors.tertiary)
                            .frame(maxWidth: .infinity)
                    } else {
                        TextField("—", value: $setLog.weight, format: .number)
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(K.Colors.primary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity)
                        Text("lbs")
                            .font(.system(size: 11))
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }

                // Reps
                TextField("—", value: $setLog.reps, format: .number)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundStyle(K.Colors.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 60)

                // RPE
                TextField("—", value: $setLog.rpe, format: .number)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(K.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(width: 50)

                // Complete / uncomplete button
                Button {
                    if setLog.isCompleted {
                        onUncomplete?()
                    } else {
                        onComplete()
                    }
                } label: {
                    Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(setLog.isCompleted ? K.Colors.success : K.Colors.surfaceBorder)
                }
                .frame(width: 44)
            }
            .padding(.horizontal, K.Spacing.lg)
            .padding(.vertical, K.Spacing.sm)
            .background(setLog.setType == .warmup ? K.Colors.warmup.opacity(0.3) : Color.clear)
            .onTapGesture(count: 2) {
                showNote.toggle()
            }

            // Per-set note (tap to reveal)
            if showNote || (setLog.note != nil && !setLog.note!.isEmpty) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(K.Colors.tertiary)
                    TextField("Add note...", text: Binding(
                        get: { setLog.note ?? "" },
                        set: { setLog.note = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(K.Colors.secondary)
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.bottom, K.Spacing.xs)
            }
        }
    }
}
