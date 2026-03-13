import Foundation
import SwiftData

@Model
final class WorkoutHistory {
    var id: UUID
    var programName: String
    var workoutName: String
    var weekNumber: Int
    var dayIndex: Int
    var cycleNumber: Int
    var blockName: String?
    var startedAt: Date
    var completedAt: Date
    var durationSeconds: Int
    var bodyWeight: Double?
    var note: String?

    @Relationship(deleteRule: .cascade, inverse: \SetHistory.workoutHistory)
    var sets: [SetHistory]

    // MARK: - Computed Properties

    var totalVolume: Double {
        sets.filter { !$0.isSkipped && $0.setType == .working }
            .reduce(0) { $0 + $1.volume }
    }

    var totalWorkingSets: Int {
        sets.filter { !$0.isSkipped && $0.setType == .working }.count
    }

    var totalReps: Int {
        sets.filter { !$0.isSkipped && $0.setType == .working }
            .reduce(0) { $0 + ($1.reps ?? 0) }
    }

    var averageRestSeconds: Double? {
        let restValues = sets.compactMap(\.restSecondsToNext)
        guard !restValues.isEmpty else { return nil }
        return Double(restValues.reduce(0, +)) / Double(restValues.count)
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Sets grouped by exercise name + orderIndex, preserving workout order
    var exerciseGroups: [(exerciseName: String, originalName: String, tag: ExerciseTag?, sets: [SetHistory])] {
        var groups: [(key: String, exerciseName: String, originalName: String, tag: ExerciseTag?, sets: [SetHistory])] = []
        var seen: [String: Int] = [:]

        for set in sets.sorted(by: { $0.exerciseOrderIndex < $1.exerciseOrderIndex || ($0.exerciseOrderIndex == $1.exerciseOrderIndex && $0.setNumber < $1.setNumber) }) {
            let key = "\(set.exerciseOrderIndex)-\(set.exerciseName)"
            if let index = seen[key] {
                groups[index].sets.append(set)
            } else {
                seen[key] = groups.count
                groups.append((key: key, exerciseName: set.exerciseName, originalName: set.originalExerciseName, tag: set.tag, sets: [set]))
            }
        }

        return groups.map { ($0.exerciseName, $0.originalName, $0.tag, $0.sets) }
    }

    init(
        programName: String,
        workoutName: String,
        weekNumber: Int,
        dayIndex: Int,
        cycleNumber: Int,
        blockName: String? = nil,
        startedAt: Date,
        completedAt: Date,
        durationSeconds: Int,
        bodyWeight: Double? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.programName = programName
        self.workoutName = workoutName
        self.weekNumber = weekNumber
        self.dayIndex = dayIndex
        self.cycleNumber = cycleNumber
        self.blockName = blockName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.bodyWeight = bodyWeight
        self.note = note
        self.sets = []
    }
}
