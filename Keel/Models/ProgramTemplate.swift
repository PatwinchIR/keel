import Foundation
import SwiftData

@Model
final class ProgramTemplate {
    var id: UUID
    var name: String
    var templateDescription: String?
    var totalWeeks: Int
    var defaultTrainingDaysRaw: [Int]
    var isBuiltIn: Bool
    var createdAt: Date
    var templateData: Data?

    var defaultTrainingDays: [TrainingDay] {
        get { defaultTrainingDaysRaw.compactMap { TrainingDay(rawValue: $0) }.sorted() }
        set { defaultTrainingDaysRaw = newValue.map(\.rawValue) }
    }

    init(
        name: String,
        description: String? = nil,
        totalWeeks: Int = 10,
        defaultTrainingDays: [TrainingDay] = [.monday, .tuesday, .wednesday, .friday, .saturday],
        isBuiltIn: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.templateDescription = description
        self.totalWeeks = totalWeeks
        self.defaultTrainingDaysRaw = defaultTrainingDays.map(\.rawValue)
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
    }
}

// MARK: - Template Blueprint (non-persisted, used to generate programs)

struct TemplateBlueprint: Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let totalWeeks: Int
    let defaultTrainingDays: [TrainingDay]
    let blocks: [BlockBlueprint]
    let weeks: [WeekBlueprint]
}

struct BlockBlueprint {
    let name: String
    let weekStart: Int
    let weekEnd: Int
    let description: String?
}

struct WeekBlueprint {
    let weekNumber: Int
    let workouts: [WorkoutBlueprint]
}

struct WorkoutBlueprint {
    let name: String
    let dayIndex: Int
    let exercises: [ExerciseBlueprint]
}

struct ExerciseBlueprint {
    let name: String
    let orderIndex: Int
    let tag: ExerciseTag?
    let warmupSets: Int
    let workingSets: Int
    let targetReps: String
    let loadType: LoadType
    let percentage: Double?
    let percentageOf: CompoundLift?
    let rpeTarget: String?
    let restPeriod: String
    let notes: String
    let substitutions: [String]
    let isBodyweight: Bool
    let isDumbbell: Bool

    init(
        name: String,
        orderIndex: Int,
        tag: ExerciseTag? = nil,
        warmupSets: Int = 0,
        workingSets: Int = 3,
        targetReps: String = "8",
        loadType: LoadType = .rpe,
        percentage: Double? = nil,
        percentageOf: CompoundLift? = nil,
        rpeTarget: String? = nil,
        restPeriod: String = "2-3 min",
        notes: String = "",
        substitutions: [String] = [],
        isBodyweight: Bool = false,
        isDumbbell: Bool = false
    ) {
        self.name = name
        self.orderIndex = orderIndex
        self.tag = tag
        self.warmupSets = warmupSets
        self.workingSets = workingSets
        self.targetReps = targetReps
        self.loadType = loadType
        self.percentage = percentage
        self.percentageOf = percentageOf
        self.rpeTarget = rpeTarget
        self.restPeriod = restPeriod
        self.notes = notes
        self.substitutions = substitutions
        self.isBodyweight = isBodyweight
        self.isDumbbell = isDumbbell
    }
}
