import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var name: String
    var weekNumber: Int
    var dayIndex: Int
    var isCompleted: Bool
    var completedAt: Date?
    var startedAt: Date?
    var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]

    var sortedExercises: [Exercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Estimated total workout time in minutes
    var estimatedMinutes: Int {
        exercises.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var completionProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        let totalSets = exercises.reduce(0) { $0 + $1.warmupSets + $1.workingSets }
        guard totalSets > 0 else { return 0 }
        let completedSets = exercises.flatMap(\.setLogs).filter(\.isCompleted).count
        return Double(completedSets) / Double(totalSets)
    }

    init(
        name: String,
        weekNumber: Int,
        dayIndex: Int
    ) {
        self.id = UUID()
        self.name = name
        self.weekNumber = weekNumber
        self.dayIndex = dayIndex
        self.isCompleted = false
        self.exercises = []
    }
}
