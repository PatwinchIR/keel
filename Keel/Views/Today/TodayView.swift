import SwiftUI
import SwiftData
import FoundationModels

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
    @State private var showSkipConfirm = false
    @State private var aiQuote: String?
    @State private var isGeneratingQuote = false

    // Day/week override — transient, resets on relaunch
    @State private var selectedDayIndex: Int?
    @State private var selectedWeekOverride: Int?

    @Environment(PlateSettings.self) private var plateSettings
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(RestDaySettings.self) private var restDaySettings
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

    /// Whether the user is viewing today (no manual day/week override)
    private var isViewingToday: Bool {
        selectedDayIndex == nil && selectedWeekOverride == nil
    }

    /// Whether today is a rest day (from settings or temp override)
    private var isTodayRest: Bool {
        restDaySettings.isTodayRestDay()
    }

    /// Whether we should show the rest day screen
    /// Only when viewing today (no overrides) and today is a rest day
    private var shouldShowRestDay: Bool {
        isViewingToday && isTodayRest
    }

    private var oneRepMaxes: [CompoundLift: Double] {
        // Use cycle-locked 1RMs; fall back to latest for legacy programs without locked values
        let locked = program?.lockedOneRepMaxes ?? [:]
        if !locked.isEmpty { return locked }
        return ProgramService(modelContext: modelContext).currentOneRepMaxes()
    }

    private var todayDate: Date { Date() }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            if let program {
                if shouldShowRestDay {
                    restDayView(program: program)
                } else if let workout = selectedWorkout {
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
        .onChange(of: workoutSession.isSessionActive) { _, isActive in
            if isActive {
                healthKitService.startActivityRingRefresh()
            } else {
                healthKitService.stopActivityRingRefresh()
            }
        }
        .onChange(of: program?.currentWeek) { _, _ in
            selectedWeekOverride = nil
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
            // Cycle · Week · Date — evenly spaced
            HStack {
                Text("Cycle \(program.currentCycleNumber)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(K.Colors.secondary)

                Spacer()

                HStack(spacing: 2) {
                    Text("Week")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(K.Colors.secondary)
                    Picker("", selection: Binding(
                        get: { effectiveWeek },
                        set: { selectedWeekOverride = $0 }
                    )) {
                        ForEach(1...program.totalWeeks, id: \.self) { week in
                            Text("\(week)").tag(week)
                        }
                    }
                    .tint(K.Colors.accent)
                    .labelsHidden()
                }

                Spacer()

                Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(K.Colors.secondary)

                if selectedWeekOverride != nil || selectedDayIndex != nil {
                    Button {
                        selectedWeekOverride = nil
                        selectedDayIndex = nil
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(K.Colors.accent)
                    }
                    .padding(.leading, K.Spacing.xs)
                }
            }

            // Day selector
            HStack(spacing: K.Spacing.sm) {
                ForEach(0..<program.trainingDays.count, id: \.self) { idx in
                    let isSelected = effectiveDayIndex == idx
                    Button {
                        withAnimation(K.Animation.fast) {
                            selectedDayIndex = idx
                        }
                    } label: {
                        Text("Day \(idx + 1)")
                            .font(.system(size: 13, weight: .semibold))
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.lg) {
                    daySelectorBar(program: program)
                        .padding(.top, K.Spacing.md)

                    workoutHeader(program: program, workout: workout)

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
                        onSetSkip: { setLog in
                            skipSet(setLog, exercise: exercise, workout: workout)
                        },
                        onSkipExercise: {
                            skipExercise(exercise, workout: workout)
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
        .alert("Skip Workout?", isPresented: $showSkipConfirm) {
            Button("Skip", role: .destructive) {
                if let workout = selectedWorkout {
                    let service = ProgramService(modelContext: modelContext)
                    service.completeWorkout(workout)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will mark today's workout as done without completing any sets.")
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
                if let block = program.blockForWeek(effectiveWeek) {
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

            // Rest day / Skip actions — only for today's actual workout, not started yet
            if isViewingToday && !workout.isCompleted && workout.completionProgress == 0 {
                HStack(spacing: K.Spacing.md) {
                    Button {
                        withAnimation(K.Animation.fast) {
                            restDaySettings.toggleTempRestDay(Date())
                        }
                    } label: {
                        HStack(spacing: K.Spacing.xs) {
                            Image(systemName: "bed.double")
                                .font(.system(size: 11))
                            Text("Rest Day")
                                .font(.keelCaption)
                        }
                        .foregroundStyle(K.Colors.secondary)
                        .padding(.horizontal, K.Spacing.md)
                        .padding(.vertical, K.Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: K.Radius.sharp)
                                .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
                        )
                    }

                    Button {
                        showSkipConfirm = true
                    } label: {
                        HStack(spacing: K.Spacing.xs) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 11))
                            Text("Skip")
                                .font(.keelCaption)
                        }
                        .foregroundStyle(K.Colors.secondary)
                        .padding(.horizontal, K.Spacing.md)
                        .padding(.vertical, K.Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: K.Radius.sharp)
                                .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
                        )
                    }

                    Spacer()
                }
                .padding(.top, K.Spacing.xs)
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

    // MARK: - Rest Day View

    private var restDayQuotes: [String] {
        [
            "Recovery is where the gains happen.",
            "Your muscles grow while you rest.",
            "Rest today, lift heavier tomorrow.",
            "Discipline includes knowing when to stop.",
            "You earned this. Enjoy it.",
            "Trust the process. Rest is part of it.",
            "Coming back stronger starts now.",
            "A well-rested body is a powerful body.",
            "Growth happens between the sessions.",
            "Champions know when to recover."
        ]
    }

    private var todayQuote: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return restDayQuotes[day % restDayQuotes.count]
    }

    @ViewBuilder
    private func restDayView(program: Program) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.lg) {
                    daySelectorBar(program: program)
                        .padding(.top, K.Spacing.md)

                    // Cardio section still available on rest days
                    cardioSection

                    VStack(spacing: K.Spacing.xl) {
                        Spacer(minLength: 20)

                        // Date and day
                        VStack(spacing: K.Spacing.xs) {
                            Text(Date().formatted(.dateTime.weekday(.wide)).uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(K.Colors.primary)
                                .tracking(2)
                            Text(Date().formatted(.dateTime.month(.wide).day()))
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.secondary)
                        }

                        Text("REST DAY")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(K.Colors.primary)
                            .tracking(4)

                        // Motivational quote
                        VStack(spacing: K.Spacing.xs) {
                            Text(aiQuote ?? todayQuote)
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, K.Spacing.xl)
                                .contentTransition(.opacity)

                            if isGeneratingQuote {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(K.Colors.tertiary)
                            }
                        }

                        // Week info
                        if let block = program.blockForWeek(effectiveWeek) {
                            Text("\(block.name) · Week \(effectiveWeek)")
                                .font(.keelCaption)
                                .foregroundStyle(K.Colors.tertiary)
                        }

                        Spacer(minLength: 20)

                        // Unmark rest day to show workout
                        if restDaySettings.isTempRestDay(Date()) {
                            Button {
                                withAnimation(K.Animation.fast) {
                                    restDaySettings.toggleTempRestDay(Date())
                                }
                            } label: {
                                HStack(spacing: K.Spacing.sm) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Undo Rest Day")
                                }
                                .font(.keelCaption)
                                .foregroundStyle(K.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, K.Spacing.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: K.Radius.sharp)
                                        .stroke(K.Colors.accent.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, K.Spacing.lg)
            }
        }
        .task {
            await generateQuoteIfNeeded()
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private func noWorkoutToday(program: Program) -> some View {
        VStack(spacing: 0) {
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

        // Start workout session on first set — only for today's actual workout
        let isCurrentDayAndWeek = selectedWeekOverride == nil && selectedDayIndex == nil
        if !workoutSession.isSessionActive && isCurrentDayAndWeek {
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

    private func skipSet(_ setLog: SetLog, exercise: Exercise, workout: Workout) {
        let service = ProgramService(modelContext: modelContext)
        service.skipSet(setLog)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Start workout session on first action — only for today's actual workout
        let isCurrentDayAndWeek = selectedWeekOverride == nil && selectedDayIndex == nil
        if !workoutSession.isSessionActive && isCurrentDayAndWeek {
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

    private func skipExercise(_ exercise: Exercise, workout: Workout) {
        let service = ProgramService(modelContext: modelContext)
        service.skipExercise(exercise)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Start workout session on first action — only for today's actual workout
        let isCurrentDayAndWeek = selectedWeekOverride == nil && selectedDayIndex == nil
        if !workoutSession.isSessionActive && isCurrentDayAndWeek {
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

    // MARK: - AI Quote Generation

    private static let quoteTextKey = "keel_aiQuoteText"
    private static let quoteTimestampKey = "keel_aiQuoteTimestamp"
    private static let quoteRefreshInterval: TimeInterval = 4 * 3600 // 4 hours

    private func generateQuoteIfNeeded() async {
        // Check cache first
        let cachedText = UserDefaults.standard.string(forKey: Self.quoteTextKey)
        let cachedTimestamp = UserDefaults.standard.double(forKey: Self.quoteTimestampKey)
        let now = Date().timeIntervalSince1970

        if let cachedText, now - cachedTimestamp < Self.quoteRefreshInterval {
            aiQuote = cachedText
            return
        }

        guard #available(iOS 26.0, *) else { return }
        await generateQuoteWithFoundationModels(now: now)
    }

    @available(iOS 26.0, *)
    private func generateQuoteWithFoundationModels(now: TimeInterval) async {
        // Check if on-device model is available
        guard SystemLanguageModel.default.isAvailable else { return }

        isGeneratingQuote = true
        defer { isGeneratingQuote = false }

        do {
            let session = LanguageModelSession(instructions: """
                You are a concise motivational coach for someone who lifts weights. \
                Generate a single short motivational sentence (under 15 words) about \
                rest day recovery, muscle growth, or coming back stronger. \
                No quotes, no attribution, just the sentence.
                """)

            let dayName = Date().formatted(.dateTime.weekday(.wide))
            let response = try await session.respond(to: "It's \(dayName), a rest day. Give me one motivational line.")

            let quote = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !quote.isEmpty else { return }

            withAnimation(K.Animation.fast) {
                aiQuote = quote
            }
            UserDefaults.standard.set(quote, forKey: Self.quoteTextKey)
            UserDefaults.standard.set(now, forKey: Self.quoteTimestampKey)
        } catch {
            // Silently fall back to hardcoded quote
        }
    }

}
