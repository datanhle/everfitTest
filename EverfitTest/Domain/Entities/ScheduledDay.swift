import Foundation

nonisolated struct ScheduledDay: Identifiable, Equatable, Sendable {
    /// Start of the day.
    let id: Date
    /// 0 = Monday ... 6 = Sunday.
    let weekday: Int
    let dayOfMonth: Int
    let relation: DayRelation
    var workouts: [ScheduledWorkout]

    var isToday: Bool { relation == .today }
}
