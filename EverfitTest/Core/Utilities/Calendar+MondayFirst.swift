import Foundation

nonisolated extension Calendar {
    /// Gregorian calendar in the user's time zone, weeks start on Monday.
    static var mondayFirst: Calendar {
        // Generated via Claude. Adjusted to handle edge case: Sunday-first locales (en_US) and non-Gregorian device calendars.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = .current
        calendar.firstWeekday = 2
        return calendar
    }
}
