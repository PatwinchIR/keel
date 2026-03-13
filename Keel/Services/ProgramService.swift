import Foundation
import SwiftData

@Observable
final class ProgramService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Program Creation

    func createProgramFromBlueprint(_ blueprint: TemplateBlueprint, oneRepMaxes: [CompoundLift: Double]) -> Program {
        let program = Program(
            name: blueprint.name,
            totalWeeks: blueprint.totalWeeks,
            trainingDays: blueprint.defaultTrainingDays
        )
        modelContext.insert(program)

        for blockBP in blueprint.blocks {
            let block = Block(
                name: blockBP.name,
                weekStart: blockBP.weekStart,
                weekEnd: blockBP.weekEnd,
                description: blockBP.description
            )
            block.program = program
            program.blocks.append(block)
        }

        for weekBP in blueprint.weeks {
            for workoutBP in weekBP.workouts {
                let workout = Workout(
                    name: workoutBP.name,
                    weekNumber: weekBP.weekNumber,
                    dayIndex: workoutBP.dayIndex
                )
                workout.program = program
                program.workouts.append(workout)

                for exBP in workoutBP.exercises {
                    let exercise = Exercise(
                        name: exBP.name,
                        orderIndex: exBP.orderIndex,
                        tag: exBP.tag,
                        warmupSets: exBP.warmupSets,
                        workingSets: exBP.workingSets,
                        targetReps: exBP.targetReps,
                        loadType: exBP.loadType,
                        percentage: exBP.percentage,
                        percentageOf: exBP.percentageOf,
                        rpeTarget: exBP.rpeTarget,
                        restPeriod: exBP.restPeriod,
                        notes: exBP.notes,
                        substitutions: exBP.substitutions,
                        isBodyweight: exBP.isBodyweight,
                        isDumbbell: exBP.isDumbbell,
                        muscleGroups: exBP.muscleGroups
                    )
                    exercise.workout = workout
                    workout.exercises.append(exercise)

                    // Pre-create set logs
                    createSetLogs(for: exercise, oneRepMaxes: oneRepMaxes)
                }
            }
        }

        // Lock initial 1RMs to the program for this cycle
        program.lockedOneRepMaxes = oneRepMaxes

        try? modelContext.save()
        return program
    }

    private func createSetLogs(for exercise: Exercise, oneRepMaxes: [CompoundLift: Double]) {
        var setNumber = 0

        // Working weight calculation
        let calculatedWeight: Double? = {
            if let lift = exercise.percentageOf, let pct = exercise.percentage, let orm = oneRepMaxes[lift] {
                return (orm * pct / 5).rounded() * 5
            }
            return nil
        }()

        // Warmup sets — use plate-based progression for barbell exercises,
        // percentage-based for dumbbell/bodyweight/no-calculated-weight
        let isBarbell = !exercise.isBodyweight && !exercise.isDumbbell
        let warmupReps = WarmupDefaults.reps(for: exercise.warmupSets)

        let warmupWeights: [Double?]
        if isBarbell, let working = calculatedWeight {
            warmupWeights = WarmupDefaults.barbellWarmupWeights(
                workingWeight: working,
                warmupCount: exercise.warmupSets
            ).map { Optional($0) }
        } else {
            let warmupPercentages = WarmupDefaults.percentages(
                for: exercise.name,
                warmupCount: exercise.warmupSets
            )
            warmupWeights = (0..<exercise.warmupSets).map { i in
                guard let working = calculatedWeight, i < warmupPercentages.count else { return nil }
                return (working * warmupPercentages[i] / 5).rounded() * 5
            }
        }

        for i in 0..<exercise.warmupSets {
            let reps = i < warmupReps.count ? warmupReps[i] : 5
            let weight = i < warmupWeights.count ? warmupWeights[i] : nil
            let log = SetLog(setNumber: setNumber, setType: .warmup, weight: weight, reps: reps)
            log.exercise = exercise
            exercise.setLogs.append(log)
            setNumber += 1
        }

        // Working sets
        let targetReps = parseTargetReps(exercise.targetReps)

        for _ in 0..<exercise.workingSets {
            let log = SetLog(
                setNumber: setNumber,
                setType: .working,
                weight: calculatedWeight,
                reps: targetReps
            )
            log.exercise = exercise
            exercise.setLogs.append(log)
            setNumber += 1
        }
    }

    private func parseTargetReps(_ reps: String) -> Int? {
        if let n = Int(reps) { return n }
        // For ranges like "3-5", use the lower bound
        if reps.contains("-"), let first = reps.split(separator: "-").first, let n = Int(first) {
            return n
        }
        return nil
    }

    // MARK: - Auto Week/Cycle Advancement

    /// Checks if a new calendar week (Monday) has started since the last check.
    /// If so, advances the program week — or starts a new cycle if at the end.
    func checkWeekTransition() {
        guard let program = activeProgram() else { return }

        let cal = Calendar(identifier: .iso8601) // ISO weeks start on Monday
        let now = Date()
        let key = "keel_lastWeekCheckDate"
        let lastCheckInterval = UserDefaults.standard.double(forKey: key)

        // First launch — store current date, no advancement
        guard lastCheckInterval > 0 else {
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: key)
            return
        }

        let lastCheck = Date(timeIntervalSince1970: lastCheckInterval)

        // Get start-of-week (Monday) for both dates
        guard let lastWeekStart = cal.dateInterval(of: .weekOfYear, for: lastCheck)?.start,
              let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return }

        // Same week — no action
        guard thisWeekStart > lastWeekStart else { return }

        // Number of full weeks between the two Mondays
        let daysBetween = cal.dateComponents([.day], from: lastWeekStart, to: thisWeekStart).day ?? 0
        let weeksPassed = max(1, daysBetween / 7)

        for _ in 0..<weeksPassed {
            if program.currentWeek < program.totalWeeks {
                program.currentWeek += 1
            } else {
                // Cycle complete — auto-start new cycle with latest 1RMs
                let maxes = currentOneRepMaxes()
                startNewCycle(program, newOneRepMaxes: maxes)
            }
        }

        try? modelContext.save()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: key)
    }

    // MARK: - Week Management

    func setWeek(_ program: Program, to week: Int) {
        let clamped = max(1, min(week, program.totalWeeks))
        program.currentWeek = clamped
        try? modelContext.save()
    }

    /// Derives the current cycle number from the max record count across all lifts.
    func syncCycleNumber() {
        guard let program = activeProgram() else { return }
        var maxCount = 0
        for lift in CompoundLift.allCases {
            let count = oneRepMaxHistory(for: lift).count
            maxCount = max(maxCount, count)
        }
        let derived = max(1, maxCount)
        if program.currentCycleNumber != derived {
            program.currentCycleNumber = derived
            try? modelContext.save()
        }
    }

    /// One-time lock of current 1RMs to the active program (for migration)
    func migrateLockedOneRepMaxes() {
        guard let program = activeProgram(), program.lockedOneRepMaxesData == nil else { return }
        program.lockedOneRepMaxes = currentOneRepMaxes()
        try? modelContext.save()
    }

    /// One-time rename of exercise names to match CompoundLift.displayName
    func migrateExerciseNames() {
        let renames = ["Barbell Bench Press": "Bench Press"]
        guard let program = activeProgram() else { return }
        var changed = false
        for workout in program.workouts {
            for exercise in workout.exercises {
                if let newName = renames[exercise.name] {
                    exercise.name = newName
                    changed = true
                }
            }
        }
        if changed { try? modelContext.save() }
    }

    func advanceWeek(_ program: Program) {
        if program.currentWeek < program.totalWeeks {
            program.currentWeek += 1
            try? modelContext.save()
        }
    }

    func startNewCycle(_ program: Program, newOneRepMaxes: [CompoundLift: Double]) {
        program.currentWeek = 1
        program.currentCycleNumber += 1

        // Lock the new 1RMs for this cycle
        program.lockedOneRepMaxes = newOneRepMaxes

        // Reset the week-check date so checkWeekTransition doesn't re-advance
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "keel_lastWeekCheckDate")

        // Recalculate all percentage-based loads
        for workout in program.workouts {
            for exercise in workout.exercises {
                if exercise.loadType == .percentage,
                   let lift = exercise.percentageOf,
                   let pct = exercise.percentage,
                   let orm = newOneRepMaxes[lift] {
                    let newWeight = (orm * pct / 5).rounded() * 5
                    for log in exercise.setLogs where log.setType == .working {
                        log.weight = newWeight
                        log.isCompleted = false
                        log.completedAt = nil
                        log.rpe = nil
                        log.note = nil
                    }
                    let warmupLogs = exercise.setLogs.filter { $0.setType == .warmup }.sorted { $0.setNumber < $1.setNumber }
                    let warmupRepScheme = WarmupDefaults.reps(for: warmupLogs.count)
                    let isBarbell = !exercise.isBodyweight && !exercise.isDumbbell

                    let warmupWeights: [Double?]
                    if isBarbell {
                        warmupWeights = WarmupDefaults.barbellWarmupWeights(
                            workingWeight: newWeight,
                            warmupCount: warmupLogs.count
                        ).map { Optional($0) }
                    } else {
                        let warmupPcts = WarmupDefaults.percentages(for: exercise.name, warmupCount: warmupLogs.count)
                        warmupWeights = warmupPcts.map { (newWeight * $0 / 5).rounded() * 5 }
                    }

                    for (i, log) in warmupLogs.enumerated() {
                        log.isCompleted = false
                        log.completedAt = nil
                        log.weight = i < warmupWeights.count ? warmupWeights[i] : nil
                        log.reps = i < warmupRepScheme.count ? warmupRepScheme[i] : 5
                    }
                } else {
                    // Reset RPE-based exercise logs
                    for log in exercise.setLogs {
                        log.isCompleted = false
                        log.completedAt = nil
                        log.rpe = nil
                        log.note = nil
                    }
                }
            }
            workout.isCompleted = false
            workout.completedAt = nil
            workout.startedAt = nil
        }

        try? modelContext.save()
    }

    // MARK: - Workout Completion

    func completeWorkout(_ workout: Workout, bodyWeight: Double? = nil) {
        // Snapshot BEFORE marking complete
        if let program = workout.program {
            snapshotWorkout(workout, program: program, bodyWeight: bodyWeight)
        }
        workout.isCompleted = true
        workout.completedAt = Date()
        try? modelContext.save()
    }

    func completeWeek(_ program: Program, week: Int) {
        let now = Date()
        let workouts = program.workoutsForWeek(week)
        for workout in workouts where !workout.isCompleted {
            for exercise in workout.exercises {
                for log in exercise.setLogs where !log.isCompleted {
                    log.isCompleted = true
                    log.completedAt = now
                }
            }
            if workout.startedAt == nil {
                workout.startedAt = now
            }
            // Snapshot before marking complete
            snapshotWorkout(workout, program: program, bodyWeight: nil)
            workout.isCompleted = true
            workout.completedAt = now
        }
        try? modelContext.save()
    }

    func markSetComplete(_ setLog: SetLog) {
        setLog.isCompleted = true
        setLog.completedAt = Date()

        // Mark workout start time if this is the first completed set
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           workout.startedAt == nil {
            workout.startedAt = Date()
        }

        try? modelContext.save()

        // Update the live snapshot so partial workouts are always captured
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           let program = workout.program {
            snapshotWorkout(workout, program: program)
        }
    }

    func skipSet(_ setLog: SetLog) {
        setLog.isCompleted = true
        setLog.isSkipped = true
        setLog.completedAt = Date()

        // Mark workout start time if this is the first completed set
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           workout.startedAt == nil {
            workout.startedAt = Date()
        }

        try? modelContext.save()

        // Update the live snapshot so partial workouts are always captured
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           let program = workout.program {
            snapshotWorkout(workout, program: program)
        }
    }

    func skipExercise(_ exercise: Exercise) {
        let now = Date()
        for setLog in exercise.setLogs where !setLog.isCompleted {
            setLog.isCompleted = true
            setLog.isSkipped = true
            setLog.completedAt = now
        }

        if let workout = exercise.workout, workout.startedAt == nil {
            workout.startedAt = now
        }

        try? modelContext.save()

        // Update the live snapshot so partial workouts are always captured
        if let workout = exercise.workout,
           let program = workout.program {
            snapshotWorkout(workout, program: program)
        }
    }

    func unmarkSetComplete(_ setLog: SetLog) {
        setLog.isCompleted = false
        setLog.isSkipped = false
        setLog.completedAt = nil

        // If workout was marked complete, undo that too
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           workout.isCompleted {
            workout.isCompleted = false
            workout.completedAt = nil
        }

        try? modelContext.save()

        // Update or remove the snapshot
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           let program = workout.program {
            let hasAnyCompleted = workout.exercises.contains { ex in
                ex.setLogs.contains { $0.isCompleted }
            }
            if hasAnyCompleted {
                snapshotWorkout(workout, program: program)
            } else {
                deleteSnapshotForWorkout(workout, program: program)
            }
        }
    }

    func cancelWorkout(_ workout: Workout) {
        // Delete the snapshot before resetting — cancelling discards the data
        if let program = workout.program {
            deleteSnapshotForWorkout(workout, program: program)
        }

        for exercise in workout.exercises {
            for log in exercise.setLogs {
                log.isCompleted = false
                log.isSkipped = false
                log.completedAt = nil
                log.rpe = nil
                log.note = nil
            }
        }
        workout.isCompleted = false
        workout.completedAt = nil
        workout.startedAt = nil
        try? modelContext.save()
    }

    /// Deletes today's snapshot for a specific workout (used when cancelling or unchecking all sets).
    private func deleteSnapshotForWorkout(_ workout: Workout, program: Program) {
        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let pName = program.name
        let cycle = program.currentCycleNumber
        let week = workout.weekNumber
        let day = workout.dayIndex

        let descriptor = FetchDescriptor<WorkoutHistory>(
            predicate: #Predicate<WorkoutHistory> {
                $0.programName == pName &&
                $0.cycleNumber == cycle &&
                $0.weekNumber == week &&
                $0.dayIndex == day &&
                $0.completedAt >= dayStart &&
                $0.completedAt < dayEnd
            }
        )
        if let existing = try? modelContext.fetch(descriptor) {
            for old in existing {
                modelContext.delete(old)
            }
            try? modelContext.save()
        }
    }

    // MARK: - 1RM

    func currentOneRepMax(for lift: CompoundLift) -> OneRepMax? {
        let liftRaw = lift.rawValue
        let descriptor = FetchDescriptor<OneRepMax>(
            predicate: #Predicate { $0.liftRaw == liftRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    func currentOneRepMaxes() -> [CompoundLift: Double] {
        var result: [CompoundLift: Double] = [:]
        for lift in CompoundLift.allCases {
            if let orm = currentOneRepMax(for: lift) {
                result[lift] = orm.weight
            }
        }
        return result
    }

    func saveOneRepMax(lift: CompoundLift, weight: Double, date: Date = Date(), cycleNumber: Int, note: String? = nil) {
        let orm = OneRepMax(lift: lift, weight: weight, date: date, cycleNumber: cycleNumber, note: note)
        modelContext.insert(orm)
        try? modelContext.save()
    }

    func deleteOneRepMax(_ record: OneRepMax) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    func oneRepMaxHistory(for lift: CompoundLift) -> [OneRepMax] {
        let liftRaw = lift.rawValue
        let descriptor = FetchDescriptor<OneRepMax>(
            predicate: #Predicate { $0.liftRaw == liftRaw },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Active Program

    func activeProgram() -> Program? {
        let descriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Cardio

    func addCardioLog(type: CardioType, durationMinutes: Int, notes: String? = nil, date: Date = Date()) {
        let log = CardioLog(type: type, date: date, durationMinutes: durationMinutes, notes: notes)
        modelContext.insert(log)
        try? modelContext.save()
    }

    func cardioLogsForDate(_ date: Date) -> [CardioLog] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let descriptor = FetchDescriptor<CardioLog>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteCardioLog(_ log: CardioLog) {
        modelContext.delete(log)
        try? modelContext.save()
    }

    // MARK: - Previous Performance

    func previousPerformance(exerciseName: String, programId: UUID, currentWeek: Int) -> [SetLog]? {
        guard let program = activeProgram() else { return nil }

        // Find the same exercise in the previous week
        let previousWeek = currentWeek - 1
        guard previousWeek >= 1 else { return nil }

        let workouts = program.workoutsForWeek(previousWeek)
        for workout in workouts {
            for exercise in workout.exercises {
                let nameToMatch = exercise.activeSubstitution ?? exercise.name
                if nameToMatch == exerciseName {
                    return exercise.sortedSetLogs.filter { $0.setType == .working && $0.isCompleted }
                }
            }
        }
        return nil
    }

    // MARK: - Exercise History (Charts)

    /// Returns all completed working sets for a given exercise name across all programs.
    /// Checks both `name` and `activeSubstitution` for matches.
    func allCompletedWorkingSets(exerciseName: String) -> [SetLog] {
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return [] }

        var result: [SetLog] = []
        for exercise in exercises {
            let displayName = exercise.activeSubstitution ?? exercise.name
            guard displayName == exerciseName || exercise.name == exerciseName else { continue }
            let completed = exercise.setLogs.filter { log in
                log.setType == .working && log.isCompleted && log.weight != nil && log.reps != nil
            }
            result.append(contentsOf: completed)
        }
        return result.sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
    }

    /// Derives estimated 1RM per day for a non-compound exercise from SetLog data.
    /// Groups completed working sets by day and takes the max Brzycki estimate per day.
    func estimatedOneRMHistory(exerciseName: String) -> [(date: Date, estimated1RM: Double)] {
        let sets = allCompletedWorkingSets(exerciseName: exerciseName)
        let calendar = Calendar.current

        var grouped: [Date: Double] = [:]
        for setLog in sets {
            guard let weight = setLog.weight, let reps = setLog.reps, reps > 0, weight > 0 else { continue }
            let estimate = OneRepMax.brzyckiEstimate(weight: weight, reps: reps)
            let day = calendar.startOfDay(for: setLog.completedAt ?? Date())
            grouped[day] = max(grouped[day] ?? 0, estimate)
        }

        return grouped.map { (date: $0.key, estimated1RM: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// Returns all distinct exercise display names that have at least one completed working set.
    func allExerciseNames() -> [String] {
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return [] }

        var names = Set<String>()
        for exercise in exercises {
            let displayName = exercise.activeSubstitution ?? exercise.name
            let hasCompleted = exercise.setLogs.contains { $0.setType == .working && $0.isCompleted }
            if hasCompleted {
                names.insert(displayName)
            }
        }
        return names.sorted()
    }

    // MARK: - Workout History Snapshot

    /// Creates or updates a permanent WorkoutHistory snapshot from a workout.
    /// Called on every set completion so partial workouts are always captured.
    /// Only snapshots if the workout has at least one completed set.
    func snapshotWorkout(_ workout: Workout, program: Program, bodyWeight: Double? = nil) {
        // Only snapshot if at least one set has been completed
        let hasCompletedSets = workout.exercises.contains { exercise in
            exercise.setLogs.contains { $0.isCompleted }
        }
        guard hasCompletedSets else { return }

        // Delete any existing snapshot for the same workout on the same calendar day
        // so we can replace it with the latest state.
        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let pName = program.name
        let cycle = program.currentCycleNumber
        let week = workout.weekNumber
        let day = workout.dayIndex

        let descriptor = FetchDescriptor<WorkoutHistory>(
            predicate: #Predicate<WorkoutHistory> {
                $0.programName == pName &&
                $0.cycleNumber == cycle &&
                $0.weekNumber == week &&
                $0.dayIndex == day &&
                $0.completedAt >= dayStart &&
                $0.completedAt < dayEnd
            }
        )
        if let existing = try? modelContext.fetch(descriptor) {
            for old in existing {
                modelContext.delete(old)
            }
        }

        let startedAt = workout.startedAt ?? now
        let completedAt = now
        let duration = Int(completedAt.timeIntervalSince(startedAt))

        let blockName = program.blockForWeek(workout.weekNumber)?.name

        let history = WorkoutHistory(
            programName: program.name,
            workoutName: workout.name,
            weekNumber: workout.weekNumber,
            dayIndex: workout.dayIndex,
            cycleNumber: program.currentCycleNumber,
            blockName: blockName,
            startedAt: startedAt,
            completedAt: completedAt,
            durationSeconds: max(0, duration),
            bodyWeight: bodyWeight
        )
        modelContext.insert(history)

        // Collect all completed set logs with timestamps for rest time calculation
        var allCompletedSetLogs: [(setHistory: SetHistory, completedAt: Date)] = []

        for exercise in workout.sortedExercises {
            let lockedMaxes = program.lockedOneRepMaxes
            let oneRM: Double? = exercise.percentageOf.flatMap { lockedMaxes[$0] }

            for setLog in exercise.sortedSetLogs {
                let setHistory = SetHistory(
                    exerciseName: exercise.displayName,
                    originalExerciseName: exercise.name,
                    exerciseOrderIndex: exercise.orderIndex,
                    setNumber: setLog.setNumber,
                    setType: setLog.setType,
                    tag: exercise.tag,
                    weight: setLog.weight,
                    reps: setLog.reps,
                    rpe: setLog.rpe,
                    isSkipped: setLog.isSkipped,
                    completedAt: setLog.completedAt,
                    note: setLog.note,
                    targetReps: exercise.targetReps,
                    rpeTarget: exercise.rpeTarget,
                    percentageUsed: exercise.percentage,
                    oneRMAtTime: oneRM,
                    muscleGroups: exercise.muscleGroups
                )
                setHistory.workoutHistory = history
                history.sets.append(setHistory)

                if let completedAt = setLog.completedAt {
                    allCompletedSetLogs.append((setHistory: setHistory, completedAt: completedAt))
                }
            }
        }

        // Compute rest times globally across the workout
        let sorted = allCompletedSetLogs.sorted { $0.completedAt < $1.completedAt }
        for i in 0..<sorted.count {
            if i < sorted.count - 1 {
                let gap = Int(sorted[i + 1].completedAt.timeIntervalSince(sorted[i].completedAt))
                // Ignore gaps > 600s (breaks) or < 5s (logging artifacts)
                if gap >= 5 && gap <= 600 {
                    sorted[i].setHistory.restSecondsToNext = gap
                }
            }
        }

        try? modelContext.save()
    }

    /// One-time migration: snapshot all currently-completed workouts that don't have history yet.
    func migrateExistingWorkoutHistory() {
        let key = "keel_workoutHistoryMigrated"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        guard let program = activeProgram() else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        let completedWorkouts = program.workouts.filter(\.isCompleted)
        for workout in completedWorkouts {
            snapshotWorkout(workout, program: program, bodyWeight: nil)
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Workout History Queries

    func allWorkoutHistory() -> [WorkoutHistory] {
        let descriptor = FetchDescriptor<WorkoutHistory>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func workoutHistory(named: String) -> [WorkoutHistory] {
        let descriptor = FetchDescriptor<WorkoutHistory>(
            predicate: #Predicate { $0.workoutName == named },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func workoutHistory(cycle: Int) -> [WorkoutHistory] {
        let descriptor = FetchDescriptor<WorkoutHistory>(
            predicate: #Predicate { $0.cycleNumber == cycle },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func workoutHistory(from: Date, to: Date) -> [WorkoutHistory] {
        let descriptor = FetchDescriptor<WorkoutHistory>(
            predicate: #Predicate { $0.completedAt >= from && $0.completedAt <= to },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func distinctWorkoutNames() -> [String] {
        let all = allWorkoutHistory()
        let names = Set(all.map(\.workoutName))
        return names.sorted()
    }

    func totalVolume(cycle: Int? = nil) -> Double {
        let history = cycle.map { workoutHistory(cycle: $0) } ?? allWorkoutHistory()
        return history.reduce(0) { $0 + $1.totalVolume }
    }

    func averageDuration(cycle: Int? = nil) -> Double {
        let history = cycle.map { workoutHistory(cycle: $0) } ?? allWorkoutHistory()
        guard !history.isEmpty else { return 0 }
        let total = history.reduce(0) { $0 + $1.durationSeconds }
        return Double(total) / Double(history.count)
    }

    func workoutCount(cycle: Int? = nil) -> Int {
        let history = cycle.map { workoutHistory(cycle: $0) } ?? allWorkoutHistory()
        return history.count
    }

    func exerciseVolumeHistory(exerciseName: String) -> [(date: Date, volume: Double)] {
        let all = allWorkoutHistory()
        var result: [(date: Date, volume: Double)] = []
        for wh in all {
            let exerciseSets = wh.sets.filter { $0.exerciseName == exerciseName && !$0.isSkipped && $0.setType == .working }
            if !exerciseSets.isEmpty {
                let vol = exerciseSets.reduce(0.0) { $0 + $1.volume }
                result.append((date: wh.completedAt, volume: vol))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    func workoutTrends(named: String? = nil, timeRange: TimeRange? = nil) -> [(date: Date, volume: Double, durationMinutes: Int, avgRestSeconds: Double?)] {
        var history: [WorkoutHistory]
        if let name = named {
            history = workoutHistory(named: name)
        } else {
            history = allWorkoutHistory()
        }

        if let floor = timeRange?.dateFloor {
            history = history.filter { $0.completedAt >= floor }
        }

        return history.map { wh in
            (date: wh.completedAt, volume: wh.totalVolume, durationMinutes: wh.durationSeconds / 60, avgRestSeconds: wh.averageRestSeconds)
        }.sorted { $0.date < $1.date }
    }

    func averageRestTime(cycle: Int? = nil) -> Double? {
        let history = cycle.map { workoutHistory(cycle: $0) } ?? allWorkoutHistory()
        let restValues = history.compactMap(\.averageRestSeconds)
        guard !restValues.isEmpty else { return nil }
        return restValues.reduce(0, +) / Double(restValues.count)
    }

    func totalTrainingHours(cycle: Int? = nil) -> Double {
        let history = cycle.map { workoutHistory(cycle: $0) } ?? allWorkoutHistory()
        let totalSeconds = history.reduce(0) { $0 + $1.durationSeconds }
        return Double(totalSeconds) / 3600.0
    }

    func deleteWorkoutHistory(_ record: WorkoutHistory) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    /// Builds estimated 1RM history for ALL exercises in a single fetch pass.
    /// Returns a dictionary mapping exercise display name to its daily max estimated 1RM entries.
    func allEstimatedOneRMHistories() -> [String: [(date: Date, estimated1RM: Double)]] {
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return [:] }

        let calendar = Calendar.current
        // exerciseName -> (day -> maxEstimate)
        var grouped: [String: [Date: Double]] = [:]

        for exercise in exercises {
            let displayName = exercise.activeSubstitution ?? exercise.name
            for log in exercise.setLogs {
                guard log.setType == .working,
                      log.isCompleted,
                      let weight = log.weight, weight > 0,
                      let reps = log.reps, reps > 0 else { continue }

                let estimate = OneRepMax.brzyckiEstimate(weight: weight, reps: reps)
                let day = calendar.startOfDay(for: log.completedAt ?? Date())
                grouped[displayName, default: [:]][day] = max(grouped[displayName, default: [:]][day] ?? 0, estimate)
            }
        }

        return grouped.mapValues { dayMap in
            dayMap.map { (date: $0.key, estimated1RM: $0.value) }
                .sorted { $0.date < $1.date }
        }
    }
}

// MARK: - Warmup Defaults

enum WarmupDefaults {
    /// Default pyramid percentages of working weight by warmup count
    private static let defaultPyramids: [Int: [Double]] = [
        1: [0.60],
        2: [0.50, 0.70],
        3: [0.40, 0.60, 0.80],
        4: [0.40, 0.55, 0.70, 0.80],
        5: [0.30, 0.45, 0.55, 0.70, 0.80],
    ]

    /// Descending rep scheme for warmup sets: start high, taper down toward working reps.
    private static let defaultReps: [Int: [Int]] = [
        1: [8],
        2: [12, 8],
        3: [12, 10, 8],
        4: [12, 10, 8, 6],
        5: [12, 10, 8, 6, 5],
    ]

    /// Returns the rep counts for each warmup set (descending from 12).
    static func reps(for warmupCount: Int) -> [Int] {
        if let preset = defaultReps[warmupCount] { return preset }
        guard warmupCount > 0 else { return [] }
        // Generate descending reps from 12 down to 5 for any count
        return (0..<warmupCount).map { i in
            let start = 12
            let end = 5
            let step = warmupCount > 1 ? Double(start - end) / Double(warmupCount - 1) : 0
            return max(end, start - Int((step * Double(i)).rounded()))
        }
    }

    private static let userDefaultsKey = "customWarmupWeights"

    /// Returns pyramid percentages for an exercise. If the user has saved custom
    /// weights for this exercise, returns those as percentages of working weight.
    /// Otherwise returns default pyramid percentages.
    static func percentages(for exerciseName: String, warmupCount: Int) -> [Double] {
        // Check for user-saved custom percentages
        if let saved = savedPercentages(for: exerciseName), saved.count == warmupCount {
            return saved
        }
        return defaultPyramids[warmupCount] ?? defaultPyramid(count: warmupCount)
    }

    /// Generates a default pyramid for any warmup count not in the table
    private static func defaultPyramid(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        return (0..<count).map { i in
            let start = 0.40
            let end = 0.80
            let step = count > 1 ? (end - start) / Double(count - 1) : 0
            return start + step * Double(i)
        }
    }

    /// Plate-based warmup weights for barbell exercises.
    /// Builds warmup sets by progressively adding plates toward the working weight:
    ///   W1: bar only (45 lbs)
    ///   W2: bar + 25 per side (95 lbs)
    ///   W3: bar + 45 per side (135 lbs)
    ///   ... continuing until close to working weight
    /// Returns actual weight values (not percentages).
    static func barbellWarmupWeights(workingWeight: Double, warmupCount: Int, barWeight: Double = 45) -> [Double] {
        guard warmupCount > 0, workingWeight > barWeight else {
            return Array(repeating: barWeight, count: warmupCount)
        }

        // Standard plate landmarks: bar, bar+25/side, bar+45/side,
        // bar+45+25/side, bar+45+45/side, etc.
        // For 45lb bar: 45, 95, 135, 185, 225, 275, 315, 365...
        let landmarks: [Double] = {
            var result: [Double] = [barWeight]
            // Alternating: +25 per side, then swap to next 45 per side
            var platesPerSide: [Double] = []
            let availablePlates: [Double] = [25, 45, 25, 45, 25, 45, 25, 45]
            for plate in availablePlates {
                if plate == 25 {
                    platesPerSide.append(plate)
                } else {
                    // Replace the last 25 with a 45
                    if let lastIdx = platesPerSide.lastIndex(of: 25) {
                        platesPerSide[lastIdx] = 45
                    } else {
                        platesPerSide.append(45)
                    }
                }
                let total = barWeight + platesPerSide.reduce(0, +) * 2
                result.append(total)
            }
            return result
        }()

        // Filter to landmarks below working weight
        let rungs = landmarks.filter { $0 < workingWeight }

        if rungs.count <= warmupCount {
            // Not enough rungs — fill remaining with evenly spaced weights
            var result = rungs
            let remaining = warmupCount - result.count
            if remaining > 0 {
                let lastRung = result.last ?? barWeight
                let gap = workingWeight - lastRung
                for i in 1...remaining {
                    let w = lastRung + gap * Double(i) / Double(remaining + 1)
                    result.append((w / 5).rounded() * 5)
                }
            }
            return result
        } else {
            // More rungs than warmup sets — always start with bar,
            // then pick from the remaining rungs closest to working weight
            var result: [Double] = [barWeight]
            let tail = Array(rungs.suffix(warmupCount - 1))
            result.append(contentsOf: tail)
            return result
        }
    }

    /// Save user-edited warmup weights as percentages of working weight
    static func saveCustomPercentages(for exerciseName: String, percentages: [Double]) {
        var all = allSavedPercentages()
        all[exerciseName] = percentages
        UserDefaults.standard.set(all, forKey: userDefaultsKey)
    }

    static func savedPercentages(for exerciseName: String) -> [Double]? {
        allSavedPercentages()[exerciseName]
    }

    private static func allSavedPercentages() -> [String: [Double]] {
        UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: [Double]] ?? [:]
    }
}
