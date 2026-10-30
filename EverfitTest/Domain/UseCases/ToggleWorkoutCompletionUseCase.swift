protocol ToggleWorkoutCompletionUseCase {
    /// Flips one workout's completion, saves it locally and returns the updated schedule.
    /// An unknown ID or a future workout returns the schedule unchanged and saves nothing.
    func execute(workoutID: String, in schedule: WeeklySchedule) -> WeeklySchedule
}

final class DefaultToggleWorkoutCompletionUseCase: ToggleWorkoutCompletionUseCase {
    private let repository: WorkoutRepository

    init(repository: WorkoutRepository) {
        self.repository = repository
    }

    func execute(workoutID: String, in schedule: WeeklySchedule) -> WeeklySchedule {
        // Generated via Claude. Adjusted to handle edge case: unknown ID or future workout; nothing is saved.
        guard let workout = schedule.workout(withID: workoutID), workout.canToggleCompletion else { return schedule }
        let isCompleted = !workout.isCompleted
        repository.setCompleted(isCompleted, workoutID: workoutID)
        return schedule.settingCompletion(isCompleted, workoutID: workoutID)
    }
}
