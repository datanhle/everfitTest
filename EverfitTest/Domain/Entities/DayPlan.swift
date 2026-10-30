nonisolated struct DayPlan: Equatable, Sendable {
    /// 0 = Monday ... 6 = Sunday (assumption: API `day` index starts on Monday).
    let weekday: Int
    var workouts: [Workout]
}
