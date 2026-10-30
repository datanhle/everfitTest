nonisolated struct Workout: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let exerciseCount: Int
    /// The user's own mark if they made one, otherwise the API's status == completed.
    var isCompleted: Bool
}
