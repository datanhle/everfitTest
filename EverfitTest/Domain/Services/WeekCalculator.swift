import Foundation

nonisolated struct WeekCalculator: Sendable {
    let calendar: Calendar

    /// Start-of-day dates Monday...Sunday of the week containing `date`.
    /// Relies on `calendar.firstWeekday == 2`, so a Sunday belongs to the week that started the previous Monday.
    ///
    /// Example: `date` = Thu 29 Oct 2026.
    func weekDates(containing date: Date) -> [Date] {
        // Generated via Claude. Adjusted to handle edge case: Sunday stays in the Monday-started week; DST days (adds calendar days, not 24h).

        // The week that contains `date`; it starts on Monday because `firstWeekday == 2`.
        // Output: Mon 26 Oct 00:00 ..< Mon 2 Nov 00:00
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }

        // Monday + 0...6 calendar days = the 7 dates of the week.
        // Output: [Mon 26 Oct, Tue 27, Wed 28, Thu 29, Fri 30, Sat 31, Sun 1 Nov]
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }
}
