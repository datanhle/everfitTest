/// Status as sent by the API.
/// Assumption (not documented by the API): 0 = assigned, 1 = missed, 2 = completed.
nonisolated enum WorkoutStatus: Int, Sendable {
    case assigned = 0
    case missed = 1
    case completed = 2
}
