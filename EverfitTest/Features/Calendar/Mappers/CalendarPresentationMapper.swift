import Foundation

/// Domain → UI models. Formatting only; no business rules.
enum CalendarPresentationMapper {
    /// Example: the week Mon 26 Oct … Sun 1 Nov 2026, today = Thu 29, locale = en.
    static func map(_ schedule: WeeklySchedule, locale: Locale = .current) -> [DayItem] {
        // Calendar only for weekday names, in the user's language.
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale

        // Short weekday names; this list always starts on Sunday.
        // Output: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdaySymbols = calendar.shortWeekdaySymbols

        // 7 ScheduledDays in, 7 DayItems out, same order.
        // Output: [MON 26, TUE 27, WED 28, THU 29 (today), FRI 30, SAT 31, SUN 1]
        return schedule.days.map { day in
            DayItem(
                id: day.id,
                // Generated via Claude. Adjusted to handle edge case: shortWeekdaySymbols starts on Sunday, but domain weekday 0 = Monday.
                // Output: weekday 0 → symbols[1] = "MON", weekday 3 → symbols[4] = "THU", weekday 6 → symbols[0] = "SUN"
                weekdayText: weekdaySymbols[(day.weekday + 1) % weekdaySymbols.count].uppercased(with: locale),
                // Day number formatted for the locale.
                // Output: 29 → "29"
                dayNumberText: day.dayOfMonth.formatted(.number.locale(locale)),
                // Highlights the date in the cell.
                // Output: true only for Thu 29
                isToday: day.isToday,
                // Ready-to-show workout rows.
                // Output: [] for an empty week, so the cell shows only the date
                workouts: day.workouts.map { workout in
                    WorkoutItem(
                        id: workout.id,
                        title: workout.title,
                        exerciseCountText: AppStrings.CalendarScreen.exerciseCount(workout.exerciseCount),
                        status: workout.status,
                        isCompleted: workout.isCompleted,
                        canToggle: workout.canToggleCompletion
                    )
                }
            )
        }
    }
}
