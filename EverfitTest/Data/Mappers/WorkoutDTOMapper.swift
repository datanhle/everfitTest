nonisolated extension DayDTO {
    /// `userCompletions`: the user's own marks by workout `_id` (from `CompletionRecord`).
    func toDomain(userCompletions: [String: Bool] = [:]) -> DayPlan {
        DayPlan(weekday: day, workouts: assignments.map { $0.toDomain(userCompletion: userCompletions[$0.id]) })
    }
}

nonisolated extension AssignmentDTO {
    /// `userCompletion`: the user's own mark for this workout, `nil` if they never tapped it.
    func toDomain(userCompletion: Bool? = nil) -> Workout {
        // Generated via Claude. Adjusted to handle edge case: user unmarked a workout the API marks completed; unknown status → assigned.
        let apiStatus = WorkoutStatus(rawValue: status) ?? .assigned
        return Workout(
            id: id,
            title: title,
            exerciseCount: totalExercise,
            // The user's mark wins; without one, the API decides.
            isCompleted: userCompletion ?? (apiStatus == .completed)
        )
    }
}
