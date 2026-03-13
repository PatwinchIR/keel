import Foundation
import SwiftData

@Model
final class SetHistory {
    var id: UUID
    var exerciseName: String
    var originalExerciseName: String
    var exerciseOrderIndex: Int
    var setNumber: Int
    var setTypeRaw: String
    var tagRaw: String?
    var weight: Double?
    var reps: Int?
    var rpe: Double?
    var isSkipped: Bool
    var completedAt: Date?
    var note: String?
    var restSecondsToNext: Int?
    var targetReps: String?
    var rpeTarget: String?
    var percentageUsed: Double?
    var oneRMAtTime: Double?
    var muscleGroupsRaw: [String] = []
    var workoutHistory: WorkoutHistory?

    // MARK: - Computed Properties

    var volume: Double {
        guard !isSkipped, let w = weight, let r = reps else { return 0 }
        return w * Double(r)
    }

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .working }
        set { setTypeRaw = newValue.rawValue }
    }

    var tag: ExerciseTag? {
        get { tagRaw.flatMap { ExerciseTag(rawValue: $0) } }
        set { tagRaw = newValue?.rawValue }
    }

    var muscleGroups: [MuscleGroup] {
        muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) }
    }

    var estimatedOneRM: Double? {
        guard !isSkipped, let w = weight, w > 0, let r = reps, r > 0 else { return nil }
        return OneRepMax.brzyckiEstimate(weight: w, reps: r)
    }

    var formattedRest: String? {
        guard let rest = restSecondsToNext else { return nil }
        let minutes = rest / 60
        let seconds = rest % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    init(
        exerciseName: String,
        originalExerciseName: String,
        exerciseOrderIndex: Int,
        setNumber: Int,
        setType: SetType,
        tag: ExerciseTag? = nil,
        weight: Double? = nil,
        reps: Int? = nil,
        rpe: Double? = nil,
        isSkipped: Bool = false,
        completedAt: Date? = nil,
        note: String? = nil,
        restSecondsToNext: Int? = nil,
        targetReps: String? = nil,
        rpeTarget: String? = nil,
        percentageUsed: Double? = nil,
        oneRMAtTime: Double? = nil,
        muscleGroups: [MuscleGroup] = []
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.originalExerciseName = originalExerciseName
        self.exerciseOrderIndex = exerciseOrderIndex
        self.setNumber = setNumber
        self.setTypeRaw = setType.rawValue
        self.tagRaw = tag?.rawValue
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isSkipped = isSkipped
        self.completedAt = completedAt
        self.note = note
        self.restSecondsToNext = restSecondsToNext
        self.targetReps = targetReps
        self.rpeTarget = rpeTarget
        self.percentageUsed = percentageUsed
        self.oneRMAtTime = oneRMAtTime
        self.muscleGroupsRaw = muscleGroups.map(\.rawValue)
    }
}
