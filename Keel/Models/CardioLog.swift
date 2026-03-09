import Foundation
import SwiftData

@Model
final class CardioLog {
    var id: UUID
    var date: Date
    var typeRaw: String
    var durationMinutes: Int
    var notes: String?

    var type: CardioType {
        get { CardioType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    init(type: CardioType, date: Date = Date(), durationMinutes: Int, notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.typeRaw = type.rawValue
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}
