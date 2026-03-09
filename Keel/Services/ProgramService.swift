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
                        substitutions: exBP.substitutions
                    )
                    exercise.workout = workout
                    workout.exercises.append(exercise)

                    // Pre-create set logs
                    createSetLogs(for: exercise, oneRepMaxes: oneRepMaxes)
                }
            }
        }

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

        // Warmup sets — populate with pyramid percentages of working weight
        let warmupPercentages = WarmupDefaults.percentages(
            for: exercise.name,
            warmupCount: exercise.warmupSets
        )
        for i in 0..<exercise.warmupSets {
            let warmupWeight: Double? = {
                guard let working = calculatedWeight, i < warmupPercentages.count else { return nil }
                return (working * warmupPercentages[i] / 5).rounded() * 5
            }()
            let log = SetLog(setNumber: setNumber, setType: .warmup, weight: warmupWeight, reps: 5)
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

    // MARK: - Week Management

    func setWeek(_ program: Program, to week: Int) {
        let clamped = max(1, min(week, program.totalWeeks))
        program.currentWeek = clamped
        try? modelContext.save()
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
                    for log in exercise.setLogs where log.setType == .warmup {
                        log.isCompleted = false
                        log.completedAt = nil
                        log.weight = nil
                        log.reps = nil
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

    func completeWorkout(_ workout: Workout) {
        workout.isCompleted = true
        workout.completedAt = Date()
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
    }

    func unmarkSetComplete(_ setLog: SetLog) {
        setLog.isCompleted = false
        setLog.completedAt = nil

        // If workout was marked complete, undo that too
        if let exercise = setLog.exercise,
           let workout = exercise.workout,
           workout.isCompleted {
            workout.isCompleted = false
            workout.completedAt = nil
        }

        try? modelContext.save()
    }

    func cancelWorkout(_ workout: Workout) {
        for exercise in workout.exercises {
            for log in exercise.setLogs {
                log.isCompleted = false
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

    func saveOneRepMax(lift: CompoundLift, weight: Double, cycleNumber: Int, note: String? = nil) {
        let orm = OneRepMax(lift: lift, weight: weight, cycleNumber: cycleNumber, note: note)
        modelContext.insert(orm)
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
