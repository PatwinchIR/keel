import Foundation

@Observable
final class RestDaySettings {
    private static let defaultRestDaysKey = "keel_defaultRestDays"
    private static let tempRestDaysKey = "keel_tempRestDays"

    /// Days of the week that are always rest days (persisted in Settings)
    var defaultRestDays: Set<Int> {
        didSet { save() }
    }

    /// Dates manually marked as rest days from TodayView (temporary overrides)
    private var tempRestDates: Set<String> {
        didSet { saveTempDates() }
    }

    init() {
        if let saved = UserDefaults.standard.array(forKey: Self.defaultRestDaysKey) as? [Int] {
            self.defaultRestDays = Set(saved)
        } else {
            // Default: Thursday (5) and Sunday (1) — TrainingDay raw values
            self.defaultRestDays = [TrainingDay.thursday.rawValue, TrainingDay.sunday.rawValue]
        }

        if let saved = UserDefaults.standard.array(forKey: Self.tempRestDaysKey) as? [String] {
            self.tempRestDates = Set(saved)
        } else {
            self.tempRestDates = []
        }
    }

    func isRestDay(_ day: TrainingDay) -> Bool {
        defaultRestDays.contains(day.rawValue)
    }

    func toggleRestDay(_ day: TrainingDay) {
        if defaultRestDays.contains(day.rawValue) {
            defaultRestDays.remove(day.rawValue)
        } else {
            defaultRestDays.insert(day.rawValue)
        }
    }

    /// Check if a specific date is temporarily marked as rest
    func isTempRestDay(_ date: Date) -> Bool {
        tempRestDates.contains(dateKey(date))
    }

    /// Toggle a specific date as a temporary rest day
    func toggleTempRestDay(_ date: Date) {
        let key = dateKey(date)
        if tempRestDates.contains(key) {
            tempRestDates.remove(key)
        } else {
            tempRestDates.insert(key)
        }
    }

    /// Whether today should be treated as a rest day
    /// (either it's a default rest day or manually marked)
    func isTodayRestDay() -> Bool {
        let today = TrainingDay.fromDate(Date())
        return isRestDay(today) || isTempRestDay(Date())
    }

    private func save() {
        UserDefaults.standard.set(Array(defaultRestDays), forKey: Self.defaultRestDaysKey)
    }

    private func saveTempDates() {
        UserDefaults.standard.set(Array(tempRestDates), forKey: Self.tempRestDaysKey)
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
