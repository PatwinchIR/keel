import Foundation
import SwiftData

@Model
final class BodyComposition {
    var id: UUID
    var date: Date
    var bodyFat: Double?
    var bodyWeight: Double?
    var method: String?
    var note: String?

    init(date: Date = Date(), bodyFat: Double? = nil, bodyWeight: Double? = nil, method: String? = nil, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.bodyFat = bodyFat
        self.bodyWeight = bodyWeight
        self.method = method
        self.note = note
    }
}
