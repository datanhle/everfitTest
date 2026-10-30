import Foundation

/// Where a day sits relative to today.
nonisolated enum DayRelation: Equatable, Sendable {
    case past
    case today
    case future

    init(date: Date, today: Date, calendar: Calendar) {
        // Generated via Claude. Adjusted to handle edge case: time of day (23:59 yesterday is past, 00:01 today is today).
        let day = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: today)
        if day < startOfToday {
            self = .past
        } else if day == startOfToday {
            self = .today
        } else {
            self = .future
        }
    }
}
