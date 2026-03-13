import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var orderIndex: Int
    var tagRaw: String?
    var warmupSets: Int
    var workingSets: Int
    var targetReps: String
    var loadTypeRaw: String
    var percentage: Double?
    var percentageOfRaw: String?
    var rpeTarget: String?
    var restPeriod: String
    var notes: String
    var substitutions: [String]
    var isBodyweight: Bool = false
    var isDumbbell: Bool = false
    var muscleGroupsRaw: [String] = []
    var activeSubstitution: String?
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var setLogs: [SetLog]

    var tag: ExerciseTag? {
        get { tagRaw.flatMap { ExerciseTag(rawValue: $0) } }
        set { tagRaw = newValue?.rawValue }
    }

    var loadType: LoadType {
        get { LoadType(rawValue: loadTypeRaw) ?? .rpe }
        set { loadTypeRaw = newValue.rawValue }
    }

    var percentageOf: CompoundLift? {
        get { percentageOfRaw.flatMap { CompoundLift(rawValue: $0) } }
        set { percentageOfRaw = newValue?.rawValue }
    }

    var muscleGroups: [MuscleGroup] {
        muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) }
    }

    var displayName: String {
        activeSubstitution ?? name
    }

    var totalSets: Int { warmupSets + workingSets }

    var sortedSetLogs: [SetLog] {
        setLogs.sorted { $0.setNumber < $1.setNumber }
    }

    func calculatedLoad(oneRepMax: Double) -> Double? {
        guard loadType == .percentage, let pct = percentage else { return nil }
        return (oneRepMax * pct / 5).rounded() * 5
    }

    /// Estimated time in minutes for this exercise based on sets and rest period
    var estimatedMinutes: Int {
        let setDuration = 45 // seconds per set (execution time)
        let restSeconds = Self.parseRestSeconds(restPeriod)
        let totalSetsCount = warmupSets + workingSets
        guard totalSetsCount > 0 else { return 0 }
        // Rest between sets (no rest after last set)
        let totalSeconds = totalSetsCount * setDuration + max(0, totalSetsCount - 1) * restSeconds
        return Int(ceil(Double(totalSeconds) / 60.0))
    }

    static func parseRestSeconds(_ rest: String) -> Int {
        let cleaned = rest.replacingOccurrences(of: " min", with: "")
        if let dash = cleaned.firstIndex(of: "-"),
           let lower = Int(cleaned[cleaned.startIndex..<dash]),
           let upper = Int(cleaned[cleaned.index(after: dash)...]) {
            return ((lower + upper) / 2) * 60 // average of range
        }
        if let val = Int(cleaned) { return val * 60 }
        return 120
    }

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
        isDumbbell: Bool = false,
        muscleGroups: [MuscleGroup] = []
    ) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
        self.tagRaw = tag?.rawValue
        self.warmupSets = warmupSets
        self.workingSets = workingSets
        self.targetReps = targetReps
        self.loadTypeRaw = loadType.rawValue
        self.percentage = percentage
        self.percentageOfRaw = percentageOf?.rawValue
        self.rpeTarget = rpeTarget
        self.restPeriod = restPeriod
        self.notes = notes
        self.substitutions = substitutions
        self.isBodyweight = isBodyweight
        self.isDumbbell = isDumbbell
        self.muscleGroupsRaw = muscleGroups.map(\.rawValue)
        self.activeSubstitution = nil
        self.setLogs = []
    }
}
