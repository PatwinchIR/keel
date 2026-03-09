import Foundation
import SwiftData

@Model
final class OneRepMax {
    var id: UUID
    var liftRaw: String
    var weight: Double
    var date: Date
    var cycleNumber: Int
    var note: String?

    var lift: CompoundLift {
        get { CompoundLift(rawValue: liftRaw) ?? .squat }
        set { liftRaw = newValue.rawValue }
    }

    init(lift: CompoundLift, weight: Double, date: Date = Date(), cycleNumber: Int = 1, note: String? = nil) {
        self.id = UUID()
        self.liftRaw = lift.rawValue
        self.weight = weight
        self.date = date
        self.cycleNumber = cycleNumber
        self.note = note
    }

    static func brzyckiEstimate(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight / (1.0278 - 0.0278 * Double(reps))
    }

    static func epleyEstimate(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    static func estimate(weight: Double, reps: Int, formula: OneRMFormula = .brzycki) -> Double {
        switch formula {
        case .brzycki: return brzyckiEstimate(weight: weight, reps: reps)
        case .epley: return epleyEstimate(weight: weight, reps: reps)
        }
    }
}
