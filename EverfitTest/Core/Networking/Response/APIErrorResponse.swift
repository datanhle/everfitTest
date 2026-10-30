/// Server error body. Not documented by the API — assumed shape: `{ "message": String?, "code": Int? }`.
nonisolated struct APIErrorResponse: Decodable, Sendable {
    let message: String?
    let code: Int?
}
