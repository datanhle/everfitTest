/// Mirrors the `data` items of `GET /workouts` exactly. Never used outside the Data layer.
nonisolated struct DayDTO: Codable, Sendable {
    let id: String
    let day: Int
    let assignments: [AssignmentDTO]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case day, assignments
    }
}
