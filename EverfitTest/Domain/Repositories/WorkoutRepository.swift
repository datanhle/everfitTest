/// Defined by Domain, implemented by Data (`DefaultWorkoutRepository`).
/// Offline-first: callers show `cachedWeek()` first, then `fetchWeek()` for updates.
protocol WorkoutRepository {
    /// Last successful response saved in SwiftData; `nil` before the first successful fetch.
    func cachedWeek() -> [DayPlan]?
    /// `GET /workouts`, then overwrites the SwiftData cache.
    func fetchWeek() async throws(APIError) -> [DayPlan]
    /// Saves the user's mark/unmark locally (by workout `_id`); both weeks above include it from then on.
    func setCompleted(_ isCompleted: Bool, workoutID: String)
}
