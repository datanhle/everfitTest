struct WorkoutItem: Identifiable, Equatable {
    let id: String
    let title: String
    let exerciseCountText: String
    let status: ScheduleStatus
    let isCompleted: Bool
    /// False for future workouts: shown, but not tappable.
    let canToggle: Bool
}
