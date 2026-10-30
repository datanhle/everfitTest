nonisolated struct AssignmentDTO: Codable, Sendable {
    let id: String
    let title: String
    let status: Int
    let totalExercise: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, status
        case totalExercise = "total_exercise"
    }
}
