import Foundation

struct ActivityRingData {
    var moveCalories: Double = 0
    var moveGoal: Double = 1
    var exerciseMinutes: Double = 0
    var exerciseGoal: Double = 30
    var standHours: Double = 0
    var standGoal: Double = 12

    var moveProgress: Double { moveCalories / max(moveGoal, 1) }
    var exerciseProgress: Double { exerciseMinutes / max(exerciseGoal, 1) }
    var standProgress: Double { standHours / max(standGoal, 1) }
}
