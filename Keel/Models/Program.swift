import Foundation
import SwiftData

@Model
final class Program {
    var id: UUID
    var name: String
    var unitRaw: String
    var createdAt: Date
    var currentWeek: Int
    var totalWeeks: Int
    var currentCycleNumber: Int
    var trainingDaysRaw: [Int]
    var templateId: UUID?
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \Block.program)
    var blocks: [Block]

    @Relationship(deleteRule: .cascade, inverse: \Workout.program)
    var workouts: [Workout]

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lbs }
        set { unitRaw = newValue.rawValue }
    }

    var trainingDays: [TrainingDay] {
        get { trainingDaysRaw.compactMap { TrainingDay(rawValue: $0) }.sorted() }
        set { trainingDaysRaw = newValue.map(\.rawValue) }
    }

    init(
        name: String,
        unit: WeightUnit = .lbs,
        totalWeeks: Int = 10,
        currentCycleNumber: Int = 1,
        trainingDays: [TrainingDay] = [.monday, .tuesday, .wednesday, .friday, .saturday],
        templateId: UUID? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.unitRaw = unit.rawValue
        self.createdAt = Date()
        self.currentWeek = 1
        self.totalWeeks = totalWeeks
        self.currentCycleNumber = currentCycleNumber
        self.trainingDaysRaw = trainingDays.map(\.rawValue)
        self.templateId = templateId
        self.isActive = isActive
        self.blocks = []
        self.workouts = []
    }

    func workoutsForWeek(_ week: Int) -> [Workout] {
        workouts
            .filter { $0.weekNumber == week }
            .sorted { $0.dayIndex < $1.dayIndex }
    }

    func todaysWorkout() -> Workout? {
        let today = TrainingDay.fromDate(Date())
        guard let dayIndex = trainingDays.firstIndex(of: today) else { return nil }
        return workoutsForWeek(currentWeek).first { $0.dayIndex == dayIndex }
    }

    func blockForWeek(_ week: Int) -> Block? {
        blocks.first { week >= $0.weekStart && week <= $0.weekEnd }
    }

    var allWorkoutsCompletedForCurrentWeek: Bool {
        let weekWorkouts = workoutsForWeek(currentWeek)
        return !weekWorkouts.isEmpty && weekWorkouts.allSatisfy(\.isCompleted)
    }
}

@Model
final class Block {
    var id: UUID
    var name: String
    var weekStart: Int
    var weekEnd: Int
    var blockDescription: String?
    var program: Program?

    init(name: String, weekStart: Int, weekEnd: Int, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.blockDescription = description
    }
}
