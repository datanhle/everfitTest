/// Business rule for what a workout shows:
/// - Past: missed / completed
/// - Today: assigned / completed
/// - Future: upcoming (greyed out, no label, can't be marked)
nonisolated enum ScheduleStatus: Equatable, Sendable {
    case assigned
    case completed
    case missed
    case upcoming

    init(relation: DayRelation, isCompleted: Bool) {
        switch relation {
        case .future: self = .upcoming
        case .today: self = isCompleted ? .completed : .assigned
        case .past: self = isCompleted ? .completed : .missed
        }
    }
}
