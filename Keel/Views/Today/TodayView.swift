import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Program> { $0.isActive == true }) private var activePrograms: [Program]
    @State private var expandedExerciseIds: Set<UUID> = []
    @State private var showRestTimer = false
    @State private var restSeconds: Int = 0
    @State private var showSubstitutionSheet = false
    @State private var selectedExercise: Exercise?
    @State private var showCompletionAlert = false
    @State private var showAddCardio = false
    @State private var showCancelWorkoutAlert = false

    // Day/week override — transient, resets on relaunch
    @State private var selectedDayIndex: Int?
    @State private var selectedWeekOverride: Int?

    @Environment(PlateSettings.self) private var plateSettings
    @State private var plateConfigRevision = 0
    var workoutSession: WorkoutSessionService

    private var program: Program? { activePrograms.first }

    private var effectiveWeek: Int {
        selectedWeekOverride ?? program?.currentWeek ?? 1
    }

    private var effectiveDayIndex: Int? {
        if let override = selectedDayIndex { return override }
        // Map today's calendar day to a day index based on training days
        guard let program else { return nil }
        let today = TrainingDay.fromDate(Date())
        return program.trainingDays.firstIndex(of: today)
    }

    private var selectedWorkout: Workout? {
        guard let program else { return nil }
        let weekWorkouts = program.workoutsForWeek(effectiveWeek)
        guard let dayIdx = effectiveDayIndex,
              dayIdx >= 0 && dayIdx < weekWorkouts.count else { return nil }
        return weekWorkouts[dayIdx]
    }

    private var oneRepMaxes: [CompoundLift: Double] {
        ProgramService(modelContext: modelContext).currentOneRepMaxes()
    }

    private var todayDate: Date { Date() }

    var body: some View {
        ZStack {
            // Green-tinted background when workout session is active
            if workoutSession.isSessionActive {
                K.Colors.accent.opacity(0.06).ignoresSafeArea()
            } else {
                K.Colors.background.ignoresSafeArea()
            }

            if let program {
                if let workout = selectedWorkout {
                    workoutContent(program: program, workout: workout)
                } else {
                    noWorkoutToday(program: program)
                }
            } else {
                noProgramView
            }

            if showRestTimer {
                RestTimerOverlay(
                    totalSeconds: restSeconds,
                    isPresented: $showRestTimer
                )
            }
        }
        .alert("Workout Complete", isPresented: $showCompletionAlert) {
            Button("Done") { }
        } message: {
            Text("All sets finished. Great work.")
        }
        .sheet(isPresented: $showAddCardio) {
            AddCardioSheet(date: todayDate)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Day/Week Selector

    @ViewBuilder
    private func daySelectorBar(program: Program) -> some View {
        VStack(spacing: K.Spacing.sm) {
            // Week override
            HStack {
                Text("WEEK")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(K.Colors.tertiary)
                    .tracking(0.8)

                Picker("Week", selection: Binding(
                    get: { effectiveWeek },
                    set: { selectedWeekOverride = $0 }
                )) {
                    ForEach(1...program.totalWeeks, id: \.self) { week in
                        Text("\(week)").tag(week)
                    }
                }
                .tint(K.Colors.accent)

                Spacer()

                if selectedWeekOverride != nil || selectedDayIndex != nil {
                    Button {
                        selectedWeekOverride = nil
                        selectedDayIndex = nil
                    } label: {
                        HStack(spacing: K.Spacing.xs) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Today")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(K.Colors.accent)
                    }
                }
            }

            // Day selector — D1 through D5
            HStack(spacing: K.Spacing.sm) {
                ForEach(0..<program.trainingDays.count, id: \.self) { idx in
                    let isSelected = effectiveDayIndex == idx
                    Button {
                        withAnimation(K.Animation.fast) {
                            selectedDayIndex = idx
                        }
                    } label: {
                        Text("D\(idx + 1)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(isSelected ? K.Colors.background : K.Colors.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, K.Spacing.sm)
                            .background(isSelected ? K.Colors.accent : K.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                            .overlay(
                                RoundedRectangle(cornerRadius: K.Radius.sharp)
                                    .stroke(isSelected ? K.Colors.accent : K.Colors.surfaceBorder, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Workout Content

    @ViewBuilder
    private func workoutContent(program: Program, workout: Workout) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.lg) {
                daySelectorBar(program: program)
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.top, K.Spacing.md)

                workoutHeader(program: program, workout: workout)

                // Live workout session
                if workoutSession.isSessionActive {
                    LiveWorkoutBanner(workoutService: workoutSession)
                } else {
                    startWorkoutButton
                }

                // Cardio section
                cardioSection

                if workout.completionProgress > 0 && !workout.isCompleted {
                    progressBar(workout.completionProgress)
                }

                ForEach(workout.sortedExercises) { exercise in
                    let prevSets = ProgramService(modelContext: modelContext)
                        .previousPerformance(
                            exerciseName: exercise.activeSubstitution ?? exercise.name,
                            programId: program.id,
                            currentWeek: effectiveWeek
                        )

                    ExerciseCardView(
                        exercise: exercise,
                        oneRepMaxes: oneRepMaxes,
                        isExpanded: expandedExerciseIds.contains(exercise.id),
                        onTap: {
                            withAnimation(K.Animation.fast) {
                                if expandedExerciseIds.contains(exercise.id) {
                                    expandedExerciseIds.remove(exercise.id)
                                } else {
                                    expandedExerciseIds.insert(exercise.id)
                                }
                            }
                        },
                        onSetComplete: { setLog in
                            completeSet(setLog, exercise: exercise, workout: workout)
                        },
                        onSetUncomplete: { setLog in
                            uncompleteSet(setLog)
                        },
                        onLongPress: {
                            if !exercise.substitutions.isEmpty {
                                selectedExercise = exercise
                                showSubstitutionSheet = true
                            }
                        },
                        onStartRest: { seconds in
                            restSeconds = seconds
                            showRestTimer = true
                        },
                        previousSets: prevSets
                    )
                    .id("\(exercise.id)-\(plateConfigRevision)")
                }

                if !workout.isCompleted && workout.completionProgress >= 1.0 {
                    completeWorkoutButton(workout)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, K.Spacing.lg)
        }
        .onChange(of: plateSettings.barWeight) { _, _ in plateConfigRevision += 1 }
        .onChange(of: plateSettings.availablePlates) { _, _ in plateConfigRevision += 1 }
        .onChange(of: plateSettings.weightUnit) { _, _ in plateConfigRevision += 1 }
        .sheet(isPresented: $showSubstitutionSheet) {
            if let exercise = selectedExercise {
                SubstitutionSheet(exercise: exercise)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Reset Workout?", isPresented: $showCancelWorkoutAlert) {
            Button("Reset All Sets", role: .destructive) {
                if let workout = selectedWorkout {
                    let service = ProgramService(modelContext: modelContext)
                    service.cancelWorkout(workout)
                    if workoutSession.isSessionActive {
                        workoutSession.endSession()
                    }
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will uncheck all sets and reset the workout. Your previous week's data is not affected.")
        }
    }

    // MARK: - Cardio Section

    @ViewBuilder
    private var cardioSection: some View {
        let service = ProgramService(modelContext: modelContext)
        let todayCardio = service.cardioLogsForDate(todayDate)

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            if !todayCardio.isEmpty {
                Text("CARDIO")
                    .sectionHeader()

                ForEach(todayCardio) { log in
                    HStack(spacing: K.Spacing.md) {
                        Image(systemName: log.type.icon)
                            .font(.body)
                            .foregroundStyle(K.Colors.accent)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.type.displayName)
                                .font(.keelCaption)
                                .foregroundStyle(K.Colors.primary)
                            if let notes = log.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(K.Colors.tertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Text("\(log.durationMinutes) min")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(K.Colors.secondary)
                    }
                    .frame(minHeight: 44)
                    .keelCard()
                }
            }

            Button {
                showAddCardio = true
            } label: {
                HStack(spacing: K.Spacing.sm) {
                    Image(systemName: "plus.circle")
                    Text("Add Cardio")
                }
                .font(.keelCaption)
                .foregroundStyle(K.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: K.Radius.sharp)
                        .stroke(K.Colors.accent.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func workoutHeader(program: Program, workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.xs) {
            HStack {
                Text("WEEK \(effectiveWeek)")
                    .sectionHeader()

                if let block = program.blockForWeek(effectiveWeek) {
                    Text("·")
                        .foregroundStyle(K.Colors.tertiary)
                    Text(block.name.uppercased())
                        .sectionHeader()
                }

                Spacer()

                if workout.completionProgress > 0 {
                    Button {
                        showCancelWorkoutAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }

                if workout.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(K.Colors.success)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(workout.name)
                    .font(.keelTitle)
                    .foregroundStyle(K.Colors.primary)

                Spacer()

                HStack(spacing: K.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("~\(workout.estimatedMinutes) min")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(K.Colors.secondary)
            }

            if selectedWeekOverride == nil && selectedDayIndex == nil {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
            } else {
                Text("Day \((effectiveDayIndex ?? 0) + 1) · Week \(effectiveWeek)")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
            }
        }
    }

    @ViewBuilder
    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(K.Colors.surfaceLight)
                    .frame(height: 3)

                Rectangle()
                    .fill(K.Colors.accent)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(K.Animation.fast, value: progress)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private func completeWorkoutButton(_ workout: Workout) -> some View {
        Button {
            let service = ProgramService(modelContext: modelContext)
            service.completeWorkout(workout)

            // End live workout session (saves to HealthKit automatically)
            if workoutSession.isSessionActive {
                workoutSession.endSession()
            } else if let start = workout.startedAt {
                // Fallback: save workout manually if no session was active
                Task {
                    await HealthKitService().saveWorkout(startDate: start, endDate: Date())
                }
            }

            showCompletionAlert = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } label: {
            Text("COMPLETE WORKOUT")
                .font(.keelHeadline)
                .foregroundStyle(K.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.lg)
                .background(K.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
        }
        .padding(.top, K.Spacing.lg)
    }

    // MARK: - Start Workout Button

    @ViewBuilder
    private var startWorkoutButton: some View {
        Button {
            workoutSession.startSession()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: K.Spacing.sm) {
                Image(systemName: "heart.circle.fill")
                    .font(.body)
                    .foregroundStyle(K.Colors.accent)
                Text("Start Workout Session")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(K.Colors.secondary)
                Spacer()
                Text("Apple Health")
                    .font(.system(size: 10))
                    .foregroundStyle(K.Colors.tertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(K.Colors.tertiary)
            }
            .padding(.horizontal, K.Spacing.lg)
            .padding(.vertical, K.Spacing.md)
            .background(K.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private func noWorkoutToday(program: Program) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.lg) {
                daySelectorBar(program: program)
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.top, K.Spacing.md)

                // Cardio section still available on rest days
                cardioSection
                    .padding(.horizontal, K.Spacing.lg)

                VStack(spacing: K.Spacing.lg) {
                    Spacer(minLength: 40)
                    Text("REST DAY")
                        .font(.keelTitle)
                        .foregroundStyle(K.Colors.primary)

                    Text("Week \(effectiveWeek) · No workout scheduled")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)

                    Text("Tap a day above to view a different workout")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var noProgramView: some View {
        VStack(spacing: K.Spacing.lg) {
            Text("KEEL")
                .font(.system(size: 32, weight: .heavy, design: .default))
                .foregroundStyle(K.Colors.primary)
                .tracking(4)

            Text("No active program")
                .font(.keelBody)
                .foregroundStyle(K.Colors.secondary)

            Text("Go to Programs to get started")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
        }
    }

    // MARK: - Actions

    private func completeSet(_ setLog: SetLog, exercise: Exercise, workout: Workout) {
        let service = ProgramService(modelContext: modelContext)
        service.markSetComplete(setLog)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Save custom warmup percentages if user edited warmup weights
        if setLog.setType == .warmup {
            saveWarmupDefaultsIfEdited(exercise: exercise)
        }

        // Start workout session on first set
        if !workoutSession.isSessionActive {
            workoutSession.startSession()
        }

        // Check if workout is fully complete
        let allDone = workout.sortedExercises.allSatisfy { ex in
            ex.sortedSetLogs.allSatisfy(\.isCompleted)
        }
        if allDone && !workout.isCompleted {
            service.completeWorkout(workout)
            workoutSession.endSession()
            showCompletionAlert = true
        }
    }

    private func uncompleteSet(_ setLog: SetLog) {
        let service = ProgramService(modelContext: modelContext)
        service.unmarkSetComplete(setLog)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func allSetsComplete(_ exercise: Exercise) -> Bool {
        exercise.sortedSetLogs.allSatisfy(\.isCompleted)
    }

    private func saveWarmupDefaultsIfEdited(exercise: Exercise) {
        let warmups = exercise.sortedSetLogs.filter { $0.setType == .warmup }
        let workingWeight = exercise.sortedSetLogs
            .first(where: { $0.setType == .working })?.weight

        guard let working = workingWeight, working > 0, !warmups.isEmpty else { return }

        let percentages = warmups.compactMap { warmup -> Double? in
            guard let w = warmup.weight, w > 0 else { return nil }
            return w / working
        }

        guard percentages.count == warmups.count else { return }
        WarmupDefaults.saveCustomPercentages(for: exercise.name, percentages: percentages)
    }

}
