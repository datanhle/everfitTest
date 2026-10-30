nonisolated struct ScheduledWorkout: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let exerciseCount: Int
    /// Where this workout's day sits relative to today.
    let relation: DayRelation
    var isCompleted: Bool

    /// Derived, so it always matches `isCompleted`.
    var status: ScheduleStatus { ScheduleStatus(relation: relation, isCompleted: isCompleted) }

    /// Only past and today's workouts can be marked/unmarked; future ones are read-only.
    var canToggleCompletion: Bool { status != .upcoming }
}

extension ScheduledWorkout {
    /// A workout placed on a day; its `status` follows from `relation` and `isCompleted`.
    init(_ workout: Workout, relation: DayRelation) {
        self.init(
            id: workout.id,
            title: workout.title,
            exerciseCount: workout.exerciseCount,
            relation: relation,
            isCompleted: workout.isCompleted
        )
    }
}
