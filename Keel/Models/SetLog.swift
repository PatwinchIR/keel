import Foundation
import SwiftData

@Model
final class SetLog {
    var id: UUID
    var setNumber: Int
    var setTypeRaw: String
    var weight: Double?
    var reps: Int?
    var rpe: Double?
    var isCompleted: Bool
    var completedAt: Date?
    var note: String?
    var exercise: Exercise?

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .working }
        set { setTypeRaw = newValue.rawValue }
    }

    init(
        setNumber: Int,
        setType: SetType,
        weight: Double? = nil,
        reps: Int? = nil
    ) {
        self.id = UUID()
        self.setNumber = setNumber
        self.setTypeRaw = setType.rawValue
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
    }
}
