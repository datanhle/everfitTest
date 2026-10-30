import Foundation

/// One Monday–Sunday week with every workout's status resolved.
nonisolated struct WeeklySchedule: Equatable, Sendable {
    private(set) var days: [ScheduledDay]

    /// Builds the 7 days of the week and places each plan's workouts on its day.
    ///
    /// Example (today = Thu 29 Oct):
    ///   plans  = [Mon: [Legs day], Thu: [HIIT], Thu: [Yoga], Sat: [Legs day]]
    ///   result = MON 26 [Legs day] · TUE–WED [] · THU 29 [HIIT, Yoga] · FRI–SUN []
    init(weekDates: [Date], plans: [DayPlan], today: Date, calendar: Calendar) {
        // Generated via Claude. Adjusted to handle edge case: same weekday twice (merged), repeated workout ID (first kept), weekday outside 0–6 (ignored).
        var days: [ScheduledDay] = []
        var seenIDs: Set<String> = []

        for (weekday, date) in weekDates.enumerated() {
            let relation = DayRelation(date: date, today: today, calendar: calendar)
            var workouts: [ScheduledWorkout] = []

            // Every plan for this weekday — the API may send the same day twice.
            // A weekday outside 0–6 never matches, so it is ignored.
            for plan in plans where plan.weekday == weekday {
                // An ID already placed on an earlier day is skipped: IDs must be unique in the week.
                for workout in plan.workouts where !seenIDs.contains(workout.id) {
                    seenIDs.insert(workout.id)
                    workouts.append(ScheduledWorkout(workout, relation: relation))
                }
            }

            days.append(ScheduledDay(
                id: calendar.startOfDay(for: date),
                weekday: weekday,
                dayOfMonth: calendar.component(.day, from: date),
                relation: relation,
                workouts: workouts
            ))
        }
        self.days = days
    }

    func workout(withID id: String) -> ScheduledWorkout? {
        days.lazy.flatMap(\.workouts).first { $0.id == id }
    }

    /// A copy with one workout's completion changed; its status follows automatically.
    ///
    /// Example (today = Thu 29 Oct): MON 26 [Legs day — not completed, .missed]
    ///   `settingCompletion(true, workoutID: "legs")` → MON 26 [Legs day — completed, .completed]
    func settingCompletion(_ isCompleted: Bool, workoutID: String) -> WeeklySchedule {
        // Generated via Claude. Adjusted to handle edge case: unknown workout ID (returns an unchanged copy).

        // A struct copy: the changes below never touch the schedule the caller holds.
        // Output: the same 7 days as `self`
        var copy = self

        // Look through the days, Monday first, for the workout with this ID.
        for dayIndex in copy.days.indices {
            // Position of the workout in this day's list; `nil` when it is on another day.
            // Output: MON 26 → 0 (Legs day); other days → nil, so go to the next day
            guard let index = copy.days[dayIndex].workouts.firstIndex(where: { $0.id == workoutID }) else { continue }

            // Only the flag changes; `status` is computed from it, so it updates too.
            // Output: Legs day isCompleted false → true, status .missed → .completed
            copy.days[dayIndex].workouts[index].isCompleted = isCompleted

            // IDs are unique within a week (enforced in init), so the first match is the only one.
            // Output: the copy with Legs day completed
            return copy
        }

        // No workout has this ID.
        // Output: an unchanged copy (== self)
        return copy
    }
}
