/// Base success envelope: `{ "data": T, "message": String? }`.
nonisolated struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
    let message: String?
}
